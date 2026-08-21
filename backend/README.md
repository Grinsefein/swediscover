# SweDiscover Backend (Go)

## Setup

### Umgebungsvariablen setzen

Erstelle eine `.env` Datei im Backend-Verzeichnis:

```bash
TRAFIKLAB_API_KEY=dein_api_key
TRAFIKLAB_GTFS_RT_KEY=dein_gtfs_rt_key
TRAFIKLAB_GTFS_STATIC_KEY=dein_gtfs_static_key
TRAFIKLAB_STOPS_KEY=dein_stops_key
TRAFIKLAB_RESROBOT_KEY=dein_resrobot_key
TRAFIKVERKET_API_KEY=dein_trafikverket_key
SERVER_PORT=8080
```

**Wichtig:** API-Keys niemals im Code oder Git commiten!

### Dependencies installieren

```bash
cd backend
go mod tidy
```

### Server starten

```bash
go run main.go
```

Der Server startet auf `http://localhost:8080`.

## API Endpunkte

| Methode | Pfad | Beschreibung |
|---------|------|-------------|
| GET | `/api/departures?stopId={id}` | Abfahrten an einer Haltestelle |
| GET | `/api/vehicles` | Aktuelle Fahrzeugpositionen |
| GET | `/api/stops/search?q={query}` | Haltestellensuche |
| GET | `/api/trip/{tripId}?date={YYYY-MM-DD}` | Trip-Details mit Zugkomposition |
| GET | `/api/cameras` | Verkehrskameras |
| GET | `/api/service-alerts` | Störungsmeldungen |
| WS | `/ws?broadcast=vehicles&minLat=&minLng=&maxLat=&maxLng=` | WebSocket für Live-Fahrzeugupdates |

## Request-Collapsing

Der Server implementiert Request-Collapsing für `/api/departures` und `/api/vehicles`:
- Antworten werden für 15 Sekunden gecached
- Parallele Requests während der Cache-TTL werden bedient ohne upstream API calls
- Telemetrie-Metriken zeigen die Einsparungen

## Telemetrie

Jede API-Antwort enthält Metriken:

```json
{
  "departures": [...],
  "telemetry": {
    "totalClientRequests": 42,
    "upstreamCallsMade": 3,
    "collapsedRequests": 39,
    "networkSavingsPercent": 92.8,
    "activeVehiclesInSweden": 1250,
    "activeVehiclesInViewport": 85
  }
}
```

## WebSocket

Der WebSocket sendet alle 5 Sekunden aktualisierte Fahrzeugpositionen:

```json
{
  "type": "vehicles",
  "items": [...],
  "timestamp": 1699876543
}
```

Optional kann eine Bounding-Box über Query-Parameter mitgegeben werden, um nur Fahrzeuge im sichtbaren Bereich zu erhalten.

## Production Deployment

- API-Keys über Environment Variables oder Secret Manager injizieren
- WebSocket CheckOrigin restriktiver konfigurieren
- HTTPS über Reverse Proxy (nginx, traefik) terminieren
- Health-Check Endpunkt hinzufügen
- Prometheus-Metriken exportieren
