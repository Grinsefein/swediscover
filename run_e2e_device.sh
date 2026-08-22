#!/usr/bin/env bash
# Führt den Trip-Details-E2E-Test auf einem echten Gerät aus.
#
# Problem: tester.tap (synthetische Events) erreicht onMapClick der nativen
# MapLibre Platform-View auf manchen Geräten nicht. Dieses Skript injiziert
# daher zusätzlich echte System-Gesten (adb shell input tap), sobald der
# Test den Marker READY_FOR_TAP in Logcat schreibt.
#
# Voraussetzungen:
#   - Gerät via adb verbunden & entsperrt
#   - Go-BFF läuft auf localhost:8080
#   - GTFS-Static-Daten im Backend vorhanden
set -euo pipefail

DEV="${1:-}"
if [ -z "$DEV" ]; then
  DEV=$(adb devices | awk 'NR==2{print $1}')
fi
echo "device: $DEV"

adb -s "$DEV" reverse tcp:8080 tcp:8080
adb -s "$DEV" shell svc power stayon true

flutter test integration_test/trip_details_e2e_test.dart -d "$DEV" &
TEST_PID=$!
trap 'kill $TEST_PID 2>/dev/null || true' EXIT

# Auf READY_FOR_TAP-Marker warten (Test bootet App + lädt Fahrzeuge).
adb -s "$DEV" logcat -c
READY=0
for _ in $(seq 1 150); do
  if adb -s "$DEV" logcat -d -s flutter 2>/dev/null | grep -q 'READY_FOR_TAP'; then
    READY=1
    break
  fi
  if ! kill -0 "$TEST_PID" 2>/dev/null; then
    echo "test process exited before READY marker"
    break
  fi
  sleep 2
done

SCREEN=$(adb -s "$DEV" shell wm size | grep -oE '[0-9]+x[0-9]+' | tail -1 | tr 'x' ' ')
read -r W H <<<"$SCREEN"
X=$((W / 2))
Y=$((H / 2))
echo "ready=$READY, tapping ($X,$Y)"

if [ "$READY" = "1" ]; then
  # Mehrere echte Taps mit Abstand; der Test pollt parallel auf das Sheet.
  for i in 1 2 3 4 5 6; do
    adb -s "$DEV" shell input tap "$X" "$Y"
    sleep 8
  done
fi

wait "$TEST_PID"
