# SweDiscover

SweDiscover ist eine Flutter-App für Echtzeit-Verkehrsdaten in Schweden. Sie kombiniert live Verkehrsinformationen, Zugdetails, Haltestellen, Karten und Verkehrskameras mit einem Go-Backend als Proxy-Schicht.

## Überblick

- Flutter Frontend für Android, Linux, Web, etc.
- Go Backend als BFF/Proxy für API-Keys und Logik
- Direktmodus für mobile API-Zugriffe
- Proxy-Modus über eigenes Go-Backend
- GTFS-Import und lokale Stop-/Datenbanklogik
- Live-Funktionen für Abfahrten, Fahrzeugpositionen und Verkehrsinformationen

## Repository-Struktur

- `lib/` – Flutter-App
- `backend/` – Go-Backend und API-Proxy
- `android/` – Android-Native Build
- `assets/` – geladene Konfigurationsdateien
- `test/` – Flutter-Tests

## Voraussetzungen

- Flutter SDK
- Go 1.23+ (für das Backend)
- Android SDK / Android-Gerät oder Emulator
- Access-Keys für Trafiklab / Trafikverket / ggf. ResRobot

## Schnellstart

### 1) Go-Backend starten

```bash
cd backend
# .env erzeugen, falls noch nicht vorhanden
# siehe backend/.env.example oder backend/.env

/run/host/usr/lib/go-1.26/bin/go run .
```

Oder mit deiner lokalen Go-Installation, falls vorhanden:

```bash
cd backend
go run .
```

Das Backend läuft standardmäßig auf Port `8080`.

### 2) Flutter App starten

```bash
cd ..
flutter pub get
flutter run
```

Für ein echtes Android-Gerät mit lokalem Proxy:

```bash
flutter run \
  --dart-define=Server_URL=http://192.168.178.180:8080
```

## Konfiguration

### App-Settings

Die App liest Konfiguration aus mehreren Quellen in dieser Reihenfolge:

1. gespeicherte Werte in der App
2. `--dart-define` / Dart-Umgebungswerte
3. Plattform-Umgebungsvariablen
4. mitgelieferte Asset-Datei `assets/config/app.env`
5. lokale .env-Dateien im Projekt oder Backend-Verzeichnis

Die wichtigsten Keys sind:

- `TRAFIKLAB_API_KEY`
- `TRAFIKVERKET_API_KEY`
- `GTFS_SWEDEN_3_REALTIME`
- `GTFS_SWEDEN_3_STATIC`
- `STOPS`
- `RES_ROBOT_V2_1`
- `MAP_TILER_API_KEY`
- `Server_URL`

### Beispiel-Asset-Datei

Datei: `assets/config/app.env`

```env
TRAFIKLAB_API_KEY=dein_key
TRAFIKVERKET_API_KEY=dein_key
GTFS_SWEDEN_3_REALTIME=dein_key
GTFS_SWEDEN_3_STATIC=dein_key
STOPS=dein_key
RES_ROBOT_V2_1=dein_key
MAP_TILER_API_KEY=dein_key
SERVER_PORT=8080
```

### Backend `.env`

Datei: `backend/.env`

```env
TRAFIKLAB_API_KEY=...
TRAFIKVERKET_API_KEY=...
GTFS_SWEDEN_3_REALTIME=...
GTFS_SWEDEN_3_STATIC=...
STOPS=...
RES_ROBOT_V2_1=...
MAP_TILER_API_KEY=...
SERVER_PORT=8080
```

## Direct vs Proxy mode

Die App kann zwischen zwei Modi wechseln:

### Direct mode

- App ruft APIs direkt von Trafiklab / Trafikverket auf
- einfach für lokale Entwicklung
- aber fehleranfälliger bei Zertifikats-/Firewall-/Netzwerk-Problemen

### Proxy mode

- App spricht nur das lokale Go-Backend an
- API-Keys bleiben auf dem Server
- besser für echte Geräte-Tests und Produktion

Im Settings-Dialog kann die Server-URL angepasst werden. Typische Werte:

- Android Emulator: `http://10.0.2.2:8080`
- lokaler Host: `http://localhost:8080`
- echtes Handy im selben LAN: `http://192.168.178.180:8080`

## Live-Checks

### Backend lokal prüfen

```bash
curl http://localhost:8080/api/vehicles
```

### Auf Android-Gerät via LAN prüfen

```bash
adb shell curl http://192.168.178.180:8080/api/vehicles
```

### ADB reverse tunnel (falls nötig)

```bash
adb reverse tcp:8080 tcp:8080
adb shell curl http://127.0.0.1:8080/api/vehicles
```

## Wichtige Hinweise

- Wenn `GTFS_SWEDEN_3_STATIC` fehlt, kann kein lokaler GTFS-Import laufen.
- Wenn der direkte Trafikverket-Call ein Zertifikatsproblem zeigt, nutze den Go-Proxy-Modus.
- Wenn `localhost` im Handy nicht funktioniert, setze die echte Host-IP wie `192.168.178.180`.
- Die App verwendet leere Zustände statt eines Crashes, wenn eine Standard-Haltestelle nicht existiert.

## Tests

```bash
flutter test test/app_settings_and_proxy_test.dart
```

Oder für Analyse:

```bash
flutter analyze
```

## Troubleshooting

### Flutter App startet nicht

```bash
flutter pub get
flutter clean
flutter run
```

### Keine Daten im Frontend

- prüfe `backend/.env`
- prüfe Proxy-URL in den Einstellungen
- prüfe, ob der Go-Server auf Port 8080 läuft
- prüfe, ob GTFS-Import ausgeführt wurde

### 404 oder 500 im Backend

- prüfe vorhandene API-Keys in `backend/.env`
- prüfe, ob der Upstream-Endpunkt noch aktiv ist
- prüfe Logs des Go-Backends

## Lizenz

Dieses Projekt ist für lokale Entwicklung und prototypische Nutzung gedacht.

## Kontakt / Weiterentwicklung

- Backend-Proxylayer: `backend/`
- App-Logik: `lib/`
- UI: `lib/views/`
- Settings und API-Key-Verwaltung: `lib/services/app_settings_service.dart`
