package main

// Round-Trip-Tests: Fixtures werden mit den offiziellen Bindings gebaut und
// via proto.Marshal in echtes GTFS-RT-Wire-Format serialisiert, dann wieder
// geparst und transformiert. So ist sichergestellt, dass die Transformer mit
// realen Feeds funktionieren.

import (
	"testing"
	"time"

	gtfs "github.com/MobilityData/gtfs-realtime-bindings/golang/gtfs"
	"google.golang.org/protobuf/proto"
)

func marshalFeed(t *testing.T, feed *gtfs.FeedMessage) *gtfs.FeedMessage {
	t.Helper()
	data, err := proto.Marshal(feed)
	if err != nil {
		t.Fatalf("proto.Marshal failed: %v", err)
	}
	parsed := &gtfs.FeedMessage{}
	if err := proto.Unmarshal(data, parsed); err != nil {
		t.Fatalf("proto.Unmarshal failed: %v", err)
	}
	return parsed
}

func TestVehiclesFromFeed(t *testing.T) {
	feed := marshalFeed(t, &gtfs.FeedMessage{
		Header: &gtfs.FeedHeader{GtfsRealtimeVersion: proto.String("2.0"), Timestamp: proto.Uint64(1700000000)},
		Entity: []*gtfs.FeedEntity{
			{
				Id: proto.String("entity-1"),
				Vehicle: &gtfs.VehiclePosition{
					Trip:            &gtfs.TripDescriptor{TripId: proto.String("trip-1"), RouteId: proto.String("route-17")},
					Vehicle:         &gtfs.VehicleDescriptor{Id: proto.String("veh-42")},
					Position:        &gtfs.Position{Latitude: proto.Float32(59.3293), Longitude: proto.Float32(18.0686), Bearing: proto.Float32(90), Speed: proto.Float32(12.5)},
					StopId:          proto.String("stop-740000001"),
					Timestamp:       proto.Uint64(1699999999),
					OccupancyStatus: gtfs.VehiclePosition_FEW_SEATS_AVAILABLE.Enum(),
				},
			},
			{
				Id: proto.String("entity-2"),
				Vehicle: &gtfs.VehiclePosition{
					Trip:     &gtfs.TripDescriptor{TripId: proto.String("trip-2")},
					Position: &gtfs.Position{Latitude: proto.Float32(57.7089), Longitude: proto.Float32(11.9746)},
				},
			},
			// Entity ohne VehiclePosition muss ignoriert werden
			{Id: proto.String("entity-empty")},
		},
	})

	vehicles := vehiclesFromFeed(feed, map[string]int32{"trip-1": 300})
	if len(vehicles) != 2 {
		t.Fatalf("expected 2 vehicles, got %d", len(vehicles))
	}

	v1 := vehicles[0].(map[string]interface{})
	if v1["vehicleId"] != "veh-42" {
		t.Errorf("vehicleId = %v, want veh-42", v1["vehicleId"])
	}
	if v1["tripId"] != "trip-1" {
		t.Errorf("tripId = %v, want trip-1", v1["tripId"])
	}
	if v1["line"] != "route-17" {
		t.Errorf("line = %v, want route-17", v1["line"])
	}
	if v1["lat"].(float64) < 59.3292 || v1["lat"].(float64) > 59.3294 {
		t.Errorf("lat = %v, want ~59.3293 (float32 round-trip)", v1["lat"])
	}
	if v1["lng"].(float64) < 18.0685 || v1["lng"].(float64) > 18.0687 {
		t.Errorf("lng = %v, want ~18.0686", v1["lng"])
	}
	if got := v1["speedKmh"].(float64); got < 44.99 || got > 45.01 {
		t.Errorf("speedKmh = %v, want 45.0 (12.5 m/s * 3.6)", got)
	}
	if v1["bearing"].(float64) != 90 {
		t.Errorf("bearing = %v, want 90", v1["bearing"])
	}
	if v1["occupancy"] != "fewSeats" {
		t.Errorf("occupancy = %v, want fewSeats", v1["occupancy"])
	}
	if v1["nextStopName"] != "stop-740000001" {
		t.Errorf("nextStopName = %v, want stop-740000001", v1["nextStopName"])
	}
	if v1["delayMinutes"] != 5 {
		t.Errorf("delayMinutes = %v, want 5 (300s joined from TripUpdates)", v1["delayMinutes"])
	}
	if _, ok := v1["lastGpsReport"]; !ok {
		t.Error("lastGpsReport missing despite timestamp present")
	}

	// Fallback auf Entity-ID wenn VehicleDescriptor.Id fehlt
	v2 := vehicles[1].(map[string]interface{})
	if v2["vehicleId"] != "entity-2" {
		t.Errorf("vehicleId fallback = %v, want entity-2", v2["vehicleId"])
	}
	if v2["delayMinutes"] != 0 {
		t.Errorf("delayMinutes default = %v, want 0", v2["delayMinutes"])
	}
}

func TestVehiclesFromFeedDeduplicatesByVehicleID(t *testing.T) {
	feed := marshalFeed(t, &gtfs.FeedMessage{
		Header: &gtfs.FeedHeader{GtfsRealtimeVersion: proto.String("2.0")},
		Entity: []*gtfs.FeedEntity{
			{
				Id: proto.String("e1"),
				Vehicle: &gtfs.VehiclePosition{
					Vehicle:  &gtfs.VehicleDescriptor{Id: proto.String("same-veh")},
					Position: &gtfs.Position{Latitude: proto.Float32(1.0), Longitude: proto.Float32(2.0)},
				},
			},
			{
				Id: proto.String("e2"),
				Vehicle: &gtfs.VehiclePosition{
					Vehicle:  &gtfs.VehicleDescriptor{Id: proto.String("same-veh")},
					Position: &gtfs.Position{Latitude: proto.Float32(3.0), Longitude: proto.Float32(4.0)},
				},
			},
		},
	})

	vehicles := vehiclesFromFeed(feed, nil)
	if len(vehicles) != 1 {
		t.Fatalf("expected dedup to 1 vehicle, got %d", len(vehicles))
	}
	v := vehicles[0].(map[string]interface{})
	if v["lat"].(float64) < 2.99 {
		t.Errorf("expected last entry to win (lat ~3.0), got %v", v["lat"])
	}
}

func TestTripDelaysFromFeed(t *testing.T) {
	feed := marshalFeed(t, &gtfs.FeedMessage{
		Header: &gtfs.FeedHeader{GtfsRealtimeVersion: proto.String("2.0")},
		Entity: []*gtfs.FeedEntity{
			{
				Id:         proto.String("tu-1"),
				TripUpdate: &gtfs.TripUpdate{Trip: &gtfs.TripDescriptor{TripId: proto.String("trip-a")}, Delay: proto.Int32(120)},
			},
			{
				Id: proto.String("tu-2"),
				TripUpdate: &gtfs.TripUpdate{
					Trip: &gtfs.TripDescriptor{TripId: proto.String("trip-b")},
					StopTimeUpdate: []*gtfs.TripUpdate_StopTimeUpdate{
						{StopSequence: proto.Uint32(1)},
						{StopSequence: proto.Uint32(2), Arrival: &gtfs.TripUpdate_StopTimeEvent{Delay: proto.Int32(-60)}},
					},
				},
			},
			{
				Id:         proto.String("tu-3"),
				TripUpdate: &gtfs.TripUpdate{Trip: &gtfs.TripDescriptor{}}, // ohne TripId → ignorieren
			},
		},
	})

	delays := tripDelaysFromFeed(feed)
	if delays["trip-a"] != 120 {
		t.Errorf("trip-a delay = %d, want 120 (trip-level)", delays["trip-a"])
	}
	if delays["trip-b"] != -60 {
		t.Errorf("trip-b delay = %d, want -60 (from StopTimeUpdate arrival)", delays["trip-b"])
	}
	if len(delays) != 2 {
		t.Errorf("expected 2 entries, got %d (%v)", len(delays), delays)
	}
}

func TestTransformTripUpdateToJSON(t *testing.T) {
	entity := &gtfs.FeedEntity{
		Id: proto.String("tu-1"),
		TripUpdate: &gtfs.TripUpdate{
			Trip:      &gtfs.TripDescriptor{TripId: proto.String("trip-x"), RouteId: proto.String("route-1"), DirectionId: proto.Uint32(1)},
			Vehicle:   &gtfs.VehicleDescriptor{Id: proto.String("veh-9")},
			Delay:     proto.Int32(240),
			Timestamp: proto.Uint64(1700000000),
		},
	}

	result := transformTripUpdateToJSON(entity)
	if result["tripId"] != "trip-x" || result["routeId"] != "route-1" {
		t.Errorf("unexpected ids: %v", result)
	}
	if result["directionId"] != uint32(1) {
		t.Errorf("directionId = %v, want 1", result["directionId"])
	}
	if result["delaySeconds"] != int32(240) {
		t.Errorf("delaySeconds = %v, want 240", result["delaySeconds"])
	}
	wantTime := time.Unix(1700000000, 0).UTC().Format(time.RFC3339)
	if result["timestamp"] != wantTime {
		t.Errorf("timestamp = %v, want %v", result["timestamp"], wantTime)
	}
}

func TestTransformAlertToJSON(t *testing.T) {
	alert := &gtfs.Alert{
		InformedEntity: []*gtfs.EntitySelector{
			{RouteId: proto.String("route-1"), StopId: proto.String("stop-1")},
		},
		Cause:           gtfs.Alert_CONSTRUCTION.Enum(),
		Effect:          gtfs.Alert_DETOUR.Enum(),
		HeaderText:      &gtfs.TranslatedString{Translation: []*gtfs.TranslatedString_Translation{{Text: proto.String("Arbete"), Language: proto.String("sv")}}},
		DescriptionText: &gtfs.TranslatedString{Translation: []*gtfs.TranslatedString_Translation{{Text: proto.String("Omkörning")}}},
		ActivePeriod:    []*gtfs.TimeRange{{Start: proto.Uint64(1700000000), End: proto.Uint64(1700086400)}},
	}

	result := transformAlertToJSON(alert)
	if result["header"] != "Arbete" {
		t.Errorf("header = %v, want Arbete", result["header"])
	}
	if result["description"] != "Omkörning" {
		t.Errorf("description = %v, want Omkörning", result["description"])
	}
	if result["cause"] != "CONSTRUCTION" {
		t.Errorf("cause = %v, want CONSTRUCTION (offizielle Enum-Namen)", result["cause"])
	}
	if result["effect"] != "DETOUR" {
		t.Errorf("effect = %v, want DETOUR", result["effect"])
	}
	entities := result["informedEntities"].([]interface{})
	first := entities[0].(map[string]interface{})
	if first["routeId"] != "route-1" || first["stopId"] != "stop-1" {
		t.Errorf("informedEntities[0] = %v", first)
	}
	periods := result["activePeriods"].([]interface{})
	p := periods[0].(map[string]interface{})
	if p["start"] != uint64(1700000000) {
		t.Errorf("activePeriod start = %v", p["start"])
	}
}

func TestTagFeedEntities(t *testing.T) {
	feed := marshalFeed(t, &gtfs.FeedMessage{
		Header: &gtfs.FeedHeader{GtfsRealtimeVersion: proto.String("2.0")},
		Entity: []*gtfs.FeedEntity{
			{
				Id: proto.String("e1"),
				Vehicle: &gtfs.VehiclePosition{
					Trip:     &gtfs.TripDescriptor{TripId: proto.String("trip-1")},
					Vehicle:  &gtfs.VehicleDescriptor{Id: proto.String("veh-1")},
					Position: &gtfs.Position{Latitude: proto.Float32(1.0), Longitude: proto.Float32(2.0)},
				},
			},
			{
				Id:         proto.String("e2"),
				TripUpdate: &gtfs.TripUpdate{Trip: &gtfs.TripDescriptor{TripId: proto.String("trip-1")}, Delay: proto.Int32(60)},
			},
		},
	})

	tagFeedEntities(feed, "skane")

	vp := feed.GetEntity()[0].GetVehicle()
	if feed.GetEntity()[0].GetId() != "skane:e1" {
		t.Errorf("entity id = %q, want skane:e1", feed.GetEntity()[0].GetId())
	}
	if vp.GetVehicle().GetId() != "skane:veh-1" {
		t.Errorf("vehicle id = %q, want skane:veh-1", vp.GetVehicle().GetId())
	}
	if vp.GetTrip().GetTripId() != "skane:trip-1" {
		t.Errorf("trip id = %q, want skane:trip-1", vp.GetTrip().GetTripId())
	}
	if got := feed.GetEntity()[1].GetTripUpdate().GetTrip().GetTripId(); got != "skane:trip-1" {
		t.Errorf("trip update trip id = %q, want skane:trip-1", got)
	}

	// Join über getaggte IDs muss funktionieren
	delays := tripDelaysFromFeed(feed)
	if delays["skane:trip-1"] != 60 {
		t.Errorf("joined delay = %d, want 60", delays["skane:trip-1"])
	}
}

func TestMapOccupancyStatus(t *testing.T) {
	cases := map[gtfs.VehiclePosition_OccupancyStatus]string{
		gtfs.VehiclePosition_EMPTY:                      "empty",
		gtfs.VehiclePosition_MANY_SEATS_AVAILABLE:       "manySeats",
		gtfs.VehiclePosition_FEW_SEATS_AVAILABLE:        "fewSeats",
		gtfs.VehiclePosition_STANDING_ROOM_ONLY:         "standingRoom",
		gtfs.VehiclePosition_CRUSHED_STANDING_ROOM_ONLY: "full",
		gtfs.VehiclePosition_FULL:                       "full",
		gtfs.VehiclePosition_NO_DATA_AVAILABLE:          "",
	}
	for status, want := range cases {
		if got := mapOccupancyStatus(status); got != want {
			t.Errorf("mapOccupancyStatus(%v) = %q, want %q", status, got, want)
		}
	}
}

func TestFilterVehiclesByBBox(t *testing.T) {
	vehicles := []interface{}{
		map[string]interface{}{"latitude": 59.33, "longitude": 18.07},
		map[string]interface{}{"latitude": 55.60, "longitude": 13.00}, // Malmö, außerhalb
		map[string]interface{}{"latitude": 59.50, "longitude": 17.90},
		map[string]interface{}{"missing": true},
	}

	filtered := filterVehiclesByBBox(vehicles, 59.0, 17.5, 60.0, 19.0)
	if len(filtered) != 2 {
		t.Fatalf("expected 2 vehicles in bbox, got %d", len(filtered))
	}
}
