package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
)

// Konfiguration
var (
	trafiklabKey     = getEnv("TRAFIKLAB_API_KEY", "")
	gtfsRtKey        = getEnv("TRAFIKLAB_GTFS_RT_KEY", "")
	gtfsStaticKey    = getEnv("TRAFIKLAB_GTFS_STATIC_KEY", "")
	stopsKey         = getEnv("TRAFIKLAB_STOPS_KEY", "")
	resrobotKey      = getEnv("TRAFIKLAB_RESROBOT_KEY", "")
	trafikverketKey  = getEnv("TRAFIKVERKET_API_KEY", "")
	serverPort       = getEnv("SERVER_PORT", "8080")
)

// Telemetrie-Metriken
type Telemetry struct {
	mu                     sync.RWMutex
	TotalClientRequests    int64   `json:"totalClientRequests"`
	UpstreamCallsMade      int64   `json:"upstreamCallsMade"`
	CollapsedRequests      int64   `json:"collapsedRequests"`
	NetworkSavingsPercent  float64 `json:"networkSavingsPercent"`
	ProtobufBytesProcessed int64   `json:"protobufBytesProcessed"`
	JSONStreamBytesEmitted int64   `json:"jsonStreamBytesEmitted"`
	ActiveVehiclesInSweden int     `json:"activeVehiclesInSweden"`
	ActiveVehiclesInViewport int   `json:"activeVehiclesInViewport"`
}

var telemetry = &Telemetry{}

// Request-Collapsing Cache
type cacheEntry struct {
	data      interface{}
	expiresAt time.Time
}

var (
	departuresCache = make(map[string]*cacheEntry)
	vehiclesCache   *cacheEntry
	cacheMu         sync.RWMutex
	cacheTTL        = 15 * time.Second
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
	Vehicles   []interface{} `json:"vehicles"`
	Telemetry  Telemetry     `json:"telemetry"`
}

func main() {
	r := mux.NewRouter()

	// API Routes
	r.HandleFunc("/api/departures", handleDepartures).Methods("GET")
	r.HandleFunc("/api/vehicles", handleVehicles).Methods("GET")
	r.HandleFunc("/api/stops/search", handleStopsSearch).Methods("GET")
	r.HandleFunc("/api/trip/{tripId}", handleTripDetails).Methods("GET")
	r.HandleFunc("/api/cameras", handleCameras).Methods("GET")
	r.HandleFunc("/api/service-alerts", handleServiceAlerts).Methods("GET")

	// WebSocket Route
	r.HandleFunc("/ws", handleWebSocket)

	log.Printf("🚀 Server startet auf Port %s", serverPort)
	log.Fatal(http.ListenAndServe(":"+serverPort, r))
}

func handleDepartures(w http.ResponseWriter, r *http.Request) {
	telemetry.mu.Lock()
	telemetry.TotalClientRequests++
	telemetry.mu.Unlock()

	stopID := r.URL.Query().Get("stopId")
	if stopID == "" {
		http.Error(w, "stopId parameter required", http.StatusBadRequest)
		return
	}

	// Request-Collapsing: Prüfen ob Cache noch gültig
	cacheMu.RLock()
	if entry, ok := departuresCache[stopID]; ok && time.Now().Before(entry.expiresAt) {
		cacheMu.RUnlock()
		telemetry.mu.Lock()
		telemetry.CollapsedRequests++
		telemetry.mu.Unlock()
		
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(DepartureResponse{
			Departures: entry.data.([]interface{}),
			Telemetry:  getTelemetrySnapshot(),
		})
		return
	}
	cacheMu.RUnlock()

	// Echter API-Aufruf zu Trafiklab
	departures, err := fetchDeparturesFromTrafiklab(stopID)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to fetch departures: %v", err), http.StatusInternalServerError)
		return
	}

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
	json.NewEncoder(w).Encode(DepartureResponse{
		Departures: departures,
		Telemetry:  getTelemetrySnapshot(),
	})
}

func handleVehicles(w http.ResponseWriter, r *http.Request) {
	telemetry.mu.Lock()
	telemetry.TotalClientRequests++
	telemetry.mu.Unlock()

	// Request-Collapsing für Fahrzeuge
	cacheMu.RLock()
	if vehiclesCache != nil && time.Now().Before(vehiclesCache.expiresAt) {
		cacheMu.RUnlock()
		telemetry.mu.Lock()
		telemetry.CollapsedRequests++
		telemetry.mu.Unlock()

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(VehiclesResponse{
			Vehicles:  vehiclesCache.data.([]interface{}),
			Telemetry: getTelemetrySnapshot(),
		})
		return
	}
	cacheMu.RUnlock()

	// GTFS-RT Fahrzeugpositionen abrufen
	vehicles, err := fetchVehiclesFromGTFSRT()
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to fetch vehicles: %v", err), http.StatusInternalServerError)
		return
	}

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
	json.NewEncoder(w).Encode(VehiclesResponse{
		Vehicles:  vehicles,
		Telemetry: getTelemetrySnapshot(),
	})
}

func handleStopsSearch(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query().Get("q")
	if query == "" {
		http.Error(w, "q parameter required", http.StatusBadRequest)
		return
	}

	stops, err := searchStops(query)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to search stops: %v", err), http.StatusInternalServerError)
		return
	}

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
		http.Error(w, "tripId required", http.StatusBadRequest)
		return
	}

	tripDetails, err := fetchTripDetails(tripID, date)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to fetch trip details: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(tripDetails)
}

func handleCameras(w http.ResponseWriter, r *http.Request) {
	cameras, err := fetchTrafficCameras()
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to fetch cameras: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"cameras": cameras,
	})
}

func handleServiceAlerts(w http.ResponseWriter, r *http.Request) {
	alerts, err := fetchServiceAlerts()
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to fetch service alerts: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"alerts": alerts,
	})
}

func handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("WebSocket Upgrade Error:", err)
		return
	}
	defer conn.Close()

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
					continue
				}

				// Bounding Box Filterung
				if minLat != 0 || minLng != 0 || maxLat != 0 || maxLng != 0 {
					filtered := filterVehiclesByBBox(vehicles, minLat, minLng, maxLat, maxLng)
					vehicles = filtered
					telemetry.mu.Lock()
					telemetry.ActiveVehiclesInViewport = len(vehicles)
					telemetry.mu.Unlock()
				}
			}

			message := map[string]interface{}{
				"type":    "vehicles",
				"items":   vehicles,
				"timestamp": time.Now().Unix(),
			}

			if err := conn.WriteJSON(message); err != nil {
				log.Println("WebSocket Write Error:", err)
				return
			}
		}
	}
}

// Helper-Funktionen mit echten API-Calls

func fetchDeparturesFromTrafiklab(stopID string) ([]interface{}, error) {
	// Trafiklab Realtime API v2 - DepartureBoard
	// https://realtime-api.trafiklab.se/v2/StopPoints/{stopId}/DepartureBoard
	url := fmt.Sprintf("https://realtime-api.trafiklab.se/v2/StopPoints/%s/DepartureBoard?apikey=%s", 
		stopID, trafiklabKey)
	
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("API returned status %d", resp.StatusCode)
	}
	
	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}
	
	// Extrahiere Departure-Array aus der Response
	if departureBoard, ok := result["DepartureBoard"].(map[string]interface{}); ok {
		if departures, ok := departureBoard["timetabledDepartureWithCalls"].([]interface{}); ok {
			return departures, nil
		}
	}
	
	return []interface{}{}, nil
}

func fetchVehiclesFromGTFSRT() ([]interface{}, error) {
	// GTFS-RT Vehicle Positions von Trafiklab
	// https://realtime-api.trafiklab.se/v1/gtfs-rt/vehicle-positions
	url := fmt.Sprintf("https://realtime-api.trafiklab.se/v1/gtfs-rt/vehicle-positions?apikey=%s", gtfsRtKey)
	
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("API returned status %d", resp.StatusCode)
	}
	
	// Protobuf-Daten lesen (müssten mit protobuf-Bibliothek geparst werden)
	// Für jetzt als Platzhalter - in Production muss hier das GTFS-RT Protobuf geparst werden
	protobufData, _ := io.ReadAll(resp.Body)
	telemetry.mu.Lock()
	telemetry.ProtobufBytesProcessed += int64(len(protobufData))
	telemetry.mu.Unlock()
	
	// TODO: Echtes GTFS-RT Protobuf Parsing implementieren
	// Siehe: https://github.com/matsu/gtfs-realtime-bindings/golang
	return []interface{}{}, nil
}

func searchStops(query string) ([]interface{}, error) {
	// Trafiklab Stops API mit FTS-Suche
	url := fmt.Sprintf("https://api.trafiklab.se/v2/StopPoints?q=%s&apikey=%s", 
		url.QueryEscape(query), stopsKey)
	
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("API returned status %d", resp.StatusCode)
	}
	
	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}
	
	if stopPoints, ok := result["StopPoints"].(map[string]interface{}); ok {
		if stopLocationGroup, ok := stopPoints["StopLocationGroup"].([]interface{}); ok {
			return stopLocationGroup, nil
		}
	}
	
	return []interface{}{}, nil
}

func fetchTripDetails(tripID, date string) (interface{}, error) {
	// Trip Details API - echte Zugkomposition und Verspätungen
	// https://realtime-api.trafiklab.se/v1/trips/{tripId}/{date}
	if date == "" {
		date = time.Now().Format("2006-01-02")
	}
	
	url := fmt.Sprintf("https://realtime-api.trafiklab.se/v1/trips/%s/%s?apikey=%s", 
		tripID, date, resrobotKey)
	
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("API returned status %d", resp.StatusCode)
	}
	
	var result interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}
	
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
	
	client := &http.Client{Timeout: 10 * time.Second}
	req, err := http.NewRequest("POST", "https://api.trafikinfo.trafikverket.se/v2/data.json", 
		strings.NewReader(xmlQuery))
	if err != nil {
		return nil, err
	}
	
	req.Header.Set("Content-Type", "application/xml")
	if trafikverketKey != "" {
		req.Header.Set("Authorization", "Bearer "+trafikverketKey)
	}
	
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("Trafikverket API returned status %d", resp.StatusCode)
	}
	
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

func fetchServiceAlerts() ([]interface{}, error) {
	// GTFS-RT ServiceAlerts parsen
	// https://realtime-api.trafiklab.se/v1/gtfs-rt/alerts
	url := fmt.Sprintf("https://realtime-api.trafiklab.se/v1/gtfs-rt/alerts?apikey=%s", gtfsRtKey)
	
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("API returned status %d", resp.StatusCode)
	}
	
	// Protobuf-Daten lesen (müssten mit protobuf-Bibliothek geparst werden)
	protobufData, _ := io.ReadAll(resp.Body)
	
	// TODO: Echtes GTFS-RT ServiceAlerts Protobuf Parsing implementieren
	_ = protobufData
	
	return []interface{}{}, nil
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
	return *telemetry
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
