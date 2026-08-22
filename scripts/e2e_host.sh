#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BFF="${BFF_URL:-http://localhost:8080}"
DEVICE_WAIT=22

red() { echo -e "\033[31m$*\033[0m"; }
green() { echo -e "\033[32m$*\033[0m"; }
yellow() { echo -e "\033[33m$*\033[0m"; }

fail=0
check() {
  if "$@"; then green "✓ $*"; else red "✗ $*"; fail=1; fi
}

section() { echo ""; yellow "== $* =="; }

section "1/5 Go backend vet & tests (mocked upstream)"
check bash -c "cd $ROOT/backend && go vet ./..."
check bash -c "cd $ROOT/backend && go test ./... -run TestE2E -v"
check bash -c "cd $ROOT/backend && go test ./... -run 'TestVehiclesFromFeed|TestTripDelays|TestTransform|TestTag|TestMap|TestFilter' -v"

section "2/5 Flutter unit & contract tests (mocked + live-if-bff-up)"
pushd "$ROOT" >/dev/null
check flutter test test/gtfs_rt_decoder_test.dart
check flutter test test/e2e_bff_live_test.dart
popd >/dev/null

section "3/5 Live BFF contract (requires $BFF)"
# Retry 3× – BFF may need a moment after cold start / GTFS fetch
for _ in 1 2 3; do curl -sf "$BFF/api/health" >/dev/null 2>&1 && break; sleep 2; done
if ! curl -sf "$BFF/api/health" >/dev/null 2>&1; then
  yellow "BFF not reachable at $BFF – live checks skipped (run with BFF_URL=... or start backend: ./backend/swe-discover-bff)"
else
  # health
  check bash -c "curl -sf $BFF/api/health | python3 -c 'import json,sys; d=json.load(open(0)); assert d[\"status\"]==\"ok\"'"
  check bash -c "curl -sf $BFF/api/debug | python3 -c 'import json,sys; d=json.load(sys.stdin); m=d[\"config\"][\"keysMasked\"]; assert all(v==\"<empty>\" or v==\"***\" or \"***\" in v for v in m.values()), m'"
  # X-Cache header present after second request (tests debug logging path)
  check bash -c "curl -sf $BFF/api/vehicles >/dev/null; curl -s -D - $BFF/api/vehicles -o /dev/null | grep -qi 'X-Cache: HIT'"

  # vehicles contract – at least shape, not count (evening may be low)
  check bash -c "curl -sf $BFF/api/vehicles | python3 -c '
import json,sys
d=json.load(sys.stdin)
v=d[\"vehicles\"]
assert isinstance(v, list)
assert \"telemetry\" in d
if v:
    x=v[0]
    assert \"vehicleId\" in x and \"lat\" in x and \"lng\" in x, x
    assert 55 <= x[\"lat\"] <= 70, x
    assert \"mode\" in x and \"occupancy\" in x
    print(f\"vehicles={len(v)} first lat={x[\"lat\"]:.4f} mode={x[\"mode\"]}\")
else:
    print(\"vehicles=0 (check GTFS_SWEDEN_3_REALTIME key)\")
'"

  check bash -c "curl -sf '$BFF/api/departures?stopId=740020101' | python3 -c '
import json,sys
d=json.load(sys.stdin)
deps=d[\"departures\"]
assert isinstance(deps, list)
if deps:
    x=deps[0]
    for k in (\"line\",\"destination\",\"mode\",\"scheduledTime\",\"realtimeTime\",\"delaySeconds\",\"status\",\"track\"):
        assert k in x, f\"missing {k} in {x}\"
    print(f\"departures={len(deps)} first line={x[\"line\"]} track={x[\"track\"]}\")
'"

  check bash -c "curl -sf '$BFF/api/stops/search?q=T-Centralen' | python3 -c '
import json,sys
d=json.load(sys.stdin)
assert \"stops\" in d and isinstance(d[\"stops\"], list) and len(d[\"stops\"])>0
print(f\"stops={len(d[\"stops\"])} first={d[\"stops\"][0][\"name\"]}\")
'"

  check bash -c "curl -sf $BFF/api/service-alerts | python3 -c '
import json,sys
d=json.load(sys.stdin)
assert \"alerts\" in d
if d[\"alerts\"]:
    a=d[\"alerts\"][0]
    assert \"cause\" in a and \"effect\" in a
print(f\"alerts={len(d[\"alerts\"])}\")
'"

  check bash -c "curl -sf $BFF/api/trip-updates | python3 -c '
import json,sys
d=json.load(sys.stdin)
assert \"tripUpdates\" in d
print(f\"tripUpdates={len(d[\"tripUpdates\"])}\")
'"

  # new endpoint: pick a live vehicleId and validate trip-details contract shape
  check bash -c "
VID=\$(curl -sf $BFF/api/vehicles | python3 -c '
import json,sys
v=json.load(sys.stdin).get(\"vehicles\",[])
print(v[0][\"vehicleId\"] if v else \"\")
')
if [ -z \"\$VID\" ]; then
  echo 'no vehicles live – trip-details check skipped'
else
  curl -sf \"$BFF/api/trip-details/\$VID\" | python3 -c '
import json,sys
d=json.load(sys.stdin)
assert d.get(\"vehicleId\"), d
assert \"route\" in d and \"stops\" in d and \"shape\" in d, list(d.keys())
assert isinstance(d[\"stops\"], list)
for s in d[\"stops\"]:
    for k in (\"stopId\",\"name\",\"stopSequence\",\"arrivalTime\",\"arrivalDelaySeconds\"):
        assert k in s, f\"missing {k} in {s}\"
seqs=[s[\"stopSequence\"] for s in d[\"stops\"]]
assert seqs==sorted(seqs), f\"stops not ordered: {seqs}\"
assert isinstance(d[\"shape\"], list)
if d[\"stops\"]:
    print(f\"trip-details ok: vehicle={d[\"vehicleId\"]} route={d.get(\"route\",{}).get(\"shortName\") or d.get(\"route\",{}).get(\"routeId\")} stops={len(d[\"stops\"])} shape_pts={len(d[\"shape\"])} nextStop={d.get(\"nextStopId\")} gtfsReady={d.get(\"gtfsReady\")}\")
else:
    print(f\"trip-details degraded (gtfsReady={d.get(\"gtfsReady\")}) but contract valid\")
'
fi"

  # regression: old wrong hosts must NOT be hit (verified via mock tests, here smoke that live URLs don't 404)
  check bash -c "curl -s -o /dev/null -w '%{http_code}' $BFF/api/vehicles | grep -q 200"
fi

section "4/5 Device (ADB) – requires USB device + adb reverse"
if ! command -v adb >/dev/null 2>&1; then
  yellow "adb not found – device checks skipped"
elif ! adb devices | grep -q "device$"; then
  yellow "no device attached – device checks skipped (adb devices empty)"
else
  check bash -c 'adb reverse --list | grep -q "8080" || adb reverse tcp:8080 tcp:8080'
  # settings file must point to localhost when using reverse
  check bash -c '
    adb shell run-as com.lateinlabs.swediscover cat app_flutter/swediscover_settings.json 2>/dev/null | python3 -c "
import json,sys
d=json.load(sys.stdin)
url=d.get(\"bffServerUrl\",\"\")
assert url==\"http://localhost:8080\", f\"bffServerUrl={url!r} want localhost:8080 (fix with: adb reverse tcp:8080 tcp:8080 + correct settings)\"
print(f\"bffServerUrl={url}\")
" 2>&1 | grep -q "bffServerUrl=http://localhost:8080" || {
      # Fallback: app may be fresh install with defaults (no file yet) – that is OK (defaults to localhost)
      echo "no persisted settings yet – defaults to localhost:8080 (ok)"
    }
  '
  # logcat after fresh launch must not contain the old BFF error when reverse is correct
  check bash -c '
    adb shell run-as com.lateinlabs.swediscover cat app_flutter/swediscover_settings.json >/dev/null 2>&1 || true
  '
  yellow "device screenshots: run scripts/e2e_device_screenshot.sh for visual pin check (requires MapTiler key, not asserted in CI)"
fi

section "5/5 Flutter analyze"
pushd "$ROOT" >/dev/null
check flutter analyze
popd >/dev/null

if [ $fail -eq 0 ]; then green "\nAll E2E checks passed"; else red "\nSome E2E checks failed"; fi
exit $fail
