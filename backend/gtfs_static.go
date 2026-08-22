package main

// GTFS-Static Unterstützung für die Fahrzeug-Detailansicht.
// Hält nur sweden.zip (637 MB) auf Disk in backend/data/gtfs/ und baut
// beim Start eager Indizes für kleine Dateien (stops/routes/trips).
// stop_times (663 MB) und shapes (2.4 GB) werden lazy per Trip gescannt
// und via LRU gecacht – so bleibt die BFF-RAM begrenzt (~40 MB eager + LRU).

import (
	"archive/zip"
	"bufio"
	"bytes"
	"encoding/csv"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"
)

// Pfade – relativ zum Arbeitsverzeichnis "backend/". Fallback: executable dir.
var gtfsZipPath = filepath.Join("data", "gtfs", "sweden.zip")
var gtfsExtractDir = filepath.Join("data", "gtfs", "extracted")

// Extraktions-Flags: Raw-CSVs auf Disk machen Scans ~5x schneller als Zip-Streams.
var (
	extractMu       sync.Mutex
	stopTimesFile   string // Pfad wenn extrahiert, sonst ""
	shapeFile       string
	extractionDone  bool
)

type gtfsStop struct {
	ID   string
	Name string
	Lat  float64
	Lon  float64
}

type gtfsRoute struct {
	ID        string
	ShortName string
	LongName  string
	Type      int
}

type gtfsTrip struct {
	ID         string
	RouteID    string
	ShapeID    string
	Headsign   string
	DirectionID int
}

type tripStop struct {
	StopID        string
	StopSequence  int
	ArrivalTime   string
	DepartureTime string
}

type shapePoint struct {
	Seq int
	Lat float64
	Lon float64
}

// Globale Indizes (eager) + LRU Caches (lazy)
var (
	gtfsInitOnce sync.Once
	gtfsInitErr  error
	gtfsReady    bool
	gtfsReadyMu  sync.RWMutex

	stopIndex  map[string]gtfsStop  // stop_id -> stop
	routeIndex map[string]gtfsRoute // route_id -> route
	tripIndex  map[string]gtfsTrip  // trip_id -> trip

	// LRU caches: tripId -> data
	stopTimesCache = struct {
		sync.RWMutex
		m map[string][]tripStop
		order []string
		max int
	}{m: make(map[string][]tripStop), max: 32}

	shapeCache = struct {
		sync.RWMutex
		m map[string][][]float64 // shape_id -> polyline [[lat,lng],...]
		order []string
		max int
	}{m: make(map[string][][]float64), max: 32}

	zipMu sync.Mutex // schützt gleichzeitige zip-Opens (os.File + zip.Reader)
)

func isGtfsReady() bool {
	gtfsReadyMu.RLock()
	defer gtfsReadyMu.RUnlock()
	return gtfsReady
}

// ensureGtfsReady baut eager Indizes beim ersten Aufruf (oder Background-Init).
// Ist sweden.zip nicht vorhanden, wird versucht, es via GTFS_SWEDEN_3_STATIC zu laden.
func ensureGtfsReady() error {
	gtfsInitOnce.Do(func() {
		// Hintergrund-Download falls zip fehlt
		if _, err := os.Stat(gtfsZipPath); os.IsNotExist(err) {
			altPath := filepath.Join("..", "data", "gtfs", "sweden.zip") // falls von project root gestartet
			if _, err2 := os.Stat(altPath); err2 == nil {
				gtfsZipPath = altPath
			} else {
				log.Printf("[GTFS] sweden.zip fehlt unter %s – versuche Download via GTFS_SWEDEN_3_STATIC", gtfsZipPath)
				if dlErr := downloadGtfsZip(); dlErr != nil {
					gtfsInitErr = fmt.Errorf("GTFS download failed: %w", dlErr)
					log.Printf("[GTFS] Download fehlgeschlagen: %v", gtfsInitErr)
					return
				}
			}
		}
		// Prüfe nochmal nach Download
		if _, err := os.Stat(gtfsZipPath); os.IsNotExist(err) {
			gtfsInitErr = fmt.Errorf("sweden.zip nicht gefunden (%s)", gtfsZipPath)
			return
		}
		start := time.Now()
		log.Printf("[GTFS] Baue eager Indizes aus %s …", gtfsZipPath)
		if err := buildGtfsIndexes(); err != nil {
			gtfsInitErr = err
			log.Printf("[GTFS] Index-Build fehlgeschlagen: %v", err)
			return
		}
		gtfsReadyMu.Lock()
		gtfsReady = true
		gtfsReadyMu.Unlock()
		log.Printf("[GTFS] Ready in %v – stops=%d routes=%d trips=%d", time.Since(start), len(stopIndex), len(routeIndex), len(tripIndex))

		// Hintergrund: große CSVs einmalig extrahieren (Raw-Scans deutlich schneller)
		go extractLargeFiles()
	})
	return gtfsInitErr
}

// downloadGtfsZip lädt sweden.zip von opendata.samtrafiken.se (637 MB). Nur wenn GTFS_SWEDEN_3_STATIC gesetzt.
func downloadGtfsZip() error {
	if cfg.GtfsStaticKey == "" {
		return fmt.Errorf("GTFS_SWEDEN_3_STATIC nicht gesetzt – lege backend/data/gtfs/sweden.zip manuell ab oder setze den Key")
	}
	url := fmt.Sprintf("https://opendata.samtrafiken.se/gtfs-sweden/sweden.zip?key=%s", cfg.GtfsStaticKey)
	log.Printf("[GTFS] Download %s (637 MB, kann Minuten dauern) …", maskKey(cfg.GtfsStaticKey))
	if err := os.MkdirAll(filepath.Dir(gtfsZipPath), 0755); err != nil {
		return err
	}
	// Streaming download direkt in Datei (kein RAM-Peak)
	resp, err := apiClient.Get(url)
	if err != nil {
		return fmt.Errorf("GET failed: %w", err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 1024))
		return fmt.Errorf("HTTP %d: %s", resp.StatusCode, strings.TrimSpace(string(body)))
	}
	tmpPath := gtfsZipPath + ".tmp"
	f, err := os.Create(tmpPath)
	if err != nil {
		return err
	}
	n, err := io.Copy(f, resp.Body)
	f.Close()
	if err != nil {
		os.Remove(tmpPath)
		return err
	}
	if err := os.Rename(tmpPath, gtfsZipPath); err != nil {
		return err
	}
	log.Printf("[GTFS] Download fertig: %d bytes -> %s", n, gtfsZipPath)
	return nil
}

func buildGtfsIndexes() error {
	zipMu.Lock()
	defer zipMu.Unlock()

	f, err := os.Open(gtfsZipPath)
	if err != nil {
		return err
	}
	defer f.Close()
	fi, _ := f.Stat()
	zr, err := zip.NewReader(f, fi.Size())
	if err != nil {
		return err
	}

	// Helper: finde File im Zip
	findFile := func(name string) *zip.File {
		for _, zf := range zr.File {
			if zf.Name == name {
				return zf
			}
		}
		return nil
	}

	// 1. stops.txt
	if zf := findFile("stops.txt"); zf != nil {
		rc, _ := zf.Open()
		m, err := parseStopsCSV(rc)
		rc.Close()
		if err != nil {
			return fmt.Errorf("stops.txt: %w", err)
		}
		stopIndex = m
	} else {
		return fmt.Errorf("stops.txt nicht im zip")
	}

	// 2. routes.txt
	if zf := findFile("routes.txt"); zf != nil {
		rc, _ := zf.Open()
		m, err := parseRoutesCSV(rc)
		rc.Close()
		if err != nil {
			return fmt.Errorf("routes.txt: %w", err)
		}
		routeIndex = m
	}

	// 3. trips.txt
	if zf := findFile("trips.txt"); zf != nil {
		rc, _ := zf.Open()
		m, err := parseTripsCSV(rc)
		rc.Close()
		if err != nil {
			return fmt.Errorf("trips.txt: %w", err)
		}
		tripIndex = m
	}

	return nil
}

func parseStopsCSV(r io.Reader) (map[string]gtfsStop, error) {
	cr := csv.NewReader(r)
	cr.ReuseRecord = true
	header, err := cr.Read()
	if err != nil {
		return nil, err
	}
	idx := csvHeaderIndex(header)
	m := make(map[string]gtfsStop, 120000)
	for {
		rec, err := cr.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			continue
		}
		sid := fieldByHeader(rec, idx, "stop_id")
		if sid == "" {
			continue
		}
		lat, _ := strconv.ParseFloat(fieldByHeader(rec, idx, "stop_lat"), 64)
		lon, _ := strconv.ParseFloat(fieldByHeader(rec, idx, "stop_lon"), 64)
		m[sid] = gtfsStop{
			ID:   sid,
			Name: fieldByHeader(rec, idx, "stop_name"),
			Lat:  lat,
			Lon:  lon,
		}
	}
	return m, nil
}

func parseRoutesCSV(r io.Reader) (map[string]gtfsRoute, error) {
	cr := csv.NewReader(r)
	header, err := cr.Read()
	if err != nil {
		return nil, err
	}
	idx := csvHeaderIndex(header)
	m := make(map[string]gtfsRoute)
	for {
		rec, err := cr.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			continue
		}
		rid := fieldByHeader(rec, idx, "route_id")
		if rid == "" {
			continue
		}
		rt, _ := strconv.Atoi(fieldByHeader(rec, idx, "route_type"))
		m[rid] = gtfsRoute{
			ID:        rid,
			ShortName: fieldByHeader(rec, idx, "route_short_name"),
			LongName:  fieldByHeader(rec, idx, "route_long_name"),
			Type:      rt,
		}
	}
	return m, nil
}

func parseTripsCSV(r io.Reader) (map[string]gtfsTrip, error) {
	cr := csv.NewReader(r)
	header, err := cr.Read()
	if err != nil {
		return nil, err
	}
	idx := csvHeaderIndex(header)
	m := make(map[string]gtfsTrip, 700000)
	for {
		rec, err := cr.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			continue
		}
		tid := fieldByHeader(rec, idx, "trip_id")
		if tid == "" {
			continue
		}
		dir, _ := strconv.Atoi(fieldByHeader(rec, idx, "direction_id"))
		m[tid] = gtfsTrip{
			ID:          tid,
			RouteID:     fieldByHeader(rec, idx, "route_id"),
			ShapeID:     fieldByHeader(rec, idx, "shape_id"),
			Headsign:    fieldByHeader(rec, idx, "trip_headsign"),
			DirectionID: dir,
		}
	}
	return m, nil
}

func csvHeaderIndex(header []string) map[string]int {
	m := make(map[string]int, len(header))
	for i, h := range header {
		m[strings.TrimSpace(h)] = i
	}
	return m
}

func fieldByHeader(rec []string, idx map[string]int, name string) string {
	if i, ok := idx[name]; ok && i < len(rec) {
		return strings.TrimSpace(rec[i])
	}
	return ""
}

// getStopTimesForTrip scannt stop_times.txt lazy und cached das Ergebnis.
// Gibt sortierte Stops (nach stop_sequence) zurück.
func getStopTimesForTrip(rawTripID string) ([]tripStop, error) {
	// Cache hit?
	stopTimesCache.RLock()
	if v, ok := stopTimesCache.m[rawTripID]; ok {
		stopTimesCache.RUnlock()
		return v, nil
	}
	stopTimesCache.RUnlock()

	if err := ensureGtfsReady(); err != nil {
		return nil, err
	}

	src, cleanup, err := openScanSource("stop_times.txt")
	if err != nil {
		return nil, err
	}
	defer cleanup()

	out := scanStopTimesFast(src, rawTripID)
	sort.Slice(out, func(i, j int) bool { return out[i].StopSequence < out[j].StopSequence })

	// In LRU legen
	stopTimesCache.Lock()
	if len(stopTimesCache.m) >= stopTimesCache.max {
		evict := stopTimesCache.order[0]
		stopTimesCache.order = stopTimesCache.order[1:]
		delete(stopTimesCache.m, evict)
	}
	stopTimesCache.m[rawTripID] = out
	stopTimesCache.order = append(stopTimesCache.order, rawTripID)
	stopTimesCache.Unlock()

	return out, nil
}

// getShapePolyline scannt shapes.txt für shape_id, downsampled auf max 300 Punkte.
func getShapePolyline(shapeID string) ([][]float64, error) {
	if shapeID == "" {
		return nil, nil
	}
	shapeCache.RLock()
	if v, ok := shapeCache.m[shapeID]; ok {
		shapeCache.RUnlock()
		return v, nil
	}
	shapeCache.RUnlock()

	if err := ensureGtfsReady(); err != nil {
		return nil, err
	}

	src, cleanup, err := openScanSource("shapes.txt")
	if err != nil {
		return nil, err
	}
	defer cleanup()

	pts := scanShapesFast(src, shapeID)
	if len(pts) == 0 {
		return nil, nil
	}
	sort.Slice(pts, func(i, j int) bool { return pts[i].Seq < pts[j].Seq })

	// Downsample auf max 300 Punkte (jeder N-te)
	const maxPts = 300
	var poly [][]float64
	if len(pts) <= maxPts {
		poly = make([][]float64, len(pts))
		for i, p := range pts {
			poly[i] = []float64{p.Lat, p.Lon}
		}
	} else {
		step := float64(len(pts)) / float64(maxPts)
		poly = make([][]float64, 0, maxPts)
		for i := 0; i < maxPts; i++ {
			idx := int(float64(i) * step)
			if idx >= len(pts) {
				idx = len(pts) - 1
			}
			poly = append(poly, []float64{pts[idx].Lat, pts[idx].Lon})
		}
		// Letzten Punkt garantieren
		last := pts[len(pts)-1]
		poly[len(poly)-1] = []float64{last.Lat, last.Lon}
	}

	shapeCache.Lock()
	if len(shapeCache.m) >= shapeCache.max {
		evict := shapeCache.order[0]
		shapeCache.order = shapeCache.order[1:]
		delete(shapeCache.m, evict)
	}
	shapeCache.m[shapeID] = poly
	shapeCache.order = append(shapeCache.order, shapeID)
	shapeCache.Unlock()

	return poly, nil
}

// stripOperatorTag entfernt "sl:" o.ä. Präfix aus getaggten IDs.
func stripOperatorTag(tagged string) string {
	if idx := strings.Index(tagged, ":"); idx >= 0 {
		return tagged[idx+1:]
	}
	return tagged
}

// scanStopTimesFast scanned stop_times.txt per Zeilenpräfix (trip_id ist
// Spalte 1, unkotiert numerisch). Parst nur die ersten 5 Felder – alle liegen
// vor dem möglicherweise kotierten stop_headsign. ~5x schneller als csv.Reader.
func scanStopTimesFast(r io.Reader, tripID string) []tripStop {
	prefix := tripID + ","
	sc := bufio.NewScanner(r)
	sc.Buffer(make([]byte, 0, 64*1024), 1<<20)
	var out []tripStop
	for sc.Scan() {
		line := sc.Bytes()
		if !bytes.HasPrefix(line, []byte(prefix)) {
			continue
		}
		// Felder: trip_id,arrival_time,departure_time,stop_id,stop_sequence,...
		rest := line[len(prefix):]
		arrival, rest2 := cutField(rest)
		departure, rest3 := cutField(rest2)
		stopID, rest4 := cutField(rest3)
		seqStr, _ := cutField(rest4)
		seq, err := strconv.Atoi(seqStr)
		if err != nil || seq == 0 || stopID == "" {
			continue
		}
		out = append(out, tripStop{
			StopID:        stopID,
			StopSequence:  seq,
			ArrivalTime:   arrival,
			DepartureTime: departure,
		})
	}
	return out
}

// scanShapesFast analog für shapes.txt (shape_id,lat,lon,seq,dist).
func scanShapesFast(r io.Reader, shapeID string) []shapePoint {
	prefix := shapeID + ","
	sc := bufio.NewScanner(r)
	sc.Buffer(make([]byte, 0, 64*1024), 1<<20)
	var out []shapePoint
	for sc.Scan() {
		line := sc.Bytes()
		if !bytes.HasPrefix(line, []byte(prefix)) {
			continue
		}
		rest := line[len(prefix):]
		latStr, rest2 := cutField(rest)
		lonStr, rest3 := cutField(rest2)
		seqStr, _ := cutField(rest3)
		seq, err := strconv.Atoi(seqStr)
		if err != nil {
			continue
		}
		lat, _ := strconv.ParseFloat(latStr, 64)
		lon, _ := strconv.ParseFloat(lonStr, 64)
		out = append(out, shapePoint{Seq: seq, Lat: lat, Lon: lon})
	}
	return out
}

// cutField liefert das erste Komma-Feld und den Rest (Bytes-sparend, kein Alloc der ganzen Zeile als Strings).
func cutField(b []byte) (string, []byte) {
	if i := bytes.IndexByte(b, ','); i >= 0 {
		return string(b[:i]), b[i+1:]
	}
	return string(b), nil
}

// extractLargeFiles entpackt stop_times.txt + shapes.txt einmalig nach
// data/gtfs/extracted/ – danach laufen Scans auf Raw-Dateien (schnell).
func extractLargeFiles() {
	extractMu.Lock()
	defer extractMu.Unlock()
	if extractionDone {
		return
	}
	if err := os.MkdirAll(gtfsExtractDir, 0755); err != nil {
		log.Printf("[GTFS] extract mkdir: %v", err)
		return
	}
	targets := map[string]string{
		"stop_times.txt": filepath.Join(gtfsExtractDir, "stop_times.txt"),
		"shapes.txt":     filepath.Join(gtfsExtractDir, "shapes.txt"),
	}
	start := time.Now()
	for name, target := range targets {
		if fi, err := os.Stat(target); err == nil && fi.Size() > 1_000_000 { // schon da
			continue
		}
		if err := extractZipEntry(name, target); err != nil {
			log.Printf("[GTFS] extract %s fehlgeschlagen: %v", name, err)
			return // zip evtl. gesperrt; nächster Request versucht erneut via lazy path
		}
		log.Printf("[GTFS] extrahiert %s in %v", name, time.Since(start))
	}
	stopTimesFile = targets["stop_times.txt"]
	shapeFile = targets["shapes.txt"]
	extractionDone = true
	log.Printf("[GTFS] Extraktion fertig in %v – Raw-Scans aktiv", time.Since(start))
}

func extractZipEntry(entryName, target string) error {
	f, err := os.Open(gtfsZipPath)
	if err != nil {
		return err
	}
	defer f.Close()
	fi, _ := f.Stat()
	zr, err := zip.NewReader(f, fi.Size())
	if err != nil {
		return err
	}
	var zf *zip.File
	for _, file := range zr.File {
		if file.Name == entryName {
			zf = file
			break
		}
	}
	if zf == nil {
		return fmt.Errorf("%s nicht im zip", entryName)
	}
	rc, err := zf.Open()
	if err != nil {
		return err
	}
	defer rc.Close()
	tmp := target + ".tmp"
	out, err := os.Create(tmp)
	if err != nil {
		return err
	}
	n, err := io.Copy(out, rc)
	out.Close()
	if err != nil {
		os.Remove(tmp)
		return err
	}
	if err := os.Rename(tmp, target); err != nil {
		return err
	}
	debugf("[GTFS] %s -> %s (%d bytes)", entryName, target, n)
	return nil
}

// openScanSource öffnet entweder die extrahierte Raw-Datei oder den Zip-Eintrag.
// Liefert io.ReadCloser + cleanup func.
func openScanSource(entryName string) (io.ReadCloser, func(), error) {
	extractMu.Lock()
	done := extractionDone
	stopF, shapeF := stopTimesFile, shapeFile
	extractMu.Unlock()

	var path string
	switch entryName {
	case "stop_times.txt":
		path = stopF
	case "shapes.txt":
		path = shapeF
	}
	if done && path != "" {
		if f, err := os.Open(path); err == nil {
			return struct {
				io.Reader
				io.Closer
			}{bufio.NewReaderSize(f, 1<<20), f}, func() { f.Close() }, nil
		}
	}
	// Fallback: aus Zip streamen
	f, err := os.Open(gtfsZipPath)
	if err != nil {
		return nil, nil, err
	}
	fi, _ := f.Stat()
	zr, err := zip.NewReader(f, fi.Size())
	if err != nil {
		f.Close()
		return nil, nil, err
	}
	var zf *zip.File
	for _, file := range zr.File {
		if file.Name == entryName {
			zf = file
			break
		}
	}
	if zf == nil {
		f.Close()
		return nil, nil, fmt.Errorf("%s nicht im zip", entryName)
	}
	rc, err := zf.Open()
	if err != nil {
		f.Close()
		return nil, nil, err
	}
	return rc, func() { rc.Close(); f.Close() }, nil
}
