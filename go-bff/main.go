package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/joho/godotenv"
)

// Trafiklab API configuration
const (
	TrafiklabBaseURL = "https://realtime-api.trafiklab.se/v1"
)

// Response structures
type DeparturesResponse struct {
	Timestamp string `json:"timestamp"`
	Query     Query  `json:"query"`
	Stops     []Stop `json:"stops"`
	Departures []Departure `json:"departures"`
}

type ArrivalsResponse struct {
	Timestamp string `json:"timestamp"`
	Query     Query  `json:"query"`
	Stops     []Stop `json:"stops"`
	Arrivals  []Departure `json:"arrivals"`
}

type Query struct {
	QueryTime string `json:"queryTime"`
	Query     string `json:"query"`
}

type Stop struct {
	ID            string   `json:"id"`
	Name          string   `json:"name"`
	Lat           float64  `json:"lat"`
	Lon           float64  `json:"lon"`
	TransportModes []string `json:"transport_modes"`
	Alerts        []interface{} `json:"alerts"`
}

type Departure struct {
	Scheduled         string    `json:"scheduled"`
	Realtime          string    `json:"realtime"`
	Delay             int       `json:"delay"`
	Canceled          bool      `json:"canceled"`
	Route             Route     `json:"route"`
	Trip              Trip      `json:"trip"`
	Agency            Agency    `json:"agency"`
	Stop              Stop      `json:"stop"`
	ScheduledPlatform *Platform `json:"scheduled_platform"`
	RealtimePlatform  *Platform `json:"realtime_platform"`
	Alerts            []interface{} `json:"alerts"`
	IsRealtime        bool      `json:"is_realtime"`
}

type Route struct {
	Name            string `json:"name"`
	Designation     string `json:"designation"`
	TransportModeCode int    `json:"transport_mode_code"`
	TransportMode   string `json:"transport_mode"`
	Direction       string `json:"direction"`
	Origin          StopInfo `json:"origin"`
	Destination     StopInfo `json:"destination"`
}

type StopInfo struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

type Trip struct {
	TripID        string `json:"trip_id"`
	StartDate     string `json:"start_date"`
	TechnicalNumber int    `json:"technical_number"`
}

type Agency struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	Operator string `json:"operator"`
}

type Platform struct {
	ID          string `json:"id"`
	Designation string `json:"designation"`
}

// BFF API Responses
type BFFResponse struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	Error   string      `json:"error,omitempty"`
}

type DepartureItem struct {
	Line            string    `json:"line"`
	Destination     string    `json:"destination"`
	Time            string    `json:"time"`
	RealtimeTime    string    `json:"realtime_time,omitempty"`
	DelaySeconds    int       `json:"delay_seconds"`
	Platform        string    `json:"platform,omitempty"`
	Canceled        bool      `json:"canceled"`
	TransportMode   string    `json:"transport_mode"`
	Agency          string    `json:"agency"`
	Latitude        float64   `json:"latitude"`
	Longitude       float64   `json:"longitude"`
	StopName        string    `json:"stop_name"`
	StopID          string    `json:"stop_id"`
}

func main() {
	// Load environment variables
	if err := godotenv.Load(); err != nil {
		log.Println("No .env file found, using system environment variables")
	}

	apiKey := os.Getenv("TRAFIKLAB_API_KEY")
	if apiKey == "" {
		log.Fatal("TRAFIKLAB_API_KEY not found in environment")
	}

	// Set up HTTP routes
	http.HandleFunc("/api/departures", handleDepartures(apiKey))
	http.HandleFunc("/api/arrivals", handleArrivals(apiKey))
	http.HandleFunc("/api/stops/search", handleStopSearch(apiKey))
	http.HandleFunc("/health", handleHealth)

	fmt.Println("🚀 BFF Server starting on :8080")
	fmt.Println("Endpoints:")
	fmt.Println("  - GET /api/departures?stopId=740000002")
	fmt.Println("  - GET /api/arrivals?stopId=740000002")
	fmt.Println("  - GET /api/stops/search?query=stockholm")
	fmt.Println("  - GET /health")

	if err := http.ListenAndServe(":8080", nil); err != nil {
		log.Fatal(err)
	}
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Access-Control-Allow-Origin", "*")
	json.NewEncoder(w).Encode(map[string]string{
		"status": "healthy",
		"time":   time.Now().Format(time.RFC3339),
	})
}

func handleDepartures(apiKey string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Access-Control-Allow-Origin", "*")

		stopID := r.URL.Query().Get("stopId")
		if stopID == "" {
			sendError(w, "Missing required parameter: stopId", http.StatusBadRequest)
			return
		}

		url := fmt.Sprintf("%s/departures/%s?key=%s", TrafiklabBaseURL, stopID, apiKey)
		
		resp, err := http.Get(url)
		if err != nil {
			sendError(w, fmt.Sprintf("Failed to fetch from Trafiklab: %v", err), http.StatusInternalServerError)
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			sendError(w, fmt.Sprintf("Trafiklab API returned status: %d", resp.StatusCode), resp.StatusCode)
			return
		}

		var trafikalbResp DeparturesResponse
		if err := json.NewDecoder(resp.Body).Decode(&trafikalbResp); err != nil {
			sendError(w, fmt.Sprintf("Failed to decode response: %v", err), http.StatusInternalServerError)
			return
		}

		// Transform to BFF format
		departures := transformDepartures(trafikalbResp)
		
		sendSuccess(w, departures)
	}
}

func handleArrivals(apiKey string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Access-Control-Allow-Origin", "*")

		stopID := r.URL.Query().Get("stopId")
		if stopID == "" {
			sendError(w, "Missing required parameter: stopId", http.StatusBadRequest)
			return
		}

		url := fmt.Sprintf("%s/arrivals/%s?key=%s", TrafiklabBaseURL, stopID, apiKey)
		
		resp, err := http.Get(url)
		if err != nil {
			sendError(w, fmt.Sprintf("Failed to fetch from Trafiklab: %v", err), http.StatusInternalServerError)
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			sendError(w, fmt.Sprintf("Trafiklab API returned status: %d", resp.StatusCode), resp.StatusCode)
			return
		}

		var trafikalbResp ArrivalsResponse
		if err := json.NewDecoder(resp.Body).Decode(&trafikalbResp); err != nil {
			sendError(w, fmt.Sprintf("Failed to decode response: %v", err), http.StatusInternalServerError)
			return
		}

		// Transform to BFF format
		arrivals := transformArrivals(trafikalbResp)
		
		sendSuccess(w, arrivals)
	}
}

func handleStopSearch(apiKey string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Access-Control-Allow-Origin", "*")

		query := r.URL.Query().Get("query")
		if query == "" {
			sendError(w, "Missing required parameter: query", http.StatusBadRequest)
			return
		}

		url := fmt.Sprintf("%s/stops/name/%s?key=%s", TrafiklabBaseURL, query, apiKey)
		
		resp, err := http.Get(url)
		if err != nil {
			sendError(w, fmt.Sprintf("Failed to fetch from Trafiklab: %v", err), http.StatusInternalServerError)
			return
		}
		defer resp.Body.Close()

		if resp.StatusCode != http.StatusOK {
			sendError(w, fmt.Sprintf("Trafiklab API returned status: %d", resp.StatusCode), resp.StatusCode)
			return
		}

		var result interface{}
		if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
			sendError(w, fmt.Sprintf("Failed to decode response: %v", err), http.StatusInternalServerError)
			return
		}

		sendSuccess(w, result)
	}
}

func transformDepartures(resp DeparturesResponse) []DepartureItem {
	items := make([]DepartureItem, 0, len(resp.Departures))
	
	for _, dep := range resp.Departures {
		platform := ""
		if dep.RealtimePlatform != nil {
			platform = dep.RealtimePlatform.Designation
		} else if dep.ScheduledPlatform != nil {
			platform = dep.ScheduledPlatform.Designation
		}

		realtimeTime := dep.Realtime
		if !dep.IsRealtime {
			realtimeTime = ""
		}

		items = append(items, DepartureItem{
			Line:          dep.Route.Designation,
			Destination:   dep.Route.Direction,
			Time:          dep.Scheduled,
			RealtimeTime:  realtimeTime,
			DelaySeconds:  dep.Delay,
			Platform:      platform,
			Canceled:      dep.Canceled,
			TransportMode: dep.Route.TransportMode,
			Agency:        dep.Agency.Name,
			Latitude:      dep.Stop.Lat,
			Longitude:     dep.Stop.Lon,
			StopName:      dep.Stop.Name,
			StopID:        dep.Stop.ID,
		})
	}

	return items
}

func transformArrivals(resp ArrivalsResponse) []DepartureItem {
	items := make([]DepartureItem, 0, len(resp.Arrivals))
	
	for _, arr := range resp.Arrivals {
		platform := ""
		if arr.RealtimePlatform != nil {
			platform = arr.RealtimePlatform.Designation
		} else if arr.ScheduledPlatform != nil {
			platform = arr.ScheduledPlatform.Designation
		}

		realtimeTime := arr.Realtime
		if !arr.IsRealtime {
			realtimeTime = ""
		}

		items = append(items, DepartureItem{
			Line:          arr.Route.Designation,
			Destination:   arr.Route.Direction,
			Time:          arr.Scheduled,
			RealtimeTime:  realtimeTime,
			DelaySeconds:  arr.Delay,
			Platform:      platform,
			Canceled:      arr.Canceled,
			TransportMode: arr.Route.TransportMode,
			Agency:        arr.Agency.Name,
			Latitude:      arr.Stop.Lat,
			Longitude:     arr.Stop.Lon,
			StopName:      arr.Stop.Name,
			StopID:        arr.Stop.ID,
		})
	}

	return items
}

func sendSuccess(w http.ResponseWriter, data interface{}) {
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(BFFResponse{
		Success: true,
		Data:    data,
	})
}

func sendError(w http.ResponseWriter, message string, statusCode int) {
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(BFFResponse{
		Success: false,
		Error:   message,
	})
}
