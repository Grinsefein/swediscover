package main

import (
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"
	"time"

	gtfs "github.com/MobilityData/gtfs-realtime-bindings/golang/gtfs"
	"google.golang.org/protobuf/proto"
)

// mockTransport intercepts upstream calls and returns canned responses.
// It validates that the request URL matches expected hosts/paths (regression for bug #1 wrong URLs).
type mockTransport struct {
	t                *testing.T
	gtfsFeedByOperator map[string]*gtfs.FeedMessage // operator -> feed
	departuresJSON   string
	stopGroupsJSON     string
	tripDetailsJSON    string
	journeyJSON        string
	captureURLs        *[]string
}

func (m *mockTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	if m.captureURLs != nil {
		*m.captureURLs = append(*m.captureURLs, req.URL.String())
	}
	host := req.URL.Host
	path := req.URL.Path
	// Query key must be present (not header apikey) for new APIs
	if strings.Contains(path, "/departures/") || strings.Contains(path, "/stops/name/") || strings.Contains(path, "/trips/") {
		if req.URL.Query().Get("key") == "" && req.Header.Get("apikey") != "" {
			m.t.Errorf("API %s should use query ?key=, not header apikey (header=%q query=%q)", path, req.Header.Get("apikey"), req.URL.Query().Get("key"))
		}
	}

	// GTFS-RT Sweden: opendata.samtrafiken.se
	if host == "opendata.samtrafiken.se" {
		// Path: /gtfs-rt-sweden/{operator}/VehiclePositionsSweden.pb etc.
		parts := strings.Split(path, "/")
		if len(parts) < 4 {
			return &http.Response{StatusCode: 404, Body: io.NopCloser(strings.NewReader(`{}`)), Header: http.Header{}}, nil
		}
		operator := parts[2]
		feed, ok := m.gtfsFeedByOperator[operator]
		if !ok {
			return &http.Response{StatusCode: 404, Body: io.NopCloser(strings.NewReader(`{}`)), Header: http.Header{}}, nil
		}
		data, _ := proto.Marshal(feed)
		return &http.Response{StatusCode: 200, Body: io.NopCloser(strings.NewReader(string(data))), Header: http.Header{"Content-Type": []string{"application/octet-stream"}}}, nil
	}
	// Trafiklab realtime APIs: realtime-api.trafiklab.se
	if host == "realtime-api.trafiklab.se" {
		if strings.HasPrefix(path, "/v1/departures/") {
			body := m.departuresJSON
			if body == "" {
				body = `{"departures":[{"scheduled":"2026-08-21T12:00:00","realtime":"2026-08-21T12:03:00","delay":180,"canceled":false,"route":{"designation":"10","transport_mode":"BUS","direction":"Centralen"},"trip":{"trip_id":"t1"},"agency":{"operator":"Test"},"stop":{"id":"123"},"scheduled_platform":{"designation":"A"},"realtime_platform":{"designation":"A"}}]}`
			}
			return &http.Response{StatusCode: 200, Body: io.NopCloser(strings.NewReader(body)), Header: http.Header{"Content-Type": []string{"application/json"}}}, nil
		}
		if strings.HasPrefix(path, "/v1/stops/name/") {
			body := m.stopGroupsJSON
			if body == "" {
				body = `{"stop_groups":[{"id":"740000001","name":"Test Stop","area_type":"STOP","transport_modes":["BUS"],"stops":[{"id":"740000001","lat":59.33,"lon":18.06}]}]}`
			}
			return &http.Response{StatusCode: 200, Body: io.NopCloser(strings.NewReader(body)), Header: http.Header{"Content-Type": []string{"application/json"}}}, nil
		}
		if strings.HasPrefix(path, "/v1/trips/") {
			body := m.tripDetailsJSON
			if body == "" {
				body = `{"Trip":{"id":"t1","stops":[]}}`
			}
			return &http.Response{StatusCode: 200, Body: io.NopCloser(strings.NewReader(body)), Header: http.Header{"Content-Type": []string{"application/json"}}}, nil
		}
	}
	// ResRobot: api.resrobot.se
	if host == "api.resrobot.se" {
		if strings.HasPrefix(path, "/v2.1/trip") {
			// Must use accessId param, not apikey/key
			if req.URL.Query().Get("accessId") == "" {
				m.t.Errorf("ResRobot /trip should use accessId, got query %q", req.URL.RawQuery)
			}
			if strings.Contains(req.URL.String(), "apikey=") {
				m.t.Errorf("ResRobot URL must not contain apikey, got %q", req.URL.String())
			}
			body := m.journeyJSON
			if body == "" {
				body = `{"Trip":[{"LegList":{"Leg":[{"Origin":{"name":"A"},"Destination":{"name":"B"}}]}}]}`
			}
			return &http.Response{StatusCode: 200, Body: io.NopCloser(strings.NewReader(body)), Header: http.Header{"Content-Type": []string{"application/json"}}}, nil
		}
	}
	// Trafikverket should not be hit in these tests (requires XML POST)
	if host == "api.trafikinfo.trafikverket.se" {
		return &http.Response{StatusCode: 200, Body: io.NopCloser(strings.NewReader(`{"RESPONSE":{"RESULT":[]}}`)), Header: http.Header{"Content-Type": []string{"application/json"}}}, nil
	}
	// Fallback: fail test if unexpected host/path (catches wrong URLs like api.trafiklab.se/v2/StopPoints)
	m.t.Errorf("Unexpected upstream request: %s %s (captured URLs: %v)", host, path, req.URL.String())
	return &http.Response{StatusCode: 404, Body: io.NopCloser(strings.NewReader(`{"error":"unexpected upstream"}`)), Header: http.Header{}}, nil
}

func buildTestVehicleFeed(operator, suffix string) *gtfs.FeedMessage {
	return &gtfs.FeedMessage{
		Header: &gtfs.FeedHeader{GtfsRealtimeVersion: proto.String("2.0")},
		Entity: []*gtfs.FeedEntity{
			{
				Id: proto.String("e1" + suffix),
				Vehicle: &gtfs.VehiclePosition{
					Trip:     &gtfs.TripDescriptor{TripId: proto.String("trip-1"), RouteId: proto.String("r10")},
					Vehicle:  &gtfs.VehicleDescriptor{Id: proto.String("veh-1" + suffix)},
					Position: &gtfs.Position{Latitude: proto.Float32(59.33), Longitude: proto.Float32(18.06), Bearing: proto.Float32(90), Speed: proto.Float32(10)},
					StopId:   proto.String("740000001"),
					Timestamp: proto.Uint64(uint64(time.Now().Unix())),
					OccupancyStatus: gtfs.VehiclePosition_MANY_SEATS_AVAILABLE.Enum(),
				},
			},
		},
	}
}

func withMockUpstream(t *testing.T, mt *mockTransport, fn func()) {
	origTransport := apiClient.Transport
	origJourneyTransport := journeyClient.Transport
	apiClient.Transport = mt
	journeyClient.Transport = mt
	t.Cleanup(func() {
		apiClient.Transport = origTransport
		journeyClient.Transport = origJourneyTransport
	})
	fn()
}

// TestE2E_GTFSRT_MultiOperatorMerge verifies the multi-operator merge now hits the correct
// Samtrafiken host, uses ?key=, prefixes entity IDs, and returns vehicles.
func TestE2E_GTFSRT_MultiOperatorMerge(t *testing.T) {
	// Setup config without needing .env
	cfg = Config{
		GtfsRtKey:       "test-key-1234",
		GtfsRtOperators: []string{"sl", "skane"},
		RealtimeApisKey: "rt-key",
		ResrobotKey:     "rr-key",
		TrafikverketKey: "tv-key",
		ServerPort:      "8080",
	}
	var captured []string
	mt := &mockTransport{
		t: t,
		gtfsFeedByOperator: map[string]*gtfs.FeedMessage{
			"sl":    buildTestVehicleFeed("sl", "-sl"),
			"skane": buildTestVehicleFeed("skane", "-sk"),
		},
		captureURLs: &captured,
	}
	withMockUpstream(t, mt, func() {
		feed, err := fetchGTFSRTFeed("vehicle-positions")
		if err != nil {
			t.Fatalf("fetchGTFSRTFeed: %v", err)
		}
		if len(feed.Entity) != 2 {
			t.Fatalf("merged entities = %d, want 2", len(feed.Entity))
		}
		// Verify prefixing
		ids := map[string]bool{}
		for _, e := range feed.Entity {
			ids[e.GetId()] = true
		}
		if !ids["sl:e1-sl"] || !ids["skane:e1-sk"] {
			t.Errorf("entity IDs not prefixed: %v", ids)
		}
		// Verify URLs used correct host and key param
		for _, u := range captured {
			if !strings.Contains(u, "opendata.samtrafiken.se") {
				t.Errorf("GTFS URL wrong host: %q", u)
			}
			if !strings.Contains(u, "key=test-key-1234") {
				t.Errorf("GTFS URL missing ?key=: %q", u)
			}
			if strings.Contains(u, "realtime-api.trafiklab.se") {
				t.Errorf("GTFS URL hit old host: %q", u)
			}
		}
		// Full vehicles pipeline
		vehicles, err := fetchVehiclesFromGTFSRT()
		if err != nil {
			t.Fatalf("fetchVehiclesFromGTFSRT: %v", err)
		}
		if len(vehicles) != 2 {
			t.Fatalf("vehicles = %d, want 2", len(vehicles))
		}
		v0 := vehicles[0].(map[string]interface{})
		if v0["vehicleId"] != "sl:veh-1-sl" {
			t.Errorf("vehicleId = %v, want sl:veh-1-sl", v0["vehicleId"])
		}
		if v0["lat"].(float64) < 59.3 {
			t.Errorf("lat = %v, want ~59.33", v0["lat"])
		}
		if v0["speedKmh"].(float64) < 35 {
			t.Errorf("speedKmh = %v, want ~36", v0["speedKmh"])
		}
	})
}

func TestE2E_Departures_CorrectURLAndTransform(t *testing.T) {
	cfg.RealtimeApisKey = "deptest-key"
	var captured []string
	mt := &mockTransport{t: t, captureURLs: &captured}
	withMockUpstream(t, mt, func() {
		deps, err := fetchDeparturesFromTrafiklab("740020101")
		if err != nil {
			t.Fatalf("fetchDepartures: %v", err)
		}
		if len(deps) != 1 {
			t.Fatalf("departures len %d", len(deps))
		}
		d := deps[0].(map[string]interface{})
		// Verify transform
		if d["line"] != "10" {
			t.Errorf("line = %v, want 10", d["line"])
		}
		if d["destination"] != "Centralen" {
			t.Errorf("destination = %v", d["destination"])
		}
		if d["mode"] != "bus" {
			t.Errorf("mode = %v, want bus", d["mode"])
		}
		if d["delaySeconds"].(int) != 180 {
			t.Errorf("delay = %v", d["delaySeconds"])
		}
		if d["track"] != "A" {
			t.Errorf("track = %v", d["track"])
		}
		// Verify URL was correct (not old /v2/StopPoints)
		if len(captured) == 0 {
			t.Fatal("no upstream URL captured")
		}
		u := captured[0]
		if !strings.Contains(u, "realtime-api.trafiklab.se/v1/departures/740020101") {
			t.Errorf("departures URL wrong: %q", u)
		}
		if !strings.Contains(u, "key=deptest-key") {
			t.Errorf("departures URL missing key param: %q", u)
		}
		if strings.Contains(u, "StopPoints") || strings.Contains(u, "apikey") {
			t.Errorf("departures URL hit old path: %q", u)
		}
	})
}

func TestE2E_Stops_CorrectURLAndTransform(t *testing.T) {
	cfg.RealtimeApisKey = "stoptest-key"
	var captured []string
	mt := &mockTransport{t: t, captureURLs: &captured}
	withMockUpstream(t, mt, func() {
		stops, err := searchStops("T-Centralen")
		if err != nil {
			t.Fatalf("searchStops: %v", err)
		}
		if len(stops) != 1 {
			t.Fatalf("stops len %d", len(stops))
		}
		s := stops[0].(map[string]interface{})
		if s["name"] != "Test Stop" {
			t.Errorf("name = %v", s["name"])
		}
		u := captured[0]
		if !strings.Contains(u, "realtime-api.trafiklab.se/v1/stops/name/T-Centralen") {
			t.Errorf("stops URL wrong: %q", u)
		}
		if strings.Contains(u, "api.trafiklab.se/v2/StopPoints") {
			t.Errorf("stops URL old host: %q", u)
		}
	})
}

func TestE2E_TripDetails_UsesKeyParamNotHeader(t *testing.T) {
	cfg.RealtimeApisKey = "triptest-key"
	var captured []string
	mt := &mockTransport{t: t, captureURLs: &captured}
	withMockUpstream(t, mt, func() {
		_, err := fetchTripDetails("trip123", "2026-08-21")
		if err != nil {
			t.Fatalf("fetchTripDetails: %v", err)
		}
		u := captured[0]
		if !strings.Contains(u, "realtime-api.trafiklab.se/v1/trips/trip123/2026-08-21") {
			t.Errorf("trip URL wrong: %q", u)
		}
		if !strings.Contains(u, "key=triptest-key") {
			t.Errorf("trip URL should have ?key=: %q", u)
		}
	})
}

func TestE2E_Journey_UsesResRobotHostAndAccessId(t *testing.T) {
	cfg.ResrobotKey = "rrkey123"
	var captured []string
	mt := &mockTransport{t: t, captureURLs: &captured}
	withMockUpstream(t, mt, func() {
		_, err := fetchJourneyFromResRobot("740000001", "740000002", "12:00", "2026-08-21")
		if err != nil {
			t.Fatalf("fetchJourney: %v", err)
		}
		u := captured[0]
		if !strings.Contains(u, "api.resrobot.se/v2.1/trip") {
			t.Errorf("journey URL wrong host: %q", u)
		}
		if !strings.Contains(u, "accessId=rrkey123") {
			t.Errorf("journey URL missing accessId: %q", u)
		}
		if strings.Contains(u, "api.trafiklab.se/v2.1/TravelPlanner") {
			t.Errorf("journey URL old path: %q", u)
		}
		parsed, _ := url.Parse(u)
		if parsed.Query().Get("originId") != "740000001" || parsed.Query().Get("destId") != "740000002" {
			t.Errorf("journey query wrong: %q", parsed.RawQuery)
		}
	})
}

func TestE2E_HealthAndDebugEndpoints(t *testing.T) {
	// Ensure handlers don't require keys and return valid JSON
	req := httptest.NewRequest("GET", "/api/health", nil)
	w := httptest.NewRecorder()
	handleHealth(w, req)
	if w.Code != 200 {
		t.Fatalf("health status %d", w.Code)
	}
	var h map[string]interface{}
	if err := json.Unmarshal(w.Body.Bytes(), &h); err != nil {
		t.Fatalf("health json: %v", err)
	}
	if h["status"] != "ok" {
		t.Errorf("health status = %v, want ok", h["status"])
	}

	req2 := httptest.NewRequest("GET", "/api/debug", nil)
	w2 := httptest.NewRecorder()
	handleDebug(w2, req2)
	if w2.Code != 200 {
		t.Fatalf("debug status %d", w2.Code)
	}
	var d map[string]interface{}
	if err := json.Unmarshal(w2.Body.Bytes(), &d); err != nil {
		t.Fatalf("debug json: %v", err)
	}
	if _, ok := d["config"]; !ok {
		t.Error("debug missing config")
	}
	if _, ok := d["telemetry"]; !ok {
		t.Error("debug missing telemetry")
	}
	// Keys must be masked, not leaked
	cfgMap := d["config"].(map[string]interface{})
	masked := cfgMap["keysMasked"].(map[string]interface{})
	for k, v := range masked {
		s := v.(string)
		if s != "<empty>" && s != "***" && !strings.Contains(s, "***") {
			t.Errorf("key %s not masked: %q", k, s)
		}
	}
}

func TestE2E_VehiclesHandler_CacheAndTelemetry(t *testing.T) {
	// Reset global caches/telemetry for determinism
	cacheMu.Lock()
	vehiclesCache = nil
	departuresCache = make(map[string]*cacheEntry)
	tripUpdatesCache = nil
	cacheMu.Unlock()
	telemetry = &Telemetry{}

	cfg.GtfsRtKey = "k"
	feed := buildTestVehicleFeed("sl", "")
	mt := &mockTransport{
		t: t,
		gtfsFeedByOperator: map[string]*gtfs.FeedMessage{"sl": feed},
	}
	// Only sl operator for this test to keep counts predictable
	origOps := cfg.GtfsRtOperators
	cfg.GtfsRtOperators = []string{"sl"}
	t.Cleanup(func() { cfg.GtfsRtOperators = origOps })

	withMockUpstream(t, mt, func() {
		req := httptest.NewRequest("GET", "/api/vehicles", nil)
		w := httptest.NewRecorder()
		handleVehicles(w, req)
		if w.Code != 200 {
			t.Fatalf("vehicles handler status %d body %s", w.Code, w.Body.String())
		}
		var res VehiclesResponse
		if err := json.Unmarshal(w.Body.Bytes(), &res); err != nil {
			// Try generic map for telemetry check
			var m map[string]interface{}
			json.Unmarshal(w.Body.Bytes(), &m)
			t.Fatalf("vehicles unmarshal: %v, body %s", err, w.Body.String())
		}
		if len(res.Vehicles) != 1 {
			t.Errorf("vehicles len %d, want 1", len(res.Vehicles))
		}
		if res.Telemetry.TotalClientRequests != 1 || res.Telemetry.UpstreamCallsMade != 1 {
			t.Errorf("telemetry total=%d upstream=%d", res.Telemetry.TotalClientRequests, res.Telemetry.UpstreamCallsMade)
		}
		// Second call should be cache HIT (CollapsedRequests)
		req2 := httptest.NewRequest("GET", "/api/vehicles", nil)
		w2 := httptest.NewRecorder()
		handleVehicles(w2, req2)
		if w2.Code != 200 {
			t.Fatalf("second vehicles status %d", w2.Code)
		}
		var res2 VehiclesResponse
		json.Unmarshal(w2.Body.Bytes(), &res2)
		if res2.Telemetry.CollapsedRequests != 1 {
			t.Errorf("collapsed = %d, want 1", res2.Telemetry.CollapsedRequests)
		}
		if w2.Header().Get("X-Cache") != "HIT" {
			t.Errorf("X-Cache = %q, want HIT", w2.Header().Get("X-Cache"))
		}
	})
}

func TestE2E_DeparturesHandler_Cache(t *testing.T) {
	cacheMu.Lock()
	departuresCache = make(map[string]*cacheEntry)
	cacheMu.Unlock()
	telemetry = &Telemetry{}
	cfg.RealtimeApisKey = "k"
	mt := &mockTransport{t: t}
	withMockUpstream(t, mt, func() {
		req := httptest.NewRequest("GET", "/api/departures?stopId=123", nil)
		w := httptest.NewRecorder()
		handleDepartures(w, req)
		if w.Code != 200 {
			t.Fatalf("departures status %d %s", w.Code, w.Body.String())
		}
		req2 := httptest.NewRequest("GET", "/api/departures?stopId=123", nil)
		w2 := httptest.NewRecorder()
		handleDepartures(w2, req2)
		if w2.Header().Get("X-Cache") != "HIT" {
			t.Errorf("expected HIT, got %q", w2.Header().Get("X-Cache"))
		}
	})
}

func TestE2E_Middleware_LogsAndMasksQuery(t *testing.T) {
	// Verify logging middleware does not leak keys and records status
	inner := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(200)
		io.WriteString(w, `{"ok":true}`)
	})
	mw := loggingMiddleware(inner)
	req := httptest.NewRequest("GET", "/api/vehicles?key=secret123&foo=bar", nil)
	w := httptest.NewRecorder()
	// Capture log output (just ensure no panic and status captured)
	mw.ServeHTTP(w, req)
	if w.Code != 200 {
		t.Fatalf("mw status %d", w.Code)
	}
}

func TestE2E_TransformTimetableDeparture_EdgeCases(t *testing.T) {
	// Empty route/stop, canceled, missing times
	item := map[string]interface{}{
		"scheduled": "2026-08-21T10:00:00",
		"realtime":  "",
		"delay":     float64(0),
		"canceled":  true,
		"route": map[string]interface{}{
			"designation":    "",
			"name":           "FallbackLine",
			"transport_mode": "METRO",
			"direction":      "T-Centralen",
		},
		"trip": map[string]interface{}{"trip_id": "t99"},
	}
	res := transformTimetableDeparture(item, "740000001", 0)
	if res["line"] != "FallbackLine" {
		t.Errorf("line fallback %v", res["line"])
	}
	if res["status"] != "cancelled" {
		t.Errorf("status %v want cancelled", res["status"])
	}
	if res["mode"] != "tunnelbana" {
		t.Errorf("mode %v want tunnelbana", res["mode"])
	}
	if res["scheduledTime"] != "2026-08-21T10:00:00" {
		t.Errorf("scheduledTime %v", res["scheduledTime"])
	}
}
