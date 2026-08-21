# Archived Backend Implementations

Dieser Ordner enthält alte Backend-Implementierungen, die nicht mehr aktiv verwendet werden.

## Hintergrund

Das Projekt hatte ursprünglich drei parallele Backend-for-Frontend (BFF) Implementierungen:

1. **backend/** (Go) - Einfache HTTP-API für Departures und Vehicles
2. **go-bff/** (Go) - Erweiterte Go-Implementierung mit Arrivals und Stop-Suche
3. **bff/** (Dart/Shelf) - Vollständige Dart-Implementierung mit GTFS-RT-Protobuf-Parsing und WebSocket-Support

## Entscheidung

Nach Evaluierung aller drei Implementierungen wurde die **Dart/Shelf-Implementierung** (`backend/`, ehemals `bff/`) als alleiniges Production-Backend ausgewählt, da sie:

- ✅ Echtes GTFS-RT-Protobuf-Parsing unterstützt
- ✅ WebSocket-Streaming für Live-Vehicle-Positions bietet
- ✅ Request-Collapsing und Telemetrie integriert hat
- ✅ Konsistent mit der Flutter-App im gleichen Tech-Stack ist
- ✅ Bereits alle notwendigen Trafiklab-API-Integrationen enthält

Die Go-Implementierungen wurden archiviert, falls Referenzcode benötigt wird.

## Verwendung des aktiven Backends

Das aktive Backend befindet sich im `/backend`-Verzeichnis:

```bash
cd backend
cp .env.example .env
# API-Keys in .env eintragen
dart pub get
dart run bin/server.dart
```

Die Flutter-App verbindet sich standardmäßig mit `http://localhost:8080` (oder über `BFF_URL` Environment-Variable konfigurierbar).
