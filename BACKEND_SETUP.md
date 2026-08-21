# Backend-Setup für SweDiscover

## Übersicht

Dieses Projekt verwendet ein **einziges Backend-for-Frontend (BFF)** in Dart/Shelf, das im `/backend`-Verzeichnis liegt. Das Backend kümmert sich um alle externen API-Aufrufe (Trafiklab, Trafikverket) und stellt der Flutter-App eine vereinheitlichte Schnittstelle bereit.

## Architektur

```
┌─────────────────┐      ┌──────────────────┐      ┌─────────────────────┐
│  Flutter App    │ ◄──► │  BFF (Dart)      │ ◄──► │  Trafiklab APIs     │
│  (Frontend)     │      │  /backend        │      │  - ResRobot         │
│                 │      │                  │      │  - GTFS-RT          │
│                 │      │  - HTTP REST     │      │  - Stops            │
│                 │      │  - WebSocket     │      │                     │
│                 │      │  - GTFS-RT Parse │      │  Trafikverket       │
│                 │      │  - Request Cache │      │  - Traffic Cameras  │
└─────────────────┘      └──────────────────┘      │  - Road Situations  │
                                                   └─────────────────────┘
```

## Quickstart

### 1. Backend konfigurieren

```bash
cd backend
cp .env.example .env
```

Öffne `.env` und trage deine API-Keys ein (von https://www.trafiklab.se/):

```env
RESROBOT_API_KEY=dein_resrobot_key
STOPS_API_KEY=dein_stops_key
GTFS_RT_API_KEY=dein_gtfs_rt_key
GTFS_STATIC_API_KEY=dein_gtfs_static_key
```

### 2. Backend starten

```bash
cd backend
dart pub get
dart run bin/server.dart
```

Das Backend läuft nun auf `http://localhost:8080`.

**Verfügbare Endpunkte:**
- `GET /health` - Health Check
- `GET /api/departures?stopId=740000002` - Abfahrten an einer Haltestelle
- `GET /api/vehicles` - Aktuelle Fahrzeugpositionen
- `WS /ws?broadcast=vehicles&bbox=...` - WebSocket für Live-Updates

### 3. Flutter App verbinden

Die App verbindet sich standardmäßig mit `http://localhost:8080`.

**Für Android Emulator:**
```bash
flutter run --dart-define=BFF_URL=http://10.0.2.2:8080
```

**Für iOS Simulator/Web/Desktop:**
```bash
flutter run --dart-define=BFF_URL=http://localhost:8080
```

**Für Produktion:**
```bash
flutter run --dart-define=BFF_URL=https://your-backend-domain.com
```

## Features des Backends

### ✅ Implementiert

- **Abfahrtsdaten** via ResRobot API v2.1
- **Fahrzeugpositionen** via GTFS-RT Protobuf-Parsing
- **WebSocket-Streaming** für Echtzeit-Updates
- **Request-Collapsing** zur Reduzierung von API-Calls
- **Telemetrie** (Client Requests, Upstream Calls, Network Savings)
- **CORS** für Browser-Clients

### 🔧 Konfiguration

| Umgebungsvariable | Beschreibung | Default |
|------------------|--------------|---------|
| `RESROBOT_API_KEY` | Trafiklab ResRobot API Key | ❌ Erforderlich |
| `STOPS_API_KEY` | Trafiklab Stops API Key | ❌ Erforderlich |
| `GTFS_RT_API_KEY` | Trafiklab GTFS-RT API Key | ❌ Erforderlich |
| `GTFS_STATIC_API_KEY` | GTFS Static API Key (für Import) | Optional |
| `BFF_HOST` | Server Host | `0.0.0.0` |
| `BFF_PORT` | Server Port | `8080` |
| `GTFS_RT_OPERATORS` | Komma-separierte Liste (sl,vasttrafik,skanetrafiken,xt) | Alle |
| `GTFS_RT_POLL_SECONDS` | Polling-Intervall für GTFS-RT | `30` |
| `BROADCAST_MS` | WebSocket Broadcast Intervall | `500` |
| `COLLAPSE_WINDOW_MS` | Request Collapse Fenster | `1500` |

## Fehlerbehebung

### Backend startet nicht

```
API-Keys fehlen. Bitte setzen Sie folgende Umgebungsvariablen:
  RESROBOT_API_KEY
  STOPS_API_KEY
  GTFS_RT_API_KEY
```

→ Stelle sicher, dass die `.env`-Datei im `/backend`-Verzeichnis liegt und alle Keys enthält.

### App kann keine Verbindung herstellen

- **Android Emulator**: Verwende `http://10.0.2.2:8080` statt `localhost`
- **iOS Simulator**: Verwende `http://localhost:8080`
- **Web**: CORS-Probleme prüfen, ggf. Backend mit `--cors-origin` starten

### Keine Fahrzeugpositionen sichtbar

- GTFS-RT-API-Key muss gültig sein
- Bounding-Box-Filter prüfen (ggf. deaktivieren in den Einstellungen)
- Backend-Logs prüfen: `dart run bin/server.dart` zeigt Polling-Status

## API-Keys beziehen

Alle API-Keys sind kostenlos bei Trafiklab erhältlich:

1. Registrieren auf https://www.trafiklab.se/
2. Projekt erstellen
3. Gewünschte APIs aktivieren (ResRobot, GTFS-RT, Stops)
4. Keys kopieren und in `.env` einfügen

## Repository History bereinigen

⚠️ **WICHTIG**: Falls du mit einem alten Fork arbeitst, könnten noch alte API-Keys in der Git-History sein. Bereinige diese mit:

```bash
# Installiere git-filter-repo
pip install git-filter-repo

# Entferne hartkodierte Keys aus der History
git filter-repo --replace-text <(echo "782db852-05b4-43d0-b79d-a10518de9caa==>REDACTED")
git filter-repo --replace-text <(echo "0fa5304a78e54f53b9b95b2bbd3d9572==>REDACTED")
git filter-repo --replace-text <(echo "5b4203043a8547c5a95259d0a0687914==>REDACTED")
git filter-repo --replace-text <(echo "223e1d41da1d431d91ad28efba929ac5==>REDACTED")

# Force push (Vorsicht: rewrite History!)
git push --force --all
```

Alternativ das Repo neu klonen nach dem Cleanup.

## Archive

Alte Go-Backend-Implementierungen befinden sich im `/archive`-Ordner. Diese werden nicht mehr verwendet, dienen aber als Referenz.
