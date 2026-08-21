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
	"github.com/joho/godotenv"
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
	// .env Datei laden
	if err := godotenv.Load(); err != nil {
		log.Println("Keine .env Datei gefunden, nutze System-Env-Vars")
	}

	r := mux.NewRouter()

	// API Routes
	r.HandleFunc("/api/departures", handleDepartures).Methods("GET")
	r.HandleFunc("/api/vehicles", handleVehicles).Methods("GET")
	r.HandleFunc("/api/stops/search", handleStopsSearch).Methods("GET")
	r.HandleFunc("/api/trip/{tripId}", handleTripDetails).Methods("GET")
	r.HandleFunc("/api/cameras", handleCameras).Methods("GET")
	r.HandleFunc("/api/service-alerts", handleServiceAlerts).Methods("GET")
	r.HandleFunc("/api/journey", handleJourneyPlanning).Methods("GET")
	r.HandleFunc("/api/situations", handleSituations).Methods("GET")

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
	
	// Protobuf-Daten lesen und parsen
	protobufData, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	
	feed, err := ParseFeedMessage(protobufData)
	if err != nil {
		return nil, err
	}
	
	// Alerts in JSON-Format transformieren
	alerts := []interface{}{}
	for _, entity := range feed.Entity {
		if entity.Alert != nil {
			alert := transformAlertToJSON(entity.Alert)
			if alert != nil {
				alerts = append(alerts, alert)
			}
		}
	}
	
	return alerts, nil
}

func transformAlertToJSON(alert *Alert) map[string]interface{} {
	result := make(map[string]interface{})
	
	// Header Text extrahieren
	if alert.HeaderText != nil && len(alert.HeaderText.Translation) > 0 {
		if text := alert.HeaderText.Translation[0].Text; text != nil {
			result["header"] = *text
		}
	}
	
	// Description Text extrahieren
	if alert.DescriptionText != nil && len(alert.DescriptionText.Translation) > 0 {
		if text := alert.DescriptionText.Translation[0].Text; text != nil {
			result["description"] = *text
		}
	}
	
	// URL extrahieren
	if alert.Url != nil && len(alert.Url.Translation) > 0 {
		if text := alert.Url.Translation[0].Text; text != nil {
			result["url"] = *text
		}
	}
	
	// Cause und Effect mappen
	causeMap := map[int32]string{
		0: "UNKNOWN_CAUSE",
		1: "OTHER_CAUSE",
		2: "TECHNICAL_PROBLEM",
		3: "STRIKE",
		4: "DEMONSTRATION",
		5: "BAD_WEATHER",
		6: "HOLIDAY",
		7: "VANDALISM",
		8: "CONSTRUCTION",
		9: "POLICE_ACTIVITY",
		10: "MEDICAL_EMERGENCY",
	}
	
	effectMap := map[int32]string{
		0: "NO_SERVICE",
		1: "REDUCED_SERVICE",
		2: "SIGNIFICANT_DELAYS",
		3: "DETOUR",
		4: "ADDITIONAL_SERVICE",
		5: "MODIFIED_SERVICE",
		6: "OTHER_EFFECT",
		7: "UNKNOWN_EFFECT",
		8: "STOP_MOVED",
		9: "NO_EFFECT",
	}
	
	if alert.Cause != nil {
		result["cause"] = causeMap[*alert.Cause]
		result["causeCode"] = *alert.Cause
	}
	
	if alert.Effect != nil {
		result["effect"] = effectMap[*alert.Effect]
		result["effectCode"] = *alert.Effect
	}
	
	// Betroffene Entities extrahieren
	informedEntities := []map[string]interface{}{}
	for _, entity := range alert.InformedEntity {
		entityMap := make(map[string]interface{})
		if entity.AgencyId != nil {
			entityMap["agencyId"] = *entity.AgencyId
		}
		if entity.RouteId != nil {
			entityMap["routeId"] = *entity.RouteId
		}
		if entity.RouteType != nil {
			entityMap["routeType"] = *entity.RouteType
		}
		if entity.StopId != nil {
			entityMap["stopId"] = *entity.StopId
		}
		if entity.TripId != nil {
			entityMap["tripId"] = *entity.TripId
		}
		if entity.DirectionId != nil {
			entityMap["directionId"] = *entity.DirectionId
		}
		informedEntities = append(informedEntities, entityMap)
	}
	result["informedEntities"] = informedEntities
	
	// Active Period extrahieren
	activePeriods := []map[string]interface{}{}
	for _, period := range alert.ActivePeriod {
		periodMap := make(map[string]interface{})
		if period.Start != nil {
			periodMap["start"] = *period.Start
			periodMap["startTime"] = time.Unix(int64(*period.Start), 0).Format(time.RFC3339)
		}
		if period.End != nil {
			periodMap["end"] = *period.End
			periodMap["endTime"] = time.Unix(int64(*period.End), 0).Format(time.RFC3339)
		}
		activePeriods = append(activePeriods, periodMap)
	}
	result["activePeriods"] = activePeriods
	
	return result
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

func handleJourneyPlanning(w http.ResponseWriter, r *http.Request) {
        from := r.URL.Query().Get("from")
        to := r.URL.Query().Get("to")
        timeStr := r.URL.Query().Get("time")
        dateStr := r.URL.Query().Get("date")
        
        if from == "" || to == "" {
                http.Error(w, "from and to parameters required", http.StatusBadRequest)
                return
        }
        
        journey, err := fetchJourneyFromResRobot(from, to, timeStr, dateStr)
        if err != nil {
                http.Error(w, fmt.Sprintf("Failed to fetch journey: %v", err), http.StatusInternalServerError)
                return
        }
        
        w.Header().Set("Content-Type", "application/json")
        json.NewEncoder(w).Encode(journey)
}

func fetchJourneyFromResRobot(from, to, timeStr, dateStr string) (interface{}, error) {
        // ResRobot v2.1 Journey Planning API
        // https://api.trafiklab.se/v2.1/TravelPlanner/SearchTrip
        
        baseURL := "https://api.trafiklab.se/v2.1/TravelPlanner/SearchTrip"
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
        
        fullURL := fmt.Sprintf("%s?%s&apikey=%s", baseURL, params.Encode(), resrobotKey)
        
        client := &http.Client{Timeout: 30 * time.Second}
        resp, err := client.Get(fullURL)
        if err != nil {
                return nil, err
        }
        defer resp.Body.Close()
        
        if resp.StatusCode != http.StatusOK {
                return nil, fmt.Errorf("ResRobot API returned status %d", resp.StatusCode)
        }
        
        var result interface{}
        if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
                return nil, err
        }
        
	return result, nil
}

func handleSituations(w http.ResponseWriter, r *http.Request) {
	situations, err := fetchTrafficSituations()
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to fetch situations: %v", err), http.StatusInternalServerError)
		return
	}

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
	
	client := &http.Client{Timeout: 15 * time.Second}
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
		return nil, fmt.Errorf("Trafikverket Situation API returned status %d", resp.StatusCode)
	}
	
	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
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
