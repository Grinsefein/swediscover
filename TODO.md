# TODO

## 1. GTFS static import fails with HTTP 404

- **Where:** `lib/data/gtfs_importer.dart:18` (`importFromTrafiklab`)
- **Symptom:** Device log shows `Fehler beim GTFS-Import: Exception: GTFS-Download fehlgeschlagen: HTTP 404` → stop database stays empty → departure monitor falls back to the "GTFS-importen körs troligen" hint.
- **Cause:** The download URL `https://api.trafiklab.se/gtfs-sweden-3/gtfs.zip` does not exist (404).
- **Fix:** Look up the correct GTFS Sweden 3 static download URL in the Trafiklab docs/dashboard and update the URL. Check whether the API key must be sent as `Authorization: Bearer <key>` header or query param for that endpoint.
- **Verify:** After fix, app start should log `GTFS-Import erfolgreich abgeschlossen.` and searching a stop (e.g. T-Centralen `740000001`) in the departure monitor must work offline from the local DB.

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
