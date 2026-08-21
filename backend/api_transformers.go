package main

// Transformation der Trafiklab realtime APIs (Timetables / Stop Lookup) in das
// JSON-Contract der Flutter-App.
//
// Contract-Quellen:
//   - TransitDeparture.fromJson:  lib/models/departure_model.dart
//   - Stops-Suche: BFF-eigenes Format {id, name, lat, lng, transportModes}

import (
	"fmt"
	"strings"
)

// transformTimetableDeparture mappt ein Departure-Item des Trafiklab
// Timetables Endpoints auf das App-Contract.
//
// Upstream-Shape (Auszug):
//
//	{"scheduled": "...", "realtime": "...", "delay": 868, "canceled": false,
//	 "route": {"designation": "76", "transport_mode": "BUS", "direction": "..."},
//	 "trip": {"trip_id": "..."}, "agency": {"name": "...", "operator": "..."},
//	 "stop": {"id": "..."}, "scheduled_platform"/"realtime_platform": {"designation": "B"}}
func transformTimetableDeparture(item map[string]interface{}, stopID string, index int) map[string]interface{} {
	route, _ := item["route"].(map[string]interface{})
	trip, _ := item["trip"].(map[string]interface{})
	agency, _ := item["agency"].(map[string]interface{})

	line := stringField(route, "designation")
	if line == "" {
		line = stringField(route, "name")
	}

	scheduled := stringField(item, "scheduled")
	realtime := stringField(item, "realtime")
	if realtime == "" {
		realtime = scheduled
	}
	if scheduled == "" {
		scheduled = realtime
	}

	delaySeconds := numberField(item, "delay")

	status := "onTime"
	if boolField(item, "canceled") {
		status = "cancelled"
	} else if delaySeconds > 60 {
		status = "delayed"
	}

	id := fmt.Sprintf("%s-%d", stringField(trip, "trip_id"), index)

	return map[string]interface{}{
		"id":            id,
		"stopId":        defaultString(stringField(item, "stopId"), stopID),
		"line":          line,
		"destination":   stringField(route, "direction"),
		"mode":          mapTransportMode(stringField(route, "transport_mode")),
		"scheduledTime": scheduled,
		"realtimeTime":  realtime,
		"delaySeconds":  int(delaySeconds),
		"status":        status,
		"track":         platformDesignation(item, "realtime_platform", "scheduled_platform"),
		"originalTrack": platformDesignation(item, "scheduled_platform"),
		"operatorName":  coalesce(stringField(agency, "operator"), stringField(agency, "name")),
	}
}

// transformStopGroup mappt eine stop_group des Stop Lookup Endpoints auf das
// BFF-Stops-Format. Lat/Lng kommen vom ersten Sub-Stop der Gruppe.
func transformStopGroup(group map[string]interface{}) map[string]interface{} {
	result := map[string]interface{}{
		"id":             stringField(group, "id"),
		"name":           stringField(group, "name"),
		"areaType":       stringField(group, "area_type"),
		"transportModes": group["transport_modes"],
	}

	if stops, ok := group["stops"].([]interface{}); ok && len(stops) > 0 {
		if first, ok := stops[0].(map[string]interface{}); ok {
			result["lat"] = numberField(first, "lat")
			result["lng"] = numberField(first, "lon")
		}
	}
	return result
}

// mapTransportMode bildet transport_mode-Strings auf die App-Enum ab
// (tunnelbana|pendeltag|fjarrtag|bus|tram|ferry).
func mapTransportMode(mode string) string {
	switch strings.ToUpper(strings.TrimSpace(mode)) {
	case "METRO":
		return "tunnelbana"
	case "TRAM":
		return "tram"
	case "FERRY", "BOAT":
		return "ferry"
	case "TRAIN", "RAIL", "LONG_DISTANCE_TRAIN", "COMMUTER_TRAIN":
		// Pendeltåg vs. Fjärrtåg ist ohne route_id-Mapping nicht unterscheidbar.
		return "fjarrtag"
	default: // BUS und unbekannte Modi
		return "bus"
	}
}

func stringField(m map[string]interface{}, key string) string {
	if m == nil {
		return ""
	}
	if v, ok := m[key].(string); ok {
		return v
	}
	return ""
}

func numberField(m map[string]interface{}, key string) float64 {
	if m == nil {
		return 0
	}
	if v, ok := m[key].(float64); ok {
		return v
	}
	return 0
}

func boolField(m map[string]interface{}, key string) bool {
	if v, ok := m[key].(bool); ok {
		return v
	}
	return false
}

// platformDesignation liefert die erste vorhandene Platform-Bezeichnung.
func platformDesignation(m map[string]interface{}, keys ...string) string {
	for _, key := range keys {
		if p, ok := m[key].(map[string]interface{}); ok {
			if d := stringField(p, "designation"); d != "" {
				return d
			}
		}
	}
	return ""
}

func defaultString(value, fallback string) string {
	if value != "" {
		return value
	}
	return fallback
}

func coalesce(values ...string) string {
	for _, v := range values {
		if v != "" {
			return v
		}
	}
	return ""
}
