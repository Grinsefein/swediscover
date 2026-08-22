package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/mux"
)

// GET /api/trip-details/{vehicleId}
// Liefert für ein selektiertes Fahrzeug: route, stops (mit Namen/Coords + Echtzeit-Delays), shape polyline, vehicle snapshot.
func handleTripDetailsByVehicle(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	vehicleID := vars["vehicleId"]
	if vehicleID == "" {
		http.Error(w, "vehicleId required", http.StatusBadRequest)
		return
	}
	// vehicleId kommt URL-encoded
	vehicleID, _ = decodePathParam(vehicleID)

	// GTFS readiness check – falls noch im Hintergrund am Laden
	if err := ensureGtfsReady(); err != nil {
		log.Printf("[TRIP-DETAILS] GTFS not ready for vehicle %s: %v", vehicleID, err)
		// Degraded: liefere trotzdem RT-Daten falls möglich, ohne static enrichment
	}

	// 1. Vehicle aus Cache finden (muss nicht GTFS-ready sein)
	vehicleMap, tripIDTagged, ok := findVehicleByID(vehicleID)
	if !ok {
		// Cache könnte leer sein – einmal frisch fetchen (mit TripUpdates-Delay-Join)
		vehicles, err := fetchVehiclesFromGTFSRT()
		if err == nil {
			// in Cache zurücklegen für nachfolgende requests
			cacheMu.Lock()
			vehiclesCache = &cacheEntry{data: vehicles, expiresAt: timeNow().Add(cacheTTL)}
			cacheMu.Unlock()
			vehicleMap, tripIDTagged, ok = findVehicleByIDFromSlice(vehicles, vehicleID)
		}
		if !ok {
			http.Error(w, fmt.Sprintf("vehicle %s not found", vehicleID), http.StatusNotFound)
			return
		}
	}

	rawTripID := stripOperatorTag(tripIDTagged)
	debugf("[TRIP-DETAILS] vehicle=%s trip=%s rawTrip=%s", vehicleID, tripIDTagged, rawTripID)

	// 2. Statische Trip/Route Infos
	var routeInfo map[string]interface{}
	var tripHeadsign string
	var shapeID string
	var routeID string
	if gtTrip, ok := tripIndex[rawTripID]; ok {
		routeID = gtTrip.RouteID
		shapeID = gtTrip.ShapeID
		tripHeadsign = gtTrip.Headsign
		if gtRoute, ok := routeIndex[routeID]; ok {
			routeInfo = map[string]interface{}{
				"routeId":   gtRoute.ID,
				"shortName": gtRoute.ShortName,
				"longName":  gtRoute.LongName,
				"type":      gtRoute.Type,
			}
		} else {
			routeInfo = map[string]interface{}{"routeId": routeID}
		}
	} else {
		// Trip nicht in static DB – z.B. Extra-Trip. Fallback: nutze vehicle routeId
		if rid, ok := vehicleMap["routeId"].(string); ok && rid != "" {
			routeID = rid
			if gtRoute, ok := routeIndex[rid]; ok {
				routeInfo = map[string]interface{}{"routeId": rid, "shortName": gtRoute.ShortName, "longName": gtRoute.LongName, "type": gtRoute.Type}
			} else {
				routeInfo = map[string]interface{}{"routeId": rid}
			}
		}
		debugf("[TRIP-DETAILS] trip %s nicht in static DB – fallback route %s", rawTripID, routeID)
	}

	// 3. + 4. parallel: Stop-Liste + Shape (beide scannen große CSVs)
	var stops []interface{}
	var shape [][]float64
	var wg sync.WaitGroup
	var stopsErr, shapeErr error
	wg.Add(2)
	go func() {
		defer wg.Done()
		s, err := buildEnrichedStops(rawTripID, tripIDTagged)
		if err != nil {
			stopsErr = err
			log.Printf("[TRIP-DETAILS] stop_times für trip %s: %v", rawTripID, err)
			stops = []interface{}{}
			return
		}
		stops = s
	}()
	go func() {
		defer wg.Done()
		if shapeID != "" {
			poly, err := getShapePolyline(shapeID)
			if err != nil {
				shapeErr = err
				debugf("[TRIP-DETAILS] shape %s: %v", shapeID, err)
				return
			}
			shape = poly
		}
	}()
	wg.Wait()
	if shape == nil && len(stops) > 1 && shapeErr == nil {
		// Fallback wenn kein shape: Linie durch Haltestellen
		for _, s := range stops {
			if m, ok := s.(map[string]interface{}); ok {
				if lat, ok1 := m["lat"].(float64); ok1 {
					if lon, ok2 := m["lng"].(float64); ok2 && lat != 0 {
						shape = append(shape, []float64{lat, lon})
					}
				}
			}
		}
	}
	_ = stopsErr
	_ = shapeErr

	// 5. Aktuelle Position/Status für Progress-Markierung
	currentStopSeq := 0
	if v, ok := vehicleMap["currentStopSequence"]; ok {
		switch val := v.(type) {
		case int:
			currentStopSeq = val
		case float64:
			currentStopSeq = int(val)
		}
	}
	// Fallback: current_stop_sequence ist nicht im Vehicle JSON (transformVehicleToJSON setzt es nicht)
	// -> versuche aus VehiclePosition direkt (wir haben es als currentStatus string, nicht seq). Lassen wir 0.

	resp := map[string]interface{}{
		"vehicleId":           vehicleID,
		"tripId":              tripIDTagged,
		"rawTripId":           rawTripID,
		"vehicle":             vehicleMap,
		"route":               routeInfo,
		"tripHeadsign":        tripHeadsign,
		"stops":               stops,
		"shape":               shape,
		"currentStopSequence": currentStopSeq,
		"currentStatus":       vehicleMap["currentStatus"],
		"nextStopId":          vehicleMap["nextStopName"],
		"gtfsReady":           isGtfsReady(),
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(resp); err != nil {
		log.Printf("[TRIP-DETAILS] encode error: %v", err)
	}
}

// findVehicleByID sucht im vehiclesCache nach vehicleId.
func findVehicleByID(vehicleID string) (map[string]interface{}, string, bool) {
	cacheMu.RLock()
	defer cacheMu.RUnlock()
	if vehiclesCache == nil {
		return nil, "", false
	}
	slice, ok := vehiclesCache.data.([]interface{})
	if !ok {
		return nil, "", false
	}
	return findVehicleByIDFromSlice(slice, vehicleID)
}

func findVehicleByIDFromSlice(slice []interface{}, vehicleID string) (map[string]interface{}, string, bool) {
	for _, v := range slice {
		if m, ok := v.(map[string]interface{}); ok {
			if m["vehicleId"] == vehicleID {
				tripID, _ := m["tripId"].(string)
				return m, tripID, true
			}
		}
	}
	return nil, "", false
}

// buildEnrichedStops kombiniert static stop_times mit Stopp-Namen/Coords und RT-Delays.
func buildEnrichedStops(rawTripID, taggedTripID string) ([]interface{}, error) {
	// Statische Haltestellenfolge
	seqStops, err := getStopTimesForTrip(rawTripID)
	if err != nil {
		return nil, err
	}
	if len(seqStops) == 0 {
		return nil, fmt.Errorf("keine stop_times für trip %s", rawTripID)
	}

	// RT Delays pro stopId/stopSequence aus TripUpdates Cache
	delayByStop := map[string]map[string]int{} // stopId -> {arrival, departure}
	delayBySeq := map[int]map[string]int{}
	if tripUpdatesCache != nil {
		cacheMu.RLock()
		slice, _ := tripUpdatesCache.data.([]interface{})
		cacheMu.RUnlock()
		// Wir suchen das TripUpdate für diesen Trip (tagged oder raw)
		for _, tuRaw := range slice {
			if m, ok := tuRaw.(map[string]interface{}); ok {
				tid, _ := m["tripId"].(string)
				if tid != taggedTripID && tid != rawTripID && !strings.HasSuffix(tid, ":"+rawTripID) {
					continue
				}
				if arr, ok := m["stopTimeUpdates"].([]interface{}); ok {
					for _, stuRaw := range arr {
						if stu, ok := stuRaw.(map[string]interface{}); ok {
							sid, _ := stu["stopId"].(string)
							seqF, _ := stu["stopSequence"].(float64)
							seq := int(seqF)
							if seq == 0 {
								if s, ok := stu["stopSequence"].(int); ok {
									seq = s
								}
							}
							entry := map[string]int{}
							if v, ok := stu["arrivalDelaySeconds"].(float64); ok {
								entry["arrival"] = int(v)
							} else if v, ok := stu["arrivalDelaySeconds"].(int); ok {
								entry["arrival"] = v
							} else if v, ok := stu["arrivalDelaySeconds"].(int32); ok {
								entry["arrival"] = int(v)
							}
							if v, ok := stu["departureDelaySeconds"].(float64); ok {
								entry["departure"] = int(v)
							} else if v, ok := stu["departureDelaySeconds"].(int); ok {
								entry["departure"] = v
							}
							if sid != "" {
								delayByStop[sid] = entry
							}
							if seq != 0 {
								delayBySeq[seq] = entry
							}
						}
					}
				}
			}
		}
	}

	// Kombinieren
	out := make([]interface{}, 0, len(seqStops))
	for _, ts := range seqStops {
		stopName := ts.StopID
		lat, lon := 0.0, 0.0
		if gs, ok := stopIndex[ts.StopID]; ok {
			stopName = gs.Name
			lat = gs.Lat
			lon = gs.Lon
		}
		arrDelay, depDelay := 0, 0
		if d, ok := delayByStop[ts.StopID]; ok {
			arrDelay = d["arrival"]
			depDelay = d["departure"]
		} else if d, ok := delayBySeq[ts.StopSequence]; ok {
			arrDelay = d["arrival"]
			depDelay = d["departure"]
		}

		out = append(out, map[string]interface{}{
			"stopId":                ts.StopID,
			"name":                  stopName,
			"lat":                   lat,
			"lng":                   lon,
			"stopSequence":          ts.StopSequence,
			"arrivalTime":           ts.ArrivalTime,
			"departureTime":         ts.DepartureTime,
			"arrivalDelaySeconds":   arrDelay,
			"departureDelaySeconds": depDelay,
		})
	}
	return out, nil
}

func decodePathParam(s string) (string, error) {
	// mux decodiert bereits; nur %3A für ":" behandeln
	return strings.ReplaceAll(s, "%3A", ":"), nil
}

// timeNow indirektion für Tests
var timeNow = func() time.Time { return time.Now() }
