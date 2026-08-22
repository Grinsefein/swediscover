# TODO

## 1. GTFS static import fails with HTTP 404 — *in progress (backend bootstrap)*

- **Where:** `lib/data/gtfs_importer.dart:18` (`importFromTrafiklab`) + new `backend/gtfs_static.go`
- **Symptom:** Device log shows `Fehler beim GTFS-Import: Exception: GTFS-Download fehlgeschlagen: HTTP 404` → stop database stays empty → departure monitor falls back to the "GTFS-importen körs troligen" hint.
- **Cause:** The download URL `https://api.trafiklab.se/gtfs-sweden-3/gtfs.zip` does not exist (404). Correct URL per `gtfsSwedenStatic.yaml` (Trafiklab) is `https://opendata.samtrafiken.se/gtfs-sweden/sweden.zip?key=GTFS_SWEDEN_3_STATIC` (server `opendata.samtrafiken.se`, query `?key=`, requires `Accept-Encoding: gzip`). The zip is 637 MB download, 3.1 GB unpacked (`stop_times.txt` 663 MB, `shapes.txt` 2.4 GB) — too large for on-device streaming; backend now hosts the static data.
- **Fix (new architecture):**
  - `GtfsImporter.importFromTrafiklab` URL + auth fixed to the correct endpoint (`?key=` not `Authorization: Bearer`).
  - **New backend module** `backend/gtfs_static.go`: keeps only `sweden.zip` (637 MB) on disk in `backend/data/gtfs/` (no full extraction), eager-indiziert `stops`/`routes`/`trips` beim Start, lazy LRU-Scans für `stop_times`/`shapes` pro `tripId`. Liefert `/api/trip-details/{vehicleId}`.
  - Legacy `lib/data/gtfs_importer.dart` bleibt für offline-DB bestehen, wird aber nicht mehr für die Kartenauswahl benötigt.
- **Verify:** `backend/data/gtfs/sweden.zip` existiert; `curl /api/trip-details/<vehicleId>` liefert `stops[]` mit Namen/Lat/Lng und `shape` Polyline; App-Log `GTFS-Import erfolgreich…` entfällt für die Kartenfunktion.

## 2. Phone cannot reach Go BFF at http://192.168.178.180:8080

- **Where:** Runtime/network environment (not an app bug); BFF URL is configured in Settings / persisted in `swediscover_settings.json` on the device.
- **Symptom:** `Connection timed out ... address = 192.168.178.180, port = 8080` from the phone, while the server (`swe-discover-ba`) is up and listening on `*:8080` on the host (`192.168.178.180`). App now shows "BFF-servern är inte nåbar på …" instead of a raw timeout.
- **Checklist:**
  - [ ] Phone and host on the same WiFi/VLAN (not mobile data or guest network with client isolation)
  - [ ] Host firewall allows inbound TCP 8080 from LAN (e.g. `sudo ufw allow 8080/tcp`)
  - [ ] Server actually running when testing (`ss -tlnp | grep 8080`)
  - [ ] Test from phone browser: open `http://192.168.178.180:8080/api/vehicles`
- **Fallback:** If LAN access can't be fixed, run the BFF via `adb reverse tcp:8080 tcp:8080` and set the BFF URL in Settings to `http://localhost:8080`.

## 3. Explicitly deferred (out of scope for the GTFS-RT pipeline fix)

These were identified during the 2026-08 review but deliberately **not** part of the
VehiclePositions/TripUpdates pipeline rework. Do them as separate tasks:

- [ ] **CORS middleware in Go backend** (`backend/main.go`): Flutter Web in proxy mode needs `Access-Control-Allow-Origin` headers; currently no CORS handling at all.
- [ ] **Rate limiting**: no throttling on any endpoint — anyone knowing the proxy URL can drain the Trafiklab/Trafikverket quotas.
- [ ] **WebSocket origin check**: `upgrader.CheckOrigin` accepts every origin (`backend/main.go:62`, marked "für Development").
- [ ] **`isBridgeActive` hardcoded `false`** (`transformCameraData`, `backend/main.go`): join camera ↔ bridge situations from the already-existing `/api/situations`.
- [ ] **Conditional HTTP requests for ServiceAlerts**: GTFS-RT feeds change rarely; use ETag / `If-Modified-Since` per Trafiklab recommendation instead of refetching on every request.
- [ ] **`dart:io` without conditional imports** (#3 from review): `app_settings_service.dart`, `trafikverket_service.dart`, `resrobot_journey_service.dart` import `dart:io` directly → breaks Flutter Web builds. Wrap behind `kIsWeb` + conditional imports.
- [ ] **Encrypted local storage for API keys**: keys stored as plaintext JSON (`swediscover_settings.json`), already on the roadmap ("Encrypted local storage").
- [ ] **Caching for uncached endpoints**: only departures + vehicles are cached server-side; stops search, trip details, cameras, alerts, situations, journey planning hit upstream every time.
- [ ] **Onboarding / first-run assistant**: Direct/Proxy mode switch, API keys and server URL currently hidden in settings; high entry barrier for new users.
- [ ] **Departure-board enrichment from TripUpdates**: `/api/trip-updates` exists after the pipeline fix, but per-stop real-time delays still need stop-matching logic before they can feed the departure monitor.

## 4. Vehicle selection: route, stops, realtime position + map UI polish — *active*

- **Goal:** Tap auf ein Fahrzeug → Route, Haltestellen und sekündlich aktualisierte Echtzeit-Position anzeigen; Karten-UI mit echten Symbolen und benutzerfreundlicher.
- **Backend:**
  - [ ] `backend/gtfs_static.go` — Bootstrap (download `sweden.zip` once → `backend/data/gtfs/`), eager `stops`/`routes`/`trips` indexes, lazy LRU für `stop_times`/`shapes`, expose `GET /api/trip-details/{vehicleId}` (vehicle snapshot + route `{shortName,longName,type}` + `tripHeadsign` + `stops[]` `{stopId,name,lat,lng,seq,arrivalTime,departureTime,arrivalDelay,departureDelay}` + `shape` `[[lat,lng],…]` downsample ≤300 + `currentStopSequence`/`currentStatus`/`nextStopId`).
  - [ ] `backend/main.go` — Route registrieren, Handler `handleTripDetailsByVehicle`, LRU, Fehler Degradation (Trip ohne static → nur RT-delays + stopIds).
  - [ ] Tests: `backend/gtfs_static_test.go`, Handler-Test mit mock zip.
- **App:**
  - [ ] `lib/models/vehicle_trip_model.dart` + `lib/services/vehicle_trip_service.dart` — BFF-Client für `trip-details`.
  - [ ] `lib/views/live_map_view.dart` — Tap (`_selectNearest`) → `_loadSelectedDetails(vehicle)` (loading spinner), Line+Stop-Marker zeichnen (`addLine`/`addCircle`), Bottom-Sheet mit Header (Linie-Badge + headsign + occupancy), Metrik-Row, scrollbare Stop-Liste (Vergangen/Aktuell/Nächste mit Delays hervorgehoben), Auto-Refresh der selektierten Position alle 10–15 s.
  - [ ] `lib/views/live_map_view.dart` — Echte Symbole: Canvas-Pins mit Modus-Glyph (MaterialIcons: `directions_bus`/`train`/`tram`/`subway`/`directions_boat`) via `TextPainter`/FontLoader, `iconRotate: bearing`, selektiert vergrößert + weißer Halo.
  - [ ] Periodischer Vehicle-Fetch (15 s = BFF cacheTTL) + selektierte Details-Refresh; `kIsWeb`-safe.
- **Verify:**
  - [ ] `curl /api/trip-details/<vehicleId>` liefert `stops[].name` und `shape.length > 0`.
  - [ ] App: Tap auf Bus in Stockholm → Polyline sichtbar, Stop-Liste scrollt, aktueller Halt farbig, Position wandert alle 10 s; Icons zeigen Bus/Tram/etc. und drehen mit Fahrtrichtung; selektiertes Fahrzeug hebt sich ab; Kamera folgt optional; Fehler-Leer-Zustand verständlich; `flutter analyze`/`go vet` grün, `flutter test` + `go test` grün, APK Screenshot: dichte Pin-Cluster als überlappende kleine Pins sichtbar, nicht riesig.
