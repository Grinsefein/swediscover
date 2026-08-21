package main

// Transformation von GTFS-RT Entities (offizielle MobilityData-Bindings)
// in das JSON-Contract der Flutter-App.
//
// Contract-Quelle: lib/models/vehicle_position_model.dart
// (RealtimeVehiclePosition.fromJson)

import (
	"fmt"
	"io"
	"log"
	"strings"
	"time"

	gtfs "github.com/MobilityData/gtfs-realtime-bindings/golang/gtfs"
	"google.golang.org/protobuf/proto"
)

const gtfsRTBaseURL = "https://opendata.samtrafiken.se/gtfs-rt-sweden"

// gtfsRTFeedFile mappt Feed-Typ auf den Dateinamen der GTFS Sweden Realtime API.
var gtfsRTFeedFile = map[string]string{
	"vehicle-positions": "VehiclePositionsSweden.pb",
	"trip-updates":      "TripUpdatesSweden.pb",
	"alerts":            "ServiceAlertsSweden.pb",
}

// fetchGTFSRTFeed lädt und parst GTFS-RT-Protobuf-Feeds (GTFS Sweden Realtime,
// opendata.samtrafiken.se) für alle konfigurierten Operatoren und merged sie
// in eine FeedMessage. Entity-/Vehicle-/Trip-IDs werden mit dem Operator
// präfixiert, damit sich Feeds verschiedener Operatoren nicht in die Quere
// kommen. feedType ist einer von "vehicle-positions", "trip-updates", "alerts".
//
// Hinweis: Go-Transport setzt Accept-Encoding: gzip automatisch und
// dekomprimiert transparent (laut API-Spec Pflicht).
func fetchGTFSRTFeed(feedType string) (*gtfs.FeedMessage, error) {
	merged := &gtfs.FeedMessage{}
	if cfg.GtfsRtKey == "" {
		return merged, nil
	}

	file, ok := gtfsRTFeedFile[feedType]
	if !ok {
		return nil, fmt.Errorf("unknown GTFS-RT feed type %q", feedType)
	}

	var lastErr error
	for _, operator := range cfg.GtfsRtOperators {
		operator = strings.TrimSpace(operator)
		if operator == "" {
			continue
		}
		url := fmt.Sprintf("%s/%s/%s?key=%s", gtfsRTBaseURL, operator, file, cfg.GtfsRtKey)

		resp, err := apiClient.Get(url)
		if err != nil {
			lastErr = err
			log.Printf("GTFS-RT %s/%s fetch failed: %v", operator, feedType, err)
			continue
		}

		data, readErr := io.ReadAll(resp.Body)
		resp.Body.Close()
		if resp.StatusCode != 200 {
			// 404 = Operator hat diesen Feed nicht (z.B. fehlen manchen
			// Operatoren VehiclePositions) → kein Fehler, überspringen.
			log.Printf("GTFS-RT %s/%s unavailable (HTTP %d)", operator, feedType, resp.StatusCode)
			continue
		}
		if readErr != nil {
			lastErr = readErr
			continue
		}

		telemetry.mu.Lock()
		telemetry.ProtobufBytesProcessed += int64(len(data))
		telemetry.mu.Unlock()

		feed := &gtfs.FeedMessage{}
		if err := proto.Unmarshal(data, feed); err != nil {
			lastErr = fmt.Errorf("failed to parse GTFS-RT %s/%s protobuf: %w", operator, feedType, err)
			log.Printf("%v", lastErr)
			continue
		}

		tagFeedEntities(feed, operator)
		merged.Entity = append(merged.Entity, feed.Entity...)
		if merged.Header == nil {
			merged.Header = feed.Header
		}
	}

	if len(merged.Entity) == 0 && lastErr != nil {
		return nil, lastErr
	}
	return merged, nil
}

// tagFeedEntities präfixiert Entity-, Vehicle- und Trip-IDs mit dem Operator,
// damit der Multi-Operator-Merge deduplizierbar und join-bar bleibt.
func tagFeedEntities(feed *gtfs.FeedMessage, operator string) {
	tag := operator + ":"
	for _, entity := range feed.GetEntity() {
		if entity.GetId() != "" {
			entity.Id = proto.String(tag + entity.GetId())
		}
		if vp := entity.GetVehicle(); vp != nil {
			if v := vp.GetVehicle(); v != nil && v.GetId() != "" {
				v.Id = proto.String(tag + v.GetId())
			}
			if tr := vp.GetTrip(); tr != nil && tr.GetTripId() != "" {
				tr.TripId = proto.String(tag + tr.GetTripId())
			}
		}
		if tu := entity.GetTripUpdate(); tu != nil {
			if v := tu.GetVehicle(); v != nil && v.GetId() != "" {
				v.Id = proto.String(tag + v.GetId())
			}
			if tr := tu.GetTrip(); tr != nil && tr.GetTripId() != "" {
				tr.TripId = proto.String(tag + tr.GetTripId())
			}
		}
	}
}

// fetchVehiclesFromGTFSRT lädt VehiclePositions + TripUpdates (für Verspätungs-
// Anreicherung) und liefert die Fahrzeuge im JSON-Contract der App.
func fetchVehiclesFromGTFSRT() ([]interface{}, error) {
	feed, err := fetchGTFSRTFeed("vehicle-positions")
	if err != nil {
		return nil, err
	}

	delaysFeed, err := fetchGTFSRTFeed("trip-updates")
	if err != nil {
		log.Printf("TripUpdates feed unavailable, skipping delay enrichment: %v", err)
		delaysFeed = &gtfs.FeedMessage{}
	}

	return vehiclesFromFeed(feed, tripDelaysFromFeed(delaysFeed)), nil
}

// vehiclesFromFeed wandelt alle VehiclePosition-Entities einer FeedMessage in
// das App-JSON-Contract um und dedupliziert dabei nach vehicleId (letzter
// Eintrag gewinnt). delaySeconds stammt aus dem TripUpdates-Join.
func vehiclesFromFeed(feed *gtfs.FeedMessage, delays map[string]int32) []interface{} {
	vehicles := []interface{}{}
	index := make(map[string]int)
	for _, entity := range feed.GetEntity() {
		vp := entity.GetVehicle()
		if vp == nil || vp.GetPosition() == nil {
			continue
		}
		delaySeconds, ok := delays[vp.GetTrip().GetTripId()]
		if !ok {
			delaySeconds = 0
		}
		vehicle := transformVehicleToJSON(entity, delaySeconds)

		id := vehicle["vehicleId"].(string)
		if i, exists := index[id]; exists {
			vehicles[i] = vehicle
		} else {
			index[id] = len(vehicles)
			vehicles = append(vehicles, vehicle)
		}
	}
	return vehicles
}

// fetchTripDelays extrahiert tripId -> delaySeconds aus dem TripUpdates-Feed.
// Fehler werden toleriert (leere Map), da die Delay-Anreicherung optional ist.
func fetchTripDelays() map[string]int32 {
	feed, err := fetchGTFSRTFeed("trip-updates")
	if err != nil {
		log.Printf("TripUpdates feed unavailable, skipping delay enrichment: %v", err)
		return map[string]int32{}
	}
	return tripDelaysFromFeed(feed)
}

// tripDelaysFromFeed extrahiert tripId -> delaySeconds aus einer geparsten
// TripUpdates-FeedMessage. Trip-Level-Delay hat Vorrang, sonst wird der erste
// nicht-null StopTimeUpdate-Delay verwendet.
func tripDelaysFromFeed(feed *gtfs.FeedMessage) map[string]int32 {
	delays := make(map[string]int32)
	for _, entity := range feed.GetEntity() {
		tu := entity.GetTripUpdate()
		if tu == nil {
			continue
		}
		tripID := tu.GetTrip().GetTripId()
		if tripID == "" {
			continue
		}
		if d := tu.GetDelay(); d != 0 {
			delays[tripID] = d
			continue
		}
		for _, stu := range tu.GetStopTimeUpdate() {
			if stu.GetArrival() != nil && stu.GetArrival().GetDelay() != 0 {
				delays[tripID] = stu.GetArrival().GetDelay()
				break
			}
			if stu.GetDeparture() != nil && stu.GetDeparture().GetDelay() != 0 {
				delays[tripID] = stu.GetDeparture().GetDelay()
				break
			}
		}
	}
	return delays
}

// fetchTripUpdatesFromGTFSRT liefert alle TripUpdates als JSON-Liste.
func fetchTripUpdatesFromGTFSRT() ([]interface{}, error) {
	feed, err := fetchGTFSRTFeed("trip-updates")
	if err != nil {
		return nil, err
	}

	tripUpdates := []interface{}{}
	for _, entity := range feed.GetEntity() {
		tu := entity.GetTripUpdate()
		if tu == nil {
			continue
		}
		tripUpdates = append(tripUpdates, transformTripUpdateToJSON(entity))
	}
	return tripUpdates, nil
}

// fetchServiceAlertsFromGTFSRT liefert alle Alerts als JSON-Liste.
func fetchServiceAlertsFromGTFSRT() ([]interface{}, error) {
	feed, err := fetchGTFSRTFeed("alerts")
	if err != nil {
		return nil, err
	}

	alerts := []interface{}{}
	for _, entity := range feed.GetEntity() {
		if entity.GetAlert() == nil {
			continue
		}
		alert := transformAlertToJSON(entity.GetAlert())
		if alert != nil {
			alerts = append(alerts, alert)
		}
	}
	return alerts, nil
}

// transformVehicleToJSON mappt eine FeedEntity mit VehiclePosition auf das
// App-Contract. delaySeconds stammt aus dem TripUpdates-Join.
//
// GTFS-RT speed ist m/s → km/h-Umrechnung (*3.6). routePolyline bleibt leer,
// da VehiclePositions keine Shapes enthält (Model hat Defaults).
func transformVehicleToJSON(entity *gtfs.FeedEntity, delaySeconds int32) map[string]interface{} {
	vp := entity.GetVehicle()

	vehicleID := vp.GetVehicle().GetId()
	if vehicleID == "" {
		vehicleID = entity.GetId()
	}

	result := map[string]interface{}{
		"vehicleId":        vehicleID,
		"tripId":           vp.GetTrip().GetTripId(),
		"routeId":          vp.GetTrip().GetRouteId(),
		"line":             vp.GetTrip().GetRouteId(),
		"mode":             "bus",
		"lat":              float64(vp.GetPosition().GetLatitude()),
		"lng":              float64(vp.GetPosition().GetLongitude()),
		"bearing":          float64(vp.GetPosition().GetBearing()),
		"speedKmh":         float64(vp.GetPosition().GetSpeed()) * 3.6,
		"occupancy":        mapOccupancyStatus(vp.GetOccupancyStatus()),
		"nextStopName":     vp.GetStopId(),
		"delayMinutes":     int(delaySeconds / 60),
		"currentStatus":    vp.GetCurrentStatus().String(),
		"routePolyline":    []interface{}{},
		"progressFraction": 0.0,
	}

	if ts := vp.GetTimestamp(); ts > 0 {
		result["lastGpsReport"] = time.Unix(int64(ts), 0).UTC().Format(time.RFC3339)
	}

	return result
}

// mapOccupancyStatus bildet GTFS-RT OccupancyStatus auf die App-Enum ab
// (empty | manySeats | fewSeats | standingRoom | full). Unbekannte Werte
// liefern "" → Flutter-Default manySeats.
func mapOccupancyStatus(status gtfs.VehiclePosition_OccupancyStatus) string {
	switch status {
	case gtfs.VehiclePosition_EMPTY:
		return "empty"
	case gtfs.VehiclePosition_MANY_SEATS_AVAILABLE:
		return "manySeats"
	case gtfs.VehiclePosition_FEW_SEATS_AVAILABLE:
		return "fewSeats"
	case gtfs.VehiclePosition_STANDING_ROOM_ONLY:
		return "standingRoom"
	case gtfs.VehiclePosition_CRUSHED_STANDING_ROOM_ONLY,
		gtfs.VehiclePosition_FULL,
		gtfs.VehiclePosition_NOT_ACCEPTING_PASSENGERS:
		return "full"
	default:
		return ""
	}
}

// transformTripUpdateToJSON liefert die Verspätungsdaten pro Fahrt.
func transformTripUpdateToJSON(entity *gtfs.FeedEntity) map[string]interface{} {
	tu := entity.GetTripUpdate()

	stopTimeUpdates := []interface{}{}
	for _, stu := range tu.GetStopTimeUpdate() {
		s := map[string]interface{}{
			"stopSequence": stu.GetStopSequence(),
			"stopId":       stu.GetStopId(),
		}
		if arrival := stu.GetArrival(); arrival != nil {
			s["arrivalDelaySeconds"] = arrival.GetDelay()
		}
		if departure := stu.GetDeparture(); departure != nil {
			s["departureDelaySeconds"] = departure.GetDelay()
		}
		stopTimeUpdates = append(stopTimeUpdates, s)
	}

	result := map[string]interface{}{
		"tripId":          tu.GetTrip().GetTripId(),
		"routeId":         tu.GetTrip().GetRouteId(),
		"directionId":     tu.GetTrip().GetDirectionId(),
		"vehicleId":       tu.GetVehicle().GetId(),
		"delaySeconds":    tu.GetDelay(),
		"stopTimeUpdates": stopTimeUpdates,
	}

	if ts := tu.GetTimestamp(); ts > 0 {
		result["timestamp"] = time.Unix(int64(ts), 0).UTC().Format(time.RFC3339)
	}

	return result
}

// transformAlertToJSON behält das bisherige JSON-Shape, liest jetzt aber über
// die generierten Getter (korrekte Field-Numbers statt des defekten Hand-Parsers).
func transformAlertToJSON(alert *gtfs.Alert) map[string]interface{} {
	result := make(map[string]interface{})

	if header := firstTranslation(alert.GetHeaderText()); header != "" {
		result["header"] = header
	}
	if description := firstTranslation(alert.GetDescriptionText()); description != "" {
		result["description"] = description
	}
	if url := firstTranslation(alert.GetUrl()); url != "" {
		result["url"] = url
	}

	result["cause"] = gtfs.Alert_Cause_name[int32(alert.GetCause())]
	result["causeCode"] = int32(alert.GetCause())
	result["effect"] = gtfs.Alert_Effect_name[int32(alert.GetEffect())]
	result["effectCode"] = int32(alert.GetEffect())

	informedEntities := []interface{}{}
	for _, entity := range alert.GetInformedEntity() {
		entityMap := map[string]interface{}{
			"agencyId":    entity.GetAgencyId(),
			"routeId":     entity.GetRouteId(),
			"stopId":      entity.GetStopId(),
			"tripId":      entity.GetTrip().GetTripId(),
			"directionId": entity.GetDirectionId(),
		}
		if entity.GetRouteType() != 0 {
			entityMap["routeType"] = entity.GetRouteType()
		}
		informedEntities = append(informedEntities, entityMap)
	}
	result["informedEntities"] = informedEntities

	activePeriods := []interface{}{}
	for _, period := range alert.GetActivePeriod() {
		periodMap := map[string]interface{}{}
		if period.GetStart() > 0 {
			periodMap["start"] = period.GetStart()
			periodMap["startTime"] = time.Unix(int64(period.GetStart()), 0).UTC().Format(time.RFC3339)
		}
		if period.GetEnd() > 0 {
			periodMap["end"] = period.GetEnd()
			periodMap["endTime"] = time.Unix(int64(period.GetEnd()), 0).UTC().Format(time.RFC3339)
		}
		activePeriods = append(activePeriods, periodMap)
	}
	result["activePeriods"] = activePeriods

	return result
}

// firstTranslation liefert den ersten Übersetzungstext (bevorzugt 'sv').
func firstTranslation(ts *gtfs.TranslatedString) string {
	if ts == nil {
		return ""
	}
	first := ""
	for _, t := range ts.GetTranslation() {
		text := t.GetText()
		if text == "" {
			continue
		}
		if first == "" {
			first = text
		}
		if t.GetLanguage() == "sv" {
			return text
		}
	}
	return first
}
