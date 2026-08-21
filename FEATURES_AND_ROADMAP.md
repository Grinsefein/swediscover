# SweDiscover - Features & Roadmap to Super Powerful App

## ✅ Implemented Features

### 1. Real-time Public Transport Data
- **Go BFF Server** (`/workspace/go-bff/`): Lightweight backend proxying Trafiklab APIs
  - `/api/departures` - Real-time departure boards
  - `/api/arrivals` - Real-time arrival boards  
  - `/api/stops/search` - Stop lookup by name
  - Caching, CORS support, telemetry
  - Uses your TRAFIKLAB_API_KEY from .env

- **Hybrid Architecture**: Flutter app can fetch data via:
  - BFF server (recommended for production)
  - Direct API calls (offline-first capability)

### 2. Android Logcat Streaming (NEW!)
- **Automatic logging**: MainActivity.kt streams all logcat output to `/data/data/com.lateinlabs.swediscover/files/logcat.log`
- **Git-tracked log file**: `/workspace/logs/logcat.log` (excluded from .gitignore exceptions)
- **Pull script**: `./scripts/pull_logcat.sh` to retrieve logs from device
- **Timestamps**: All logs include session start/stop markers with timestamps

### 3. Core App Features
- Live map view with vehicle positions
- Departure monitors
- Train composition inspector
- Traffic cameras integration
- Multi-language support (Swedish/English)
- Material 3 Expressive theme
- Dark/Light mode toggle

## 🚀 What's Missing to Become SUPER Powerful

### High Priority (Must-Have)

#### 1. **Offline-First Architecture**
- [ ] Implement Hive or Isar for local caching
- [ ] Cache GTFS static data (stops, routes, trips)
- [ ] Queue API requests when offline
- [ ] Background sync service
- [ ] Smart cache invalidation strategies

#### 2. **Advanced Real-time Features**
- [ ] Push notifications for delays/cancellations
- [ ] Personalized alerts for favorite stops/lines
- [ ] Crowding predictions
- [ ] Connection protection (wait for delayed connections)
- [ ] Multi-modal journey planning with real-time updates

#### 3. **Performance Optimization**
- [ ] Image caching and lazy loading
- [ ] Pagination for large lists
- [ ] WebSocket connections for live updates (instead of polling)
- [ ] Background isolates for heavy computations
- [ ] Memory leak detection and fixes

#### 4. **User Experience Enhancements**
- [ ] Onboarding flow for first-time users
- [ ] Tutorial overlays for complex features
- [ ] Haptic feedback for interactions
- [ ] Smooth animations and transitions
- [ ] Accessibility improvements (TalkBack, font scaling)

### Medium Priority (Should-Have)

#### 5. **Analytics & Telemetry**
- [ ] Privacy-focused analytics (no Google Analytics)
- [ ] Crash reporting (Sentry or similar)
- [ ] Performance monitoring
- [ ] User behavior insights (opt-in)
- [ ] A/B testing framework

#### 6. **Social & Community Features**
- [ ] Share trip plans
- [ ] User-reported incidents (crowdsourced delays)
- [ ] Favorite places sharing
- [ ] Social proof (how many people use this stop)

#### 7. **Advanced Search & Discovery**
- [ ] Voice search for stops/destinations
- [ ] Natural language queries ("next train to Stockholm")
- [ ] Predictive search based on history
- [ ] Nearby POI discovery
- [ ] Event-based routing (concerts, sports)

#### 8. **Integration Ecosystem**
- [ ] Calendar integration (auto-suggest departure times)
- [ ] Weather API integration
- [ ] Ticket purchasing (Swip, SL app integration)
- [ ] Bike-sharing availability
- [ ] Parking space availability

### Lower Priority (Nice-to-Have)

#### 9. **AI/ML Features**
- [ ] Personalized recommendations
- [ ] Anomaly detection in traffic patterns
- [ ] Predictive delay modeling
- [ ] Smart home screen widgets
- [ ] Context-aware suggestions

#### 10. **Monetization (Optional)**
- [ ] Premium features (ad-free, advanced analytics)
- [ ] Business API access
- [ ] White-label solutions for municipalities
- [ ] Sponsored POIs

#### 11. **Platform Expansion**
- [ ] Wear OS app
- [ ] CarPlay/Android Auto
- [ ] Web progressive web app (PWA)
- [ ] Desktop apps (Windows/macOS/Linux)
- [ ] Smartwatch complications

## 📊 Testing & Quality

### Current Testing Setup
- [ ] Unit tests for repositories
- [ ] Widget tests for key screens
- [ ] Integration tests for API calls
- [ ] End-to-end tests with real devices

### Needed Testing Improvements
- [ ] Golden tests for UI consistency
- [ ] Performance benchmarks
- [ ] Accessibility audits
- [ ] Security penetration testing
- [ ] Load testing for BFF server

## 🔒 Security Checklist
- [x] API keys in .env (not committed)
- [ ] Certificate pinning for API calls
- [ ] Encrypted local storage
- [ ] Biometric authentication option
- [ ] GDPR compliance audit
- [ ] Privacy policy implementation
- [ ] Data retention policies

## 📱 Platform-Specific Enhancements

### Android
- [x] Logcat streaming implemented
- [ ] Background location services
- [ ] Foreground service for continuous updates
- [ ] App shortcuts
- [ ] Dynamic app icon badges
- [ ] Split APKs for smaller downloads

### iOS
- [ ] Background app refresh
- [ ] Siri shortcuts
- [ ] Live Activities (iOS 16+)
- [ ] Widgets
- [ ] CarPlay support

## 🛠 Developer Experience
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Automated releases
- [ ] Code coverage reports
- [ ] Documentation site
- [ ] Contributing guidelines
- [ ] Issue templates
- [ ] PR templates

## 📈 Success Metrics
Define KPIs:
- Daily Active Users (DAU)
- Session duration
- Retention rate (D1, D7, D30)
- Crash-free sessions
- API response times
- User satisfaction (NPS)

---

## Quick Start Commands

### Start Go BFF Server
```bash
cd /workspace/go-bff
./server
# Or: go run main.go
```

### Pull Logcat Logs
```bash
./scripts/pull_logcat.sh
```

### View Logs
```bash
tail -f /workspace/logs/logcat.log
```

### Run Flutter App
```bash
flutter run
```

### Test API Endpoints
```bash
curl http://localhost:8080/api/departures?stopId=740000002
curl http://localhost:8080/api/stops/search?query=stockholm
```

---

**Next Steps**: Prioritize features based on user feedback and business goals. Start with offline-first architecture and performance optimizations for immediate impact.
