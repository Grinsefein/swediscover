package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
	"github.com/joho/godotenv"
)

// Konfiguration
var (
	// Gemeinsamer HTTP-Client für alle Trafiklab/GTFS-RT-Upstream-Calls.
	apiClient = &http.Client{Timeout: 15 * time.Second}
	// ResRobot Journey Planning kann bei komplexen Routen länger dauern.
	journeyClient = &http.Client{Timeout: 30 * time.Second}
)

// Config enthält alle API-Keys und Einstellungen. WICHTIG: Wird erst NACH
// godotenv.Load() in main() befüllt – Package-Variablen werden vor main()
// initialisiert und würden ein .env nie sehen (klassischer Init-Order-Bug).
type Config struct {
	TrafiklabKey    string
	RealtimeApisKey string // Trafiklab realtime APIs (Timetables/StopLookup/Trips)
	GtfsRtKey       string
	GtfsStaticKey   string
	StopsKey        string
	ResrobotKey     string
	TrafikverketKey string
	ServerPort      string
	// GTFS-RT Sweden liefert Feeds pro Operator. Default deckt die großen
	// Regionen ab (Quota schonen); per Env erweiterbar, z.B.
	// GTFS_RT_OPERATORS="sl,skane,ul,xt,otraf,klt,varm,dt,vastmanland".
	GtfsRtOperators []string
}

var cfg Config

// Debug-Logging: via DEBUG=1 oder LOG_LEVEL=debug aktivierbar.
// Immer eingeschaltete INFO-Logs bleiben davon unberührt.
var debugEnabled bool

func debugf(format string, args ...interface{}) {
	if debugEnabled {
		log.Printf("[DEBUG] "+format, args...)
	}
}

func maskKey(key string) string {
	if key == "" {
		return "<empty>"
	}
	if len(key) <= 8 {
		return "***"
	}
	return key[:4] + "***" + key[len(key)-4:]
}

// statusWriter fängt HTTP-Status und Byte-Zähler für Logging-Middleware ab.
type statusWriter struct {
	http.ResponseWriter
	status int
	bytes  int
}

func (w *statusWriter) WriteHeader(code int) {
	w.status = code
	w.ResponseWriter.WriteHeader(code)
}

func (w *statusWriter) Write(b []byte) (int, error) {
	if w.status == 0 {
		w.status = http.StatusOK
	}
	n, err := w.ResponseWriter.Write(b)
	w.bytes += n
	return n, err
}

// Hijack leitet an den zugrundeliegenden Writer weiter, damit WebSocket-
// Upgrades (/ws) auch durch die Logging-Middleware funktionieren.
func (w *statusWriter) Hijack() (net.Conn, *bufio.ReadWriter, error) {
	h, ok := w.ResponseWriter.(http.Hijacker)
	if !ok {
		return nil, nil, fmt.Errorf("statusWriter: underlying ResponseWriter does not implement http.Hijacker")
	}
	w.status = http.StatusSwitchingProtocols
	return h.Hijack()
}

// Flush reicht Flusher durch (SSE/Streaming-Kompatibilität).
func (w *statusWriter) Flush() {
	if f, ok := w.ResponseWriter.(http.Flusher); ok {
		f.Flush()
	}
}

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		sw := &statusWriter{ResponseWriter: w}
		next.ServeHTTP(sw, r)
		if sw.status == 0 {
			sw.status = http.StatusOK
		}
		duration := time.Since(start)
		// Cache-Hit wird von den Handlern als X-Cache Header gesetzt, falls vorhanden
		cacheHdr := sw.Header().Get("X-Cache")
		if cacheHdr == "" {
			cacheHdr = "-"
		}
		log.Printf("[HTTP] %s %s%s -> %d (%d bytes, cache=%s) %s %v",
			r.Method, r.URL.Path,
			func() string {
				if r.URL.RawQuery != "" {
					// Query ohne API-Keys loggen (Keys maskieren)
					q := r.URL.Query()
					for _, k := range []string{"key", "apikey", "accessId"} {
						if q.Get(k) != "" {
							q.Set(k, "***")
						}
					}
					enc := q.Encode()
					if enc != "" {
						return "?" + enc
					}
				}
				return ""
			}(),
			sw.status, sw.bytes, cacheHdr, r.RemoteAddr, duration)
	})
}

func loadConfig() {
	cfg = Config{
		TrafiklabKey:    getEnv("TRAFIKLAB_API_KEY", ""),
		RealtimeApisKey: getEnv("TRAFIKLAB_REALTIME_APIS", ""),
		GtfsRtKey:       getEnv("GTFS_SWEDEN_3_REALTIME", ""),
		GtfsStaticKey:   getEnv("GTFS_SWEDEN_3_STATIC", ""),
		StopsKey:        getEnv("STOPS", ""),
		ResrobotKey:     getEnv("RES_ROBOT_V2_1", ""),
		TrafikverketKey: getEnv("TRAFIKVERKET_API_KEY", ""),
		ServerPort:      getEnv("SERVER_PORT", "8080"),
		GtfsRtOperators: strings.Split(getEnv("GTFS_RT_OPERATORS", "sl,skane,ul,xt"), ","),
	}
	if cfg.RealtimeApisKey == "" {
		cfg.RealtimeApisKey = cfg.TrafiklabKey
	}

	// Debug-Flag auswerten (DEBUG=1 / true / LOG_LEVEL=debug)
	lvl := strings.ToLower(getEnv("LOG_LEVEL", ""))
	dbg := strings.ToLower(getEnv("DEBUG", ""))
	debugEnabled = dbg == "1" || dbg == "true" || dbg == "yes" || lvl == "debug"

	// Konfig-Summary mit maskierten Keys (immer loggen, kein Secret-Leak)
	log.Printf("[CONFIG] ServerPort=%s Operators=%v Debug=%v", cfg.ServerPort, cfg.GtfsRtOperators, debugEnabled)
	log.Printf("[CONFIG] Keys: TRAFIKLAB_API_KEY=%s TRAFIKLAB_REALTIME_APIS=%s GTFS_SWEDEN_3_REALTIME=%s GTFS_SWEDEN_3_STATIC=%s STOPS=%s RES_ROBOT_V2_1=%s TRAFIKVERKET_API_KEY=%s",
		maskKey(cfg.TrafiklabKey), maskKey(cfg.RealtimeApisKey), maskKey(cfg.GtfsRtKey), maskKey(cfg.GtfsStaticKey), maskKey(cfg.StopsKey), maskKey(cfg.ResrobotKey), maskKey(cfg.TrafikverketKey))
	log.Printf("[CONFIG] Clients: apiClient Timeout=%v journeyClient Timeout=%v CacheTTL=%v",
		apiClient.Timeout, journeyClient.Timeout, cacheTTL)
	if cfg.GtfsRtKey == "" {
		log.Println("⚠️  GTFS_SWEDEN_3_REALTIME nicht gesetzt – /api/vehicles, /api/trip-updates und /api/service-alerts liefern leere Daten")
	}
	// Warnung wenn RealtimeApisKey fehlt (Departures/Stops/Trips brauchen ihn)
	if cfg.RealtimeApisKey == "" {
		log.Println("⚠️  TRAFIKLAB_REALTIME_APIS (und TRAFIKLAB_API_KEY) leer – /api/departures, /api/stops/search, /api/trip/* werden fehlschlagen")
	}
	if cfg.ResrobotKey == "" {
		log.Println("⚠️  RES_ROBOT_V2_1 leer – /api/journey wird fehlschlagen")
	}
}

// Telemetrie-Metriken
type Telemetry struct {
	mu                       sync.RWMutex
	TotalClientRequests      int64   `json:"totalClientRequests"`
	UpstreamCallsMade        int64   `json:"upstreamCallsMade"`
	CollapsedRequests        int64   `json:"collapsedRequests"`
	NetworkSavingsPercent    float64 `json:"networkSavingsPercent"`
	ProtobufBytesProcessed   int64   `json:"protobufBytesProcessed"`
	JSONStreamBytesEmitted   int64   `json:"jsonStreamBytesEmitted"`
	ActiveVehiclesInSweden   int     `json:"activeVehiclesInSweden"`
	ActiveVehiclesInViewport int     `json:"activeVehiclesInViewport"`
}

var telemetry = &Telemetry{}

// Request-Collapsing Cache
type cacheEntry struct {
	data      interface{}
	expiresAt time.Time
}

var (
	departuresCache  = make(map[string]*cacheEntry)
	vehiclesCache    *cacheEntry
	tripUpdatesCache *cacheEntry
	cacheMu          sync.RWMutex
	cacheTTL         = 15 * time.Second
)

// WebSocket Upgrader
var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // Für Development, in Production restriktiver machen
	},
}

// Departure Response
type DepartureResponse struct {
	Departures []interface{} `json:"departures"`
	Telemetry  Telemetry     `json:"telemetry"`
}

// Vehicles Response
type VehiclesResponse struct {
	Vehicles  []interface{} `json:"vehicles"`
	Telemetry Telemetry     `json:"telemetry"`
}

// TripUpdates Response
type TripUpdatesResponse struct {
	TripUpdates []interface{} `json:"tripUpdates"`
	Telemetry   Telemetry     `json:"telemetry"`
}

func main() {
	// Timestamps + Datei:Zeile für bessere Diagnose
	log.SetFlags(log.LstdFlags | log.Lmicroseconds | log.Lshortfile)

	// .env Datei laden
	if err := godotenv.Load(); err != nil {
		log.Println("Keine .env Datei gefunden, nutze System-Env-Vars")
	}
	loadConfig()

	r := mux.NewRouter()
	// Request-Logging für alle Routen
	r.Use(loggingMiddleware)

	// API Routes
	r.HandleFunc("/api/departures", handleDepartures).Methods("GET")
	r.HandleFunc("/api/vehicles", handleVehicles).Methods("GET")
	r.HandleFunc("/api/stops/search", handleStopsSearch).Methods("GET")
	r.HandleFunc("/api/trip/{tripId}", handleTripDetails).Methods("GET")
	r.HandleFunc("/api/trip-details/{vehicleId}", handleTripDetailsByVehicle).Methods("GET")
	r.HandleFunc("/api/cameras", handleCameras).Methods("GET")
	r.HandleFunc("/api/service-alerts", handleServiceAlerts).Methods("GET")
	r.HandleFunc("/api/trip-updates", handleTripUpdates).Methods("GET")
	r.HandleFunc("/api/journey", handleJourneyPlanning).Methods("GET")
	r.HandleFunc("/api/situations", handleSituations).Methods("GET")
	r.HandleFunc("/api/health", handleHealth).Methods("GET")
	r.HandleFunc("/api/debug", handleDebug).Methods("GET")

	// GTFS static bootstrap im Hintergrund (lädt sweden.zip, baut Indizes)
	go func() {
		if err := ensureGtfsReady(); err != nil {
			log.Printf("[GTFS] background init: %v (endpoint /api/trip-details wird degraded antworten)", err)
		}
	}()

	// WebSocket Route
	r.HandleFunc("/ws", handleWebSocket)

	log.Printf("🚀 Server startet auf Port %s", cfg.ServerPort)
	debugf("Registered routes: /api/departures, /api/vehicles, /api/stops/search, /api/trip/{tripId}, /api/cameras, /api/service-alerts, /api/trip-updates, /api/journey, /api/situations, /api/health, /api/debug, /ws")
	srv := &http.Server{
		Addr:         ":" + cfg.ServerPort,
		Handler:      r,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 60 * time.Second,
		IdleTimeout:  120 * time.Second,
	}
	log.Fatal(srv.ListenAndServe())
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":    "ok",
		"time":      time.Now().UTC().Format(time.RFC3339),
		"uptime":    time.Since(startTime).String(),
		"telemetry": getTelemetrySnapshot(),
	})
}

var startTime = time.Now()

func handleDebug(w http.ResponseWriter, r *http.Request) {
	// Liefert maskierte Config + Telemetry + Cache-Stats. Kein Secret-Leak.
	cacheMu.RLock()
	depCacheSize := len(departuresCache)
	vehCached := vehiclesCache != nil && time.Now().Before(vehiclesCache.expiresAt)
	tuCached := tripUpdatesCache != nil && time.Now().Before(tripUpdatesCache.expiresAt)
	cacheMu.RUnlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"config": map[string]interface{}{
			"serverPort":      cfg.ServerPort,
			"operators":       cfg.GtfsRtOperators,
			"debug":           debugEnabled,
			"cacheTTL":        cacheTTL.String(),
			"apiTimeout":      apiClient.Timeout.String(),
			"journeyTimeout":  journeyClient.Timeout.String(),
			"keysPresent": map[string]bool{
				"TRAFIKLAB_API_KEY":        cfg.TrafiklabKey != "",
				"TRAFIKLAB_REALTIME_APIS":  cfg.RealtimeApisKey != "",
				"GTFS_SWEDEN_3_REALTIME":   cfg.GtfsRtKey != "",
				"GTFS_SWEDEN_3_STATIC":     cfg.GtfsStaticKey != "",
				"STOPS":                    cfg.StopsKey != "",
				"RES_ROBOT_V2_1":           cfg.ResrobotKey != "",
				"TRAFIKVERKET_API_KEY":     cfg.TrafikverketKey != "",
			},
			"keysMasked": map[string]string{
				"TRAFIKLAB_API_KEY":        maskKey(cfg.TrafiklabKey),
				"TRAFIKLAB_REALTIME_APIS":  maskKey(cfg.RealtimeApisKey),
				"GTFS_SWEDEN_3_REALTIME":   maskKey(cfg.GtfsRtKey),
				"RES_ROBOT_V2_1":           maskKey(cfg.ResrobotKey),
				"TRAFIKVERKET_API_KEY":     maskKey(cfg.TrafikverketKey),
			},
		},
		"telemetry": getTelemetrySnapshot(),
		"cache": map[string]interface{}{
			"departuresEntries": depCacheSize,
			"vehiclesCached":    vehCached,
			"tripUpdatesCached": tuCached,
		},
		"gtfs": map[string]interface{}{
			"ready":      isGtfsReady(),
			"zipPath":    gtfsZipPath,
			"stops":      len(stopIndex),
			"routes":     len(routeIndex),
			"trips":      len(tripIndex),
			"initError":  func() string { if gtfsInitErr != nil { return gtfsInitErr.Error() }; return "" }(),
		},
	})
}

func handleDepartures(w http.ResponseWriter, r *http.Request) {
	telemetry.mu.Lock()
	telemetry.TotalClientRequests++
	telemetry.mu.Unlock()

	stopID := r.URL.Query().Get("stopId")
	if stopID == "" {
		log.Printf("[DEPARTURES] 400 missing stopId from %s", r.RemoteAddr)
		http.Error(w, "stopId parameter required", http.StatusBadRequest)
		return
	}
	debugf("[DEPARTURES] request stopId=%s from %s", stopID, r.RemoteAddr)

	// Request-Collapsing: Prüfen ob Cache noch gültig
	cacheMu.RLock()
	if entry, ok := departuresCache[stopID]; ok && time.Now().Before(entry.expiresAt) {
		cacheMu.RUnlock()
		telemetry.mu.Lock()
		telemetry.CollapsedRequests++
		telemetry.mu.Unlock()
		log.Printf("[DEPARTURES] cache HIT stopId=%s -> %d departures (collapsed)", stopID, len(entry.data.([]interface{})))
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("X-Cache", "HIT")
		json.NewEncoder(w).Encode(DepartureResponse{
			Departures: entry.data.([]interface{}),
			Telemetry:  getTelemetrySnapshot(),
		})
		return
	}
	cacheMu.RUnlock()
	debugf("[DEPARTURES] cache MISS stopId=%s -> upstream fetch", stopID)

	// Echter API-Aufruf zu Trafiklab
	start := time.Now()
	departures, err := fetchDeparturesFromTrafiklab(stopID)
	if err != nil {
		log.Printf("[DEPARTURES] upstream ERROR stopId=%s err=%v duration=%v", stopID, err, time.Since(start))
		http.Error(w, fmt.Sprintf("Failed to fetch departures: %v", err), http.StatusInternalServerError)
		return
	}
	log.Printf("[DEPARTURES] upstream OK stopId=%s -> %d departures in %v", stopID, len(departures), time.Since(start))

	telemetry.mu.Lock()
	telemetry.UpstreamCallsMade++
	telemetry.mu.Unlock()

	// Cache speichern
	cacheMu.Lock()
	departuresCache[stopID] = &cacheEntry{
		data:      departures,
		expiresAt: time.Now().Add(cacheTTL),
	}
	cacheMu.Unlock()

	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("X-Cache", "MISS")
	json.NewEncoder(w).Encode(DepartureResponse{
		Departures: departures,
		Telemetry:  getTelemetrySnapshot(),
	})
}

func handleVehicles(w http.ResponseWriter, r *http.Request) {
	telemetry.mu.Lock()
	telemetry.TotalClientRequests++
	telemetry.mu.Unlock()
	debugf("[VEHICLES] request from %s", r.RemoteAddr)

	// Request-Collapsing für Fahrzeuge
	cacheMu.RLock()
	if vehiclesCache != nil && time.Now().Before(vehiclesCache.expiresAt) {
		cacheMu.RUnlock()
		telemetry.mu.Lock()
		telemetry.CollapsedRequests++
		telemetry.mu.Unlock()
		n := len(vehiclesCache.data.([]interface{}))
		log.Printf("[VEHICLES] cache HIT -> %d vehicles (collapsed)", n)
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("X-Cache", "HIT")
		json.NewEncoder(w).Encode(VehiclesResponse{
			Vehicles:  vehiclesCache.data.([]interface{}),
			Telemetry: getTelemetrySnapshot(),
		})
		return
	}
	cacheMu.RUnlock()
	debugf("[VEHICLES] cache MISS -> GTFS-RT fetch (operators=%v)", cfg.GtfsRtOperators)

	// GTFS-RT Fahrzeugpositionen abrufen
	start := time.Now()
	vehicles, err := fetchVehiclesFromGTFSRT()
	if err != nil {
		log.Printf("[VEHICLES] ERROR err=%v duration=%v", err, time.Since(start))
		http.Error(w, fmt.Sprintf("Failed to fetch vehicles: %v", err), http.StatusInternalServerError)
		return
	}
	dur := time.Since(start)
	log.Printf("[VEHICLES] OK -> %d vehicles in %v (protobuf=%d bytes)", len(vehicles), dur, func() int64 {
		telemetry.mu.RLock()
		defer telemetry.mu.RUnlock()
		return telemetry.ProtobufBytesProcessed
	}())

	telemetry.mu.Lock()
	telemetry.UpstreamCallsMade++
	telemetry.ActiveVehiclesInSweden = len(vehicles)
	telemetry.mu.Unlock()

	// Cache speichern
	cacheMu.Lock()
	vehiclesCache = &cacheEntry{
		data:      vehicles,
		expiresAt: time.Now().Add(cacheTTL),
	}
	cacheMu.Unlock()

	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("X-Cache", "MISS")
	json.NewEncoder(w).Encode(VehiclesResponse{
		Vehicles:  vehicles,
		Telemetry: getTelemetrySnapshot(),
	})
}

func handleStopsSearch(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query().Get("q")
	if query == "" {
		log.Printf("[STOPS] 400 missing q from %s", r.RemoteAddr)
		http.Error(w, "q parameter required", http.StatusBadRequest)
		return
	}
	debugf("[STOPS] search q=%q from %s", query, r.RemoteAddr)
	start := time.Now()
	stops, err := searchStops(query)
	if err != nil {
		log.Printf("[STOPS] ERROR q=%q err=%v duration=%v", query, err, time.Since(start))
		http.Error(w, fmt.Sprintf("Failed to search stops: %v", err), http.StatusInternalServerError)
		return
	}
	log.Printf("[STOPS] OK q=%q -> %d stops in %v", query, len(stops), time.Since(start))
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"stops": stops,
	})
}

func handleTripDetails(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	tripID := vars["tripId"]
	date := r.URL.Query().Get("date")

	if tripID == "" {
		log.Printf("[TRIP] 400 missing tripId from %s", r.RemoteAddr)
		http.Error(w, "tripId required", http.StatusBadRequest)
		return
	}
	debugf("[TRIP] request tripId=%s date=%s from %s", tripID, date, r.RemoteAddr)
	start := time.Now()
	// GTFS-RT-IDs sind operator-getaggt ("sl:12345") – Upstream erwartet die rohe ID
	tripDetails, err := fetchTripDetails(stripOperatorTag(tripID), date)
	if err != nil {
		log.Printf("[TRIP] ERROR tripId=%s err=%v duration=%v", tripID, err, time.Since(start))
		http.Error(w, fmt.Sprintf("Failed to fetch trip details: %v", err), http.StatusInternalServerError)
		return
	}
	log.Printf("[TRIP] OK tripId=%s in %v", tripID, time.Since(start))
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(tripDetails)
}

func handleCameras(w http.ResponseWriter, r *http.Request) {
	debugf("[CAMERAS] request from %s", r.RemoteAddr)
	start := time.Now()
	cameras, err := fetchTrafficCameras()
	if err != nil {
		log.Printf("[CAMERAS] ERROR err=%v duration=%v", err, time.Since(start))
		http.Error(w, fmt.Sprintf("Failed to fetch cameras: %v", err), http.StatusInternalServerError)
		return
	}
	log.Printf("[CAMERAS] OK -> %d cameras in %v", len(cameras), time.Since(start))
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"cameras": cameras,
	})
}

func handleServiceAlerts(w http.ResponseWriter, r *http.Request) {
	debugf("[ALERTS] request from %s", r.RemoteAddr)
	start := time.Now()
	alerts, err := fetchServiceAlertsFromGTFSRT()
	if err != nil {
		log.Printf("[ALERTS] ERROR err=%v duration=%v", err, time.Since(start))
		http.Error(w, fmt.Sprintf("Failed to fetch service alerts: %v", err), http.StatusInternalServerError)
		return
	}
	log.Printf("[ALERTS] OK -> %d alerts in %v", len(alerts), time.Since(start))
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"alerts": alerts,
	})
}

func handleTripUpdates(w http.ResponseWriter, r *http.Request) {
	telemetry.mu.Lock()
	telemetry.TotalClientRequests++
	telemetry.mu.Unlock()
	debugf("[TRIP-UPDATES] request from %s", r.RemoteAddr)

	cacheMu.RLock()
	if tripUpdatesCache != nil && time.Now().Before(tripUpdatesCache.expiresAt) {
		cacheMu.RUnlock()
		telemetry.mu.Lock()
		telemetry.CollapsedRequests++
		telemetry.mu.Unlock()
		n := len(tripUpdatesCache.data.([]interface{}))
		log.Printf("[TRIP-UPDATES] cache HIT -> %d tripUpdates", n)
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("X-Cache", "HIT")
		json.NewEncoder(w).Encode(TripUpdatesResponse{
			TripUpdates: tripUpdatesCache.data.([]interface{}),
			Telemetry:   getTelemetrySnapshot(),
		})
		return
	}
	cacheMu.RUnlock()
	debugf("[TRIP-UPDATES] cache MISS -> GTFS-RT fetch")

	start := time.Now()
	tripUpdates, err := fetchTripUpdatesFromGTFSRT()
	if err != nil {
		log.Printf("[TRIP-UPDATES] ERROR err=%v duration=%v", err, time.Since(start))
		http.Error(w, fmt.Sprintf("Failed to fetch trip updates: %v", err), http.StatusInternalServerError)
		return
	}
	log.Printf("[TRIP-UPDATES] OK -> %d tripUpdates in %v", len(tripUpdates), time.Since(start))

	telemetry.mu.Lock()
	telemetry.UpstreamCallsMade++
	telemetry.mu.Unlock()

	cacheMu.Lock()
	tripUpdatesCache = &cacheEntry{
		data:      tripUpdates,
		expiresAt: time.Now().Add(cacheTTL),
	}
	cacheMu.Unlock()

	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("X-Cache", "MISS")
	json.NewEncoder(w).Encode(TripUpdatesResponse{
		TripUpdates: tripUpdates,
		Telemetry:   getTelemetrySnapshot(),
	})
}

func handleWebSocket(w http.ResponseWriter, r *http.Request) {
	log.Printf("[WS] upgrade attempt from %s (broadcast=%s bbox=%.4f,%.4f,%.4f,%.4f)", r.RemoteAddr, r.URL.Query().Get("broadcast"), mustParseFloat(r.URL.Query().Get("minLat")), mustParseFloat(r.URL.Query().Get("minLng")), mustParseFloat(r.URL.Query().Get("maxLat")), mustParseFloat(r.URL.Query().Get("maxLng")))
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("[WS] upgrade ERROR from %s: %v", r.RemoteAddr, err)
		return
	}
	defer conn.Close()
	log.Printf("[WS] connected %s", r.RemoteAddr)

	broadcast := r.URL.Query().Get("broadcast") == "vehicles"
	minLat, _ := strconv.ParseFloat(r.URL.Query().Get("minLat"), 64)
	minLng, _ := strconv.ParseFloat(r.URL.Query().Get("minLng"), 64)
	maxLat, _ := strconv.ParseFloat(r.URL.Query().Get("maxLat"), 64)
	maxLng, _ := strconv.ParseFloat(r.URL.Query().Get("maxLng"), 64)

	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			var vehicles []interface{}
			var err error

			if broadcast {
				vehicles, err = fetchVehiclesFromGTFSRT()
				if err != nil {
					log.Printf("[WS] fetchVehicles ERROR for %s: %v", r.RemoteAddr, err)
					continue
				}

				// Bounding Box Filterung
				if minLat != 0 || minLng != 0 || maxLat != 0 || maxLng != 0 {
					filtered := filterVehiclesByBBox(vehicles, minLat, minLng, maxLat, maxLng)
					debugf("[WS] bbox filter %s: %d -> %d vehicles", r.RemoteAddr, len(vehicles), len(filtered))
					vehicles = filtered
					telemetry.mu.Lock()
					telemetry.ActiveVehiclesInViewport = len(vehicles)
					telemetry.mu.Unlock()
				}
			}

			message := map[string]interface{}{
				"type":      "vehicles",
				"items":     vehicles,
				"timestamp": time.Now().Unix(),
			}

			if err := conn.WriteJSON(message); err != nil {
				log.Printf("[WS] write ERROR to %s: %v (closing)", r.RemoteAddr, err)
				return
			}
			debugf("[WS] sent %d vehicles to %s", len(vehicles), r.RemoteAddr)
		}
	}
}

func mustParseFloat(s string) float64 {
	v, _ := strconv.ParseFloat(s, 64)
	return v
}

// Helper-Funktionen mit echten API-Calls

func fetchDeparturesFromTrafiklab(stopID string) ([]interface{}, error) {
	// Trafiklab realtime APIs - Timetables Endpoint
	// GET https://realtime-api.trafiklab.se/v1/departures/{stopId}?key=...
	maskedURL := fmt.Sprintf("https://realtime-api.trafiklab.se/v1/departures/%s?key=%s", url.PathEscape(stopID), maskKey(cfg.RealtimeApisKey))
	debugf("[UPSTREAM] departures GET %s", maskedURL)
	start := time.Now()
	resp, err := apiClient.Get(fmt.Sprintf(
		"https://realtime-api.trafiklab.se/v1/departures/%s?key=%s",
		url.PathEscape(stopID), cfg.RealtimeApisKey))
	if err != nil {
		log.Printf("[UPSTREAM] departures ERROR stopId=%s after %v: %v (type=%T)", stopID, time.Since(start), err, err)
		return nil, fmt.Errorf("departures upstream %s failed: %w", maskedURL, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		// Body-Snippet für Diagnose (z.B. 401 Key ungültig, 429 Quota)
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
		snippet := strings.TrimSpace(string(body))
		if len(snippet) > 200 {
			snippet = snippet[:200] + "..."
		}
		log.Printf("[UPSTREAM] departures HTTP %d stopId=%s after %v body=%q", resp.StatusCode, stopID, time.Since(start), snippet)
		return nil, fmt.Errorf("API returned status %d body=%q", resp.StatusCode, snippet)
	}

	var result struct {
		Departures []map[string]interface{} `json:"departures"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		log.Printf("[UPSTREAM] departures JSON decode ERROR stopId=%s after %v: %v", stopID, time.Since(start), err)
		return nil, fmt.Errorf("departures decode: %w", err)
	}

	departures := make([]interface{}, 0, len(result.Departures))
	for i, item := range result.Departures {
		departures = append(departures, transformTimetableDeparture(item, stopID, i))
	}
	debugf("[UPSTREAM] departures OK stopId=%s -> %d items in %v", stopID, len(departures), time.Since(start))
	return departures, nil
}

func searchStops(query string) ([]interface{}, error) {
	// Trafiklab realtime APIs - Stop Lookup Endpoint
	// GET https://realtime-api.trafiklab.se/v1/stops/name/{searchValue}?key=...
	maskedURL := fmt.Sprintf("https://realtime-api.trafiklab.se/v1/stops/name/%s?key=%s", url.PathEscape(query), maskKey(cfg.RealtimeApisKey))
	debugf("[UPSTREAM] stops GET %s", maskedURL)
	start := time.Now()
	resp, err := apiClient.Get(fmt.Sprintf(
		"https://realtime-api.trafiklab.se/v1/stops/name/%s?key=%s",
		url.PathEscape(query), cfg.RealtimeApisKey))
	if err != nil {
		log.Printf("[UPSTREAM] stops ERROR q=%q after %v: %v", query, time.Since(start), err)
		return nil, fmt.Errorf("stops upstream %s failed: %w", maskedURL, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
		snippet := strings.TrimSpace(string(body))
		log.Printf("[UPSTREAM] stops HTTP %d q=%q after %v body=%q", resp.StatusCode, query, time.Since(start), snippet)
		return nil, fmt.Errorf("API returned status %d", resp.StatusCode)
	}

	var result struct {
		StopGroups []map[string]interface{} `json:"stop_groups"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		log.Printf("[UPSTREAM] stops decode ERROR q=%q after %v: %v", query, time.Since(start), err)
		return nil, err
	}

	stops := make([]interface{}, 0, len(result.StopGroups))
	for _, group := range result.StopGroups {
		stops = append(stops, transformStopGroup(group))
	}
	debugf("[UPSTREAM] stops OK q=%q -> %d groups in %v", query, len(stops), time.Since(start))
	return stops, nil
}

func fetchTripDetails(tripID, date string) (interface{}, error) {
	// Trafiklab realtime APIs - Trip Details Endpoint
	// GET https://realtime-api.trafiklab.se/v1/trips/{tripId}/{startDate}?key=...
	if date == "" {
		date = time.Now().Format("2006-01-02")
	}
	maskedURL := fmt.Sprintf("https://realtime-api.trafiklab.se/v1/trips/%s/%s?key=%s",
		url.PathEscape(tripID), url.PathEscape(date), maskKey(cfg.RealtimeApisKey))
	debugf("[UPSTREAM] trip GET %s", maskedURL)
	start := time.Now()
	req, err := http.NewRequest("GET", fmt.Sprintf(
		"https://realtime-api.trafiklab.se/v1/trips/%s/%s?key=%s",
		url.PathEscape(tripID), url.PathEscape(date), cfg.RealtimeApisKey), nil)
	if err != nil {
		return nil, err
	}

	resp, err := apiClient.Do(req)
	if err != nil {
		log.Printf("[UPSTREAM] trip ERROR tripId=%s after %v: %v", tripID, time.Since(start), err)
		return nil, fmt.Errorf("trip upstream %s failed: %w", maskedURL, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
		log.Printf("[UPSTREAM] trip HTTP %d tripId=%s after %v body=%q", resp.StatusCode, tripID, time.Since(start), strings.TrimSpace(string(body)))
		return nil, fmt.Errorf("API returned status %d", resp.StatusCode)
	}

	var result interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		log.Printf("[UPSTREAM] trip decode ERROR tripId=%s after %v: %v", tripID, time.Since(start), err)
		return nil, err
	}
	debugf("[UPSTREAM] trip OK tripId=%s in %v", tripID, time.Since(start))
	return result, nil
}

func fetchTrafficCameras() ([]interface{}, error) {
	// Trafikverket Camera API - echte Verkehrskameras
	// https://api.trafikinfo.trafikverket.se/v2/data.json
	xmlQuery := `
		<QUERYOBJECT>
			<CAMERA>
				<ID/>
				<Name/>
				<Active>true</Active>
				<Status>
					<Code/>
					<Description/>
				</Status>
				<Location>
					<RoadNumber/>
					<RoadName/>
					<Direction/>
					<Coordinate System="WGS84">
						<Latitude/>
						<Longitude/>
					</Coordinate>
				</Location>
				<CameraPhoto>
					<URL/>
					<Updated/>
				</CameraPhoto>
			</CAMERA>
		</QUERYOBJECT>
	`

	client := apiClient
	req, err := http.NewRequest("POST", "https://api.trafikinfo.trafikverket.se/v2/data.json",
		strings.NewReader(xmlQuery))
	if err != nil {
		return nil, err
	}

	req.Header.Set("Content-Type", "application/xml")
	if cfg.TrafikverketKey != "" {
		req.Header.Set("Authorization", "Bearer "+cfg.TrafikverketKey)
	}
	debugf("[UPSTREAM] cameras POST %s (key=%s)", req.URL.String(), maskKey(cfg.TrafikverketKey))
	start := time.Now()
	resp, err := client.Do(req)
	if err != nil {
		log.Printf("[UPSTREAM] cameras ERROR after %v: %v", time.Since(start), err)
		return nil, fmt.Errorf("cameras upstream failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
		log.Printf("[UPSTREAM] cameras HTTP %d after %v body=%q", resp.StatusCode, time.Since(start), strings.TrimSpace(string(body)))
		return nil, fmt.Errorf("Trafikverket API returned status %d", resp.StatusCode)
	}
	debugf("[UPSTREAM] cameras HTTP %d in %v", resp.StatusCode, time.Since(start))

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	// Kamera-Daten extrahieren und transformieren
	cameras := []interface{}{}
	if response, ok := result["RESPONSE"].(map[string]interface{}); ok {
		if resultData, ok := response["RESULT"].([]interface{}); ok {
			for _, item := range resultData {
				if cameraMap, ok := item.(map[string]interface{}); ok {
					camera := transformCameraData(cameraMap)
					if camera != nil {
						cameras = append(cameras, camera)
					}
				}
			}
		}
	}

	return cameras, nil
}

func transformCameraData(cameraMap map[string]interface{}) map[string]interface{} {
	// Transformiere Trafikverket Camera-Daten in unser Format
	camera := make(map[string]interface{})

	if id, ok := cameraMap["Id"]; ok {
		camera["id"] = id
	}

	if name, ok := cameraMap["Name"]; ok {
		camera["name"] = name
	}

	if location, ok := cameraMap["Location"].(map[string]interface{}); ok {
		if roadName, ok := location["RoadName"]; ok {
			camera["roadName"] = roadName
		}
		if roadNumber, ok := location["RoadNumber"]; ok {
			camera["roadNumber"] = roadNumber
		}
		if coord, ok := location["Coordinate"].(map[string]interface{}); ok {
			if lat, ok := coord["Latitude"]; ok {
				camera["latitude"] = lat
			}
			if lng, ok := coord["Longitude"]; ok {
				camera["longitude"] = lng
			}
		}
	}

	if status, ok := cameraMap["Status"].(map[string]interface{}); ok {
		if code, ok := status["Code"]; ok {
			camera["statusCode"] = code
		}
		if desc, ok := status["Description"]; ok {
			camera["statusDescription"] = desc
		}
		// Brückenstatus prüfen (Situation-Objecttype wäre besser, aber hier als Proxy)
		camera["isBridgeActive"] = false // TODO: Separate Situation-API abfragen
	}

	if photo, ok := cameraMap["CameraPhoto"].(map[string]interface{}); ok {
		if url, ok := photo["URL"]; ok {
			camera["imageUrl"] = url
		}
		if updated, ok := photo["Updated"]; ok {
			camera["lastUpdated"] = updated
		}
	}

	camera["active"] = true

	return camera
}

func filterVehiclesByBBox(vehicles []interface{}, minLat, minLng, maxLat, maxLng float64) []interface{} {
	filtered := []interface{}{}
	for _, v := range vehicles {
		if vm, ok := v.(map[string]interface{}); ok {
			if lat, ok := vm["latitude"].(float64); ok {
				if lng, ok := vm["longitude"].(float64); ok {
					if lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng {
						filtered = append(filtered, v)
					}
				}
			}
		}
	}
	return filtered
}

func getTelemetrySnapshot() Telemetry {
	telemetry.mu.RLock()
	defer telemetry.mu.RUnlock()
	return Telemetry{
		TotalClientRequests:      telemetry.TotalClientRequests,
		UpstreamCallsMade:        telemetry.UpstreamCallsMade,
		CollapsedRequests:        telemetry.CollapsedRequests,
		NetworkSavingsPercent:    telemetry.NetworkSavingsPercent,
		ProtobufBytesProcessed:   telemetry.ProtobufBytesProcessed,
		JSONStreamBytesEmitted:   telemetry.JSONStreamBytesEmitted,
		ActiveVehiclesInSweden:   telemetry.ActiveVehiclesInSweden,
		ActiveVehiclesInViewport: telemetry.ActiveVehiclesInViewport,
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func handleJourneyPlanning(w http.ResponseWriter, r *http.Request) {
	from := r.URL.Query().Get("from")
	to := r.URL.Query().Get("to")
	timeStr := r.URL.Query().Get("time")
	dateStr := r.URL.Query().Get("date")

	if from == "" || to == "" {
		log.Printf("[JOURNEY] 400 missing from/to from %s", r.RemoteAddr)
		http.Error(w, "from and to parameters required", http.StatusBadRequest)
		return
	}
	debugf("[JOURNEY] request from=%s to=%s time=%s date=%s from %s", from, to, timeStr, dateStr, r.RemoteAddr)
	start := time.Now()
	journey, err := fetchJourneyFromResRobot(from, to, timeStr, dateStr)
	if err != nil {
		log.Printf("[JOURNEY] ERROR from=%s to=%s err=%v duration=%v", from, to, err, time.Since(start))
		http.Error(w, fmt.Sprintf("Failed to fetch journey: %v", err), http.StatusInternalServerError)
		return
	}
	log.Printf("[JOURNEY] OK from=%s to=%s in %v", from, to, time.Since(start))
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(journey)
}

func fetchJourneyFromResRobot(from, to, timeStr, dateStr string) (interface{}, error) {
	// ResRobot v2.1 Journey Planning API
	// GET https://api.resrobot.se/v2.1/trip?originId=..&destId=..&accessId=..

	params := url.Values{}
	params.Set("originId", from)
	params.Set("destId", to)

	if timeStr != "" {
		params.Set("time", timeStr)
	} else {
		params.Set("time", "now")
	}

	if dateStr != "" {
		params.Set("date", dateStr)
	}
	params.Set("format", "json")

	fullURL := fmt.Sprintf("https://api.resrobot.se/v2.1/trip?%s&accessId=%s",
		params.Encode(), cfg.ResrobotKey)
	maskedFullURL := fmt.Sprintf("https://api.resrobot.se/v2.1/trip?%s&accessId=%s", params.Encode(), maskKey(cfg.ResrobotKey))
	debugf("[UPSTREAM] journey GET %s", maskedFullURL)
	start := time.Now()
	resp, err := journeyClient.Get(fullURL)
	if err != nil {
		log.Printf("[UPSTREAM] journey ERROR from=%s to=%s after %v: %v", from, to, time.Since(start), err)
		return nil, fmt.Errorf("journey upstream %s failed: %w", maskedFullURL, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
		log.Printf("[UPSTREAM] journey HTTP %d from=%s to=%s after %v body=%q", resp.StatusCode, from, to, time.Since(start), strings.TrimSpace(string(body)))
		return nil, fmt.Errorf("ResRobot API returned status %d", resp.StatusCode)
	}

	var result interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		log.Printf("[UPSTREAM] journey decode ERROR from=%s to=%s after %v: %v", from, to, time.Since(start), err)
		return nil, err
	}
	debugf("[UPSTREAM] journey OK from=%s to=%s in %v", from, to, time.Since(start))
	return result, nil
}

func handleSituations(w http.ResponseWriter, r *http.Request) {
	debugf("[SITUATIONS] request from %s", r.RemoteAddr)
	start := time.Now()
	situations, err := fetchTrafficSituations()
	if err != nil {
		log.Printf("[SITUATIONS] ERROR err=%v duration=%v", err, time.Since(start))
		http.Error(w, fmt.Sprintf("Failed to fetch situations: %v", err), http.StatusInternalServerError)
		return
	}
	log.Printf("[SITUATIONS] OK -> %d situations in %v", len(situations), time.Since(start))
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"situations": situations,
	})
}

func fetchTrafficSituations() ([]interface{}, error) {
	// Trafikverket Situation API - Brückenöffnungen, Straßenarbeiten, Störungen
	// https://api.trafikinfo.trafikverket.se/v2/data.json
	xmlQuery := `
		<QUERYOBJECT>
			<SITUATION>
				<ID/>
				<Priority/>
				<Category>
					<Code/>
				</Category>
				<Headline>
					<Text/>
					<Language>sv</Language>
				</Headline>
				<Description>
					<Text/>
					<Language>sv</Language>
				</Description>
				<Location>
					<RoadNumber/>
					<RoadName/>
					<Direction/>
					<Coordinate System="WGS84">
						<Latitude/>
						<Longitude/>
					</Coordinate>
				</Location>
				<TimePeriod>
					<StartDateTime/>
					<EndDateTime/>
				</TimePeriod>
				<TrafficImpact>
					<Code/>
				</TrafficImpact>
			</SITUATION>
		</QUERYOBJECT>
	`

	client := apiClient
	req, err := http.NewRequest("POST", "https://api.trafikinfo.trafikverket.se/v2/data.json",
		strings.NewReader(xmlQuery))
	if err != nil {
		return nil, err
	}

	req.Header.Set("Content-Type", "application/xml")
	if cfg.TrafikverketKey != "" {
		req.Header.Set("Authorization", "Bearer "+cfg.TrafikverketKey)
	}
	debugf("[UPSTREAM] situations POST %s (key=%s)", req.URL.String(), maskKey(cfg.TrafikverketKey))
	start := time.Now()
	resp, err := client.Do(req)
	if err != nil {
		log.Printf("[UPSTREAM] situations ERROR after %v: %v", time.Since(start), err)
		return nil, fmt.Errorf("situations upstream failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
		log.Printf("[UPSTREAM] situations HTTP %d after %v body=%q", resp.StatusCode, time.Since(start), strings.TrimSpace(string(body)))
		return nil, fmt.Errorf("Trafikverket Situation API returned status %d", resp.StatusCode)
	}
	debugf("[UPSTREAM] situations HTTP %d in %v", resp.StatusCode, time.Since(start))

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		log.Printf("[UPSTREAM] situations decode ERROR after %v: %v", time.Since(start), err)
		return nil, err
	}

	// Situations extrahieren und filtern
	situations := []interface{}{}
	if response, ok := result["RESPONSE"].(map[string]interface{}); ok {
		if resultData, ok := response["RESULT"].([]interface{}); ok {
			for _, item := range resultData {
				if situationMap, ok := item.(map[string]interface{}); ok {
					situation := transformSituationData(situationMap)
					if situation != nil {
						situations = append(situations, situation)
					}
				}
			}
		}
	}
	debugf("[UPSTREAM] situations OK -> %d situations in %v", len(situations), time.Since(start))
	return situations, nil
}

func transformSituationData(data map[string]interface{}) map[string]interface{} {
	result := make(map[string]interface{})

	// ID und Priorität
	if id, ok := data["ID"]; ok {
		result["id"] = id
	}
	if priority, ok := data["Priority"]; ok {
		result["priority"] = priority
	}

	// Kategorie
	if category, ok := data["Category"].(map[string]interface{}); ok {
		if code, ok := category["Code"]; ok {
			result["categoryCode"] = code
			// Bestimme Typ basierend auf Category-Code
			codeStr := fmt.Sprintf("%v", code)
			if strings.Contains(codeStr, "BridgeOpening") || strings.Contains(codeStr, "bridge") {
				result["type"] = "bridge_opening"
			} else if strings.Contains(codeStr, "Roadwork") || strings.Contains(codeStr, "roadwork") {
				result["type"] = "roadwork"
			} else {
				result["type"] = "disturbance"
			}
		}
	}

	// Headline
	if headline, ok := data["Headline"].(map[string]interface{}); ok {
		if text, ok := headline["Text"]; ok {
			result["headline"] = text
		}
	}

	// Description
	if description, ok := data["Description"].(map[string]interface{}); ok {
		if text, ok := description["Text"]; ok {
			result["description"] = text
		}
	}

	// Location
	if location, ok := data["Location"].(map[string]interface{}); ok {
		locationResult := make(map[string]interface{})
		if roadNum, ok := location["RoadNumber"]; ok {
			locationResult["roadNumber"] = roadNum
		}
		if roadName, ok := location["RoadName"]; ok {
			locationResult["roadName"] = roadName
		}
		if direction, ok := location["Direction"]; ok {
			locationResult["direction"] = direction
		}
		if coord, ok := location["Coordinate"].(map[string]interface{}); ok {
			coordResult := make(map[string]interface{})
			if lat, ok := coord["Latitude"]; ok {
				coordResult["latitude"] = lat
			}
			if lng, ok := coord["Longitude"]; ok {
				coordResult["longitude"] = lng
			}
			locationResult["coordinate"] = coordResult
		}
		result["location"] = locationResult
	}

	// TimePeriod
	if timePeriod, ok := data["TimePeriod"].(map[string]interface{}); ok {
		timeResult := make(map[string]interface{})
		if start, ok := timePeriod["StartDateTime"]; ok {
			timeResult["start"] = start
		}
		if end, ok := timePeriod["EndDateTime"]; ok {
			timeResult["end"] = end
		}
		result["timePeriod"] = timeResult
	}

	// TrafficImpact
	if impact, ok := data["TrafficImpact"].(map[string]interface{}); ok {
		if code, ok := impact["Code"]; ok {
			result["trafficImpactCode"] = code
		}
	}

	return result
}
