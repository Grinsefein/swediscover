package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"sync"
	"time"

	"github.com/joho/godotenv"
)

// Config holds API keys and server configuration
type Config struct {
	ResRobotAPIKey       string
	GTFSRegionalRTKey    string
	GTFSSweden3RTKey     string
	OxifyRealtimeKey     string
	SIRIKey              string
	TrafiklabRealtimeKey string
	ServerHost           string
	ServerPort           string
}

// Departure represents a transit departure
type Departure struct {
	StopID        string `json:"stopId"`
	StopName      string `json:"stopName"`
	LineName      string `json:"lineName"`
	Destination   string `json:"destination"`
	ExpectedTime  string `json:"expectedTime"`
	EstimatedTime string `json:"estimatedTime,omitempty"`
	Direction     int    `json:"direction"`
}

// VehiclePosition represents a real-time vehicle position
type VehiclePosition struct {
	VehicleID    string  `json:"vehicleId"`
	Latitude     float64 `json:"latitude"`
	Longitude    float64 `json:"longitude"`
	Bearing      float64 `json:"bearing"`
	Speed        float64 `json:"speed"`
	RouteID      string  `json:"routeId"`
	TripID       string  `json:"tripId"`
	LastUpdated  int64   `json:"lastUpdated"`
	Occupancy    string  `json:"occupancy,omitempty"`
}

// VehiclesResponse is the API response for vehicles
type VehiclesResponse struct {
	Vehicles                []VehiclePosition `json:"vehicles"`
	TotalClientRequests     int               `json:"totalClientRequests"`
	UpstreamCallsMade       int               `json:"upstreamCallsMade"`
	CollapsedRequests       int               `json:"collapsedRequests"`
	NetworkSavingsPercent   float64           `json:"networkSavingsPercent"`
	ProtobufBytesProcessed  int               `json:"protobufBytesProcessed"`
	JSONStreamBytesEmitted  int               `json:"jsonStreamBytesProcessed"`
	ActiveVehiclesInSweden  int               `json:"activeVehiclesInSweden"`
	ActiveVehiclesInViewport int              `json:"activeVehiclesInViewport"`
}

// BFFServer handles HTTP requests and manages upstream API calls
type BFFServer struct {
	config              *Config
	client              *http.Client
	vehicleCache        []VehiclePosition
	vehicleCacheTime    time.Time
	vehicleCacheMu      sync.RWMutex
	totalRequests       int
	upstreamCalls       int
	collapsedRequests   int
	protobufBytes       int
	jsonBytes           int
	activeVehiclesSweden int
}

func NewBFFServer(config *Config) *BFFServer {
	return &BFFServer{
		config: config,
		client: &http.Client{
			Timeout: 10 * time.Second,
		},
		vehicleCache:     []VehiclePosition{},
		vehicleCacheTime: time.Time{},
	}
}

func loadConfig() (*Config, error) {
	// Try to load .env file
	if _, err := os.Stat(".env"); err == nil {
		if err := godotenv.Load(); err != nil {
			log.Printf("Warning: Could not load .env file: %v", err)
		}
	} else if _, err := os.Stat("../.env"); err == nil {
		if err := godotenv.Load("../.env"); err != nil {
			log.Printf("Warning: Could not load ../.env file: %v", err)
		}
	}

	config := &Config{
		ResRobotAPIKey:       os.Getenv("RES_ROBOT_V2_1"),
		GTFSRegionalRTKey:    os.Getenv("GTFS_REGIONAL_REALTIME"),
		GTFSSweden3RTKey:     os.Getenv("GTFS_SWEDEN_3_REALTIME"),
		OxifyRealtimeKey:     os.Getenv("OXIFY_REALTIME_POSITION"),
		SIRIKey:              os.Getenv("SIRI"),
		TrafiklabRealtimeKey: os.Getenv("TRAFIKLAB_REALTIME_APIS"),
		ServerHost:           getEnvOrDefault("SERVER_HOST", "0.0.0.0"),
		ServerPort:           getEnvOrDefault("SERVER_PORT", "8080"),
	}

	if config.ResRobotAPIKey == "" {
		return nil, fmt.Errorf("RES_ROBOT_V2_1 API key not found")
	}

	return config, nil
}

func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// fetchDepartures fetches departures from ResRobot API
func (s *BFFServer) fetchDepartures(stopID string) ([]Departure, error) {
	s.totalRequests++
	
	url := fmt.Sprintf(
		"https://api.trafiklab.se/samtrafiken/resrobot/v2.1/StopPoint?stopId=%s&key=%s",
		stopID,
		s.config.ResRobotAPIKey,
	)

	resp, err := s.client.Get(url)
	if err != nil {
		s.upstreamCalls++
		return nil, fmt.Errorf("failed to fetch departures: %w", err)
	}
	defer resp.Body.Close()

	s.upstreamCalls++

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("API returned status %d: %s", resp.StatusCode, string(body))
	}

	var result struct {
		StopPoints []struct {
			StopID   string `json:"StopPointExtendedCode"`
			StopName string `json:"Name"`
			Departures []struct {
				LineName     string `json:"LineNumber"`
				Destination  string `json:"Destination"`
				ExpectedTime string `json:"ExpectedDateTime"`
				EstimatedTime string `json:"JourneyDetailRef"`
				Direction    int    `json:"Direction"`
			} `json:"DepartureOrArrival"`
		} `json:"StopPoints"`
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	var departures []Departure
	for _, sp := range result.StopPoints {
		for _, dep := range sp.Departures {
			departures = append(departures, Departure{
				StopID:        stopID,
				StopName:      sp.StopName,
				LineName:      dep.LineName,
				Destination:   dep.Destination,
				ExpectedTime:  dep.ExpectedTime,
				EstimatedTime: dep.EstimatedTime,
				Direction:     dep.Direction,
			})
		}
	}

	return departures, nil
}

// fetchVehicles fetches vehicle positions from GTFS-RT or Oxify API
func (s *BFFServer) fetchVehicles() ([]VehiclePosition, error) {
	s.totalRequests++
	
	// Check cache first (cache for 10 seconds)
	s.vehicleCacheMu.RLock()
	if time.Since(s.vehicleCacheTime) < 10*time.Second && len(s.vehicleCache) > 0 {
		s.collapsedRequests++
		cache := s.vehicleCache
		s.vehicleCacheMu.RUnlock()
		return cache, nil
	}
	s.vehicleCacheMu.RUnlock()

	s.vehicleCacheMu.Lock()
	defer s.vehicleCacheMu.Unlock()

	// Try Oxify API first (real-time vehicle positions)
	if s.config.OxifyRealtimeKey != "" {
		url := fmt.Sprintf(
			"https://api.trafiklab.se/oxify/vehicle-positions/v1?key=%s",
			s.config.OxifyRealtimeKey,
		)

		resp, err := s.client.Get(url)
		if err == nil {
			defer resp.Body.Close()
			s.upstreamCalls++

			if resp.StatusCode == http.StatusOK {
				body, err := io.ReadAll(resp.Body)
				if err == nil {
					s.protobufBytes += len(body)
					
					var result struct {
						Entity []struct {
							Vehicle struct {
								Vehicle struct {
									ID string `json:"id"`
								} `json:"vehicle"`
								Trip struct {
									RouteID string `json:"routeId"`
									TripID  string `json:"tripId"`
								} `json:"trip"`
								Position struct {
									Latitude  float64 `json:"latitude"`
									Longitude float64 `json:"longitude"`
									Bearing   float64 `json:"bearing"`
								} `json:"position"`
								VehicleTimestamp int64  `json:"timestamp"`
								Speed            float64 `json:"speed"`
								OccupancyStatus  string `json:"occupancyStatus"`
							} `json:"vehicle"`
						} `json:"entity"`
					}

					if err := json.Unmarshal(body, &result); err == nil {
						var vehicles []VehiclePosition
						for _, entity := range result.Entity {
							v := entity.Vehicle
							vehicles = append(vehicles, VehiclePosition{
								VehicleID:   v.Vehicle.ID,
								Latitude:    v.Position.Latitude,
								Longitude:   v.Position.Longitude,
								Bearing:     v.Position.Bearing,
								Speed:       v.Speed,
								RouteID:     v.Trip.RouteID,
								TripID:      v.Trip.TripID,
								LastUpdated: v.VehicleTimestamp,
								Occupancy:   v.OccupancyStatus,
							})
						}

						s.vehicleCache = vehicles
						s.vehicleCacheTime = time.Now()
						s.activeVehiclesSweden = len(vehicles)
						s.jsonBytes += len(body)
						
						return vehicles, nil
					}
				}
			}
		}
	}

	// Fallback: Return empty list if no API available
	return []VehiclePosition{}, nil
}

func (s *BFFServer) handleDepartures(w http.ResponseWriter, r *http.Request) {
	stopID := r.URL.Query().Get("stopId")
	if stopID == "" {
		http.Error(w, "stopId parameter required", http.StatusBadRequest)
		return
	}

	departures, err := s.fetchDepartures(stopID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"departures": departures,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func (s *BFFServer) handleVehicles(w http.ResponseWriter, r *http.Request) {
	vehicles, err := s.fetchVehicles()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	response := VehiclesResponse{
		Vehicles:                vehicles,
		TotalClientRequests:     s.totalRequests,
		UpstreamCallsMade:       s.upstreamCalls,
		CollapsedRequests:       s.collapsedRequests,
		NetworkSavingsPercent:   float64(s.collapsedRequests) / float64(s.totalRequests) * 100,
		ProtobufBytesProcessed:  s.protobufBytes,
		JSONStreamBytesEmitted:  s.jsonBytes,
		ActiveVehiclesInSweden:  s.activeVehiclesSweden,
		ActiveVehiclesInViewport: len(vehicles),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func (s *BFFServer) handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status": "ok",
		"time":   time.Now().Format(time.RFC3339),
	})
}

func (s *BFFServer) Start() error {
	mux := http.NewServeMux()
	mux.HandleFunc("/api/departures", s.handleDepartures)
	mux.HandleFunc("/api/vehicles", s.handleVehicles)
	mux.HandleFunc("/health", s.handleHealth)
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path == "/" {
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(map[string]string{
				"message": "SweDiscover BFF Server",
				"endpoints": "/api/departures, /api/vehicles, /health",
			})
		} else {
			http.NotFound(w, r)
		}
	})

	addr := fmt.Sprintf("%s:%s", s.config.ServerHost, s.config.ServerPort)
	log.Printf("Starting SweDiscover BFF on %s", addr)
	log.Printf("ResRobot API key configured: %v", s.config.ResRobotAPIKey != "")
	log.Printf("Oxify API key configured: %v", s.config.OxifyRealtimeKey != "")

	return http.ListenAndServe(addr, corsMiddleware(mux))
}

// corsMiddleware adds CORS headers for Flutter app
func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}

		next.ServeHTTP(w, r)
	})
}

func main() {
	config, err := loadConfig()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	server := NewBFFServer(config)
	
	if err := server.Start(); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
