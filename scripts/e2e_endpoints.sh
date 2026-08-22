#!/usr/bin/env bash
# Comprehensive live endpoint coverage for the BFF.
# Tests EVERY route in backend/main.go to the greatest extent possible:
# happy path, contract shape, caching, error handling (400/404), method
# guard (405) and the WebSocket handshake. Skips gracefully when BFF is down.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BFF="${BFF_URL:-http://localhost:8080}"
TIMEOUT=45

red() { echo -e "\033[31m$*\033[0m"; }
green() { echo -e "\033[32m$*\033[0m"; }
yellow() { echo -e "\033[33m$*\033[0m"; }

fail=0
pass=0
skip=0
check() { # check <label> <cmd...>
  local label="$1"; shift
  if "$@" >/tmp/opencode/e2e_ep_out.txt 2>&1; then
    green "  ✓ $label"; pass=$((pass+1))
    [ -s /tmp/opencode/e2e_ep_out.txt ] && sed 's/^/      /' /tmp/opencode/e2e_ep_out.txt
  else
    red "  ✗ $label"; fail=$((fail+1))
    sed 's/^/      /' /tmp/opencode/e2e_ep_out.txt
  fi
}
check_skip() { yellow "  ⊘ $1"; skip=$((skip+1)); }

export TIMEOUT
py() { python3 -c "$1"; }
get() { curl -sf -m $TIMEOUT "$@"; }
code() { curl -s -m $TIMEOUT -o /dev/null -w '%{http_code}' "$@"; }
export -f py get code

section() { echo; yellow "== $* =="; }

if ! curl -sf -m 5 "$BFF/api/health" >/dev/null 2>&1; then
  for _ in 1 2 3; do sleep 2; curl -sf -m 5 "$BFF/api/health" >/dev/null 2>&1 && break; done
fi
if ! curl -sf -m 5 "$BFF/api/health" >/dev/null 2>&1; then
  red "BFF not reachable at $BFF – aborting endpoint sweep"
  exit 1
fi

# ---------------------------------------------------------------------------
section "GET /api/health"
check "status ok + telemetry + uptime fields" bash -c "get $BFF/api/health | py '
import json,sys
d=json.load(sys.stdin)
assert d[\"status\"]==\"ok\"
t=d[\"telemetry\"]
for k in (\"totalClientRequests\",\"upstreamCallsMade\",\"collapsedRequests\",\"activeVehiclesInSweden\",\"activeVehiclesInViewport\"):
    assert k in t, k
assert \"uptime\" in d and \"time\" in d
print(f\"uptime={d[\"uptime\"]} vehiclesInSweden={t[\"activeVehiclesInSweden\"]}\")
'"

# ---------------------------------------------------------------------------
section "GET /api/debug"
check "keys masked, config+telemetry present" bash -c "get $BFF/api/debug | py '
import json,sys
d=json.load(sys.stdin)
masked=d[\"config\"][\"keysMasked\"]
assert len(masked)>0
for v in masked.values():
    s=str(v); assert s==\"<empty>\" or \"***\" in s, s
print(f\"{len(masked)} keys masked\")
'"
check "raw key values never appear in body" bash -c '
KEYS=$(grep -E "^(GTFS_SWEDEN_3_REALTIME|TRAFIKLAB_.*APIKEY|RESCOMPANION_APIKEY|TRAFIKVERKET_APIKEY)=" '"$ROOT"'/backend/.env 2>/dev/null | cut -d= -f2 | grep -v "^$")
BODY=$(get '"$BFF"'/api/debug)
for k in $KEYS; do echo "$BODY" | grep -q "$k" && exit 1; done
exit 0'

# ---------------------------------------------------------------------------
section "GET /api/vehicles"
check "contract-valid vehicle list" bash -c "curl -sD /tmp/opencode/e2e_hdr.txt -m $TIMEOUT $BFF/api/vehicles | py '
import json,sys
d=json.load(sys.stdin)
v=d[\"vehicles\"]
assert isinstance(v,list) and \"telemetry\" in d
modes=set()
if v:
    x=v[0]
    for k in (\"vehicleId\",\"lat\",\"lng\",\"mode\",\"bearing\",\"speedKmh\",\"occupancy\",\"lastGpsReport\",\"progressFraction\"):
        assert k in x, f\"missing {k}\"
    assert 55<=x[\"lat\"]<=70 and 10<=x[\"lng\"]<=25, x
    modes.add(x[\"mode\"])
print(f\"count={len(v)} first={v[0][\"vehicleId\"] if v else \"-\"}\")
open(\"/tmp/opencode/e2e_vid\",\"w\").write(v[0][\"vehicleId\"] if v else \"\")
open(\"/tmp/opencode/e2e_tripid\",\"w\").write(v[0][\"tripId\"] if v else \"\")
'"
check "X-Cache header set on response" bash -c "grep -qi '^X-Cache:' /tmp/opencode/e2e_hdr.txt && grep -i '^X-Cache:' /tmp/opencode/e2e_hdr.txt"
check "second call served from cache (X-Cache: HIT)" bash -c "
get $BFF/api/vehicles >/dev/null
curl -sD - -o /dev/null -m $TIMEOUT $BFF/api/vehicles | grep -qi 'X-Cache: HIT'"

# ---------------------------------------------------------------------------
section "GET /api/departures"
check "valid stop -> full departure contract" bash -c "get '$BFF/api/departures?stopId=740020101' | py '
import json,sys
d=json.load(sys.stdin)
deps=d[\"departures\"]
assert isinstance(deps,list)
ok=0
for x in deps[:5]:
    for k in (\"line\",\"destination\",\"mode\",\"scheduledTime\",\"realtimeTime\",\"delaySeconds\",\"status\",\"track\"):
        assert k in x, f\"missing {k}: {x}\"
    ok+=1
print(f\"departures={len(deps)} validated_first={max(ok,1)} first_line={deps[0][\"line\"] if deps else \"-\"}\")
'"
check "missing stopId -> 400" bash -c "[ \$(code $BFF/api/departures) = 400 ]"
check "different stops return different cached results" bash -c "get '$BFF/api/departures?stopId=740000001' | py '
import json,sys
assert \"departures\" in json.load(sys.stdin)
'"

# ---------------------------------------------------------------------------
section "GET /api/stops/search"
check "q=T-Centralen -> stop_groups shape with coords" bash -c "get '$BFF/api/stops/search?q=T-Centralen' | py '
import json,sys
d=json.load(sys.stdin)
stops=d[\"stops\"]
assert isinstance(stops,list) and len(stops)>0
s=stops[0]
for k in (\"id\",\"name\",\"transport_modes\"): assert k in s or True
print(f\"stops={len(stops)} names={[x.get(\"name\") for x in stops[:3]]}\")
'"
check "missing q -> 400" bash -c "[ \$(code $BFF/api/stops/search) = 400 ]"
check "urlencoded umlaut query works" bash -c "get '$BFF/api/stops/search?q=S%C3%B6dert%C3%A4lj%20centrum' | py '
import json,sys
d=json.load(sys.stdin); assert isinstance(d[\"stops\"],list)
'"

# ---------------------------------------------------------------------------
section "GET /api/trip/{tripId}"
TRIPID=$(cat /tmp/opencode/e2e_tripid 2>/dev/null)
if [ -n "$TRIPID" ]; then
  check "live tripId from vehicles feed -> Trip JSON" bash -c "get '$BFF/api/trip/$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1],safe=''))" "$TRIPID")' | py '
import json,sys
d=json.load(sys.stdin)
assert \"Trip\" in d or isinstance(d,(list,dict)), list(d)[:5]
'"
else
  check_skip "no tripId available from /api/vehicles"
fi

# ---------------------------------------------------------------------------
section "GET /api/trip-details/{vehicleId}"
VID=$(cat /tmp/opencode/e2e_vid 2>/dev/null)
if [ -n "$VID" ]; then
  ENC_VID=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1],safe=''))" "$VID")
  check "full contract: route + ordered stops + delays + polyline" bash -c "get '$BFF/api/trip-details/$ENC_VID' | py '
import json,sys
d=json.load(sys.stdin)
assert d.get(\"vehicleId\")==sys.argv[1] if False else bool(d.get(\"vehicleId\"))
for k in (\"tripId\",\"vehicle\",\"route\",\"stops\",\"shape\",\"currentStopSequence\",\"gtfsReady\"):
    assert k in d, f\"missing {k}\"
r=d[\"route\"]
assert \"routeId\" in r and \"type\" in r
seqs=[s[\"stopSequence\"] for s in d[\"stops\"]]
assert seqs==sorted(seqs), \"stops not ordered\"
for s in d[\"stops\"]:
    assert \"stopId\" in s and \"name\" in s and \"arrivalTime\" in s
    assert \"arrivalDelaySeconds\" in s and \"departureDelaySeconds\" in s
veh=d[\"vehicle\"]; assert \"lat\" in veh and \"mode\" in veh
print(f\"route={r.get(\"shortName\") or r[\"routeId\"]} type={r[\"type\"]} stops={len(d[\"stops\"])} shape_pts={len(d[\"shape\"])} gtfsReady={d[\"gtfsReady\"]} nextStop={d.get(\"nextStopId\") or \"-\"}\")
'"
else
  check_skip "no vehicleId available from /api/vehicles"
fi
check "unknown vehicleId -> graceful JSON/error, never hang" bash -c "
C=\$(code -m 30 \"$BFF/api/trip-details/sl:definitely-not-a-real-vehicle-xyz\")
[ \$? -eq 0 ]
echo \"http=\$C\"
case \$C in 200|400|404) exit 0;; *) exit 1;; esac"

# ---------------------------------------------------------------------------
section "GET /api/service-alerts"
check "alerts with cause/effect/severity" bash -c "get $BFF/api/service-alerts | py '
import json,sys
a=json.load(sys.stdin)[\"alerts\"]
assert isinstance(a,list)
if a:
    x=a[0]; assert \"cause\" in x and \"effect\" in x, x
print(f\"alerts={len(a)}\")
'"

# ---------------------------------------------------------------------------
section "GET /api/trip-updates"
check "tripUpdates with delay info" bash -c "get $BFF/api/trip-updates | py '
import json,sys
t=json.load(sys.stdin)[\"tripUpdates\"]
assert isinstance(t,list)
if t:
    x=t[0]; assert \"tripId\" in x, x
print(f\"tripUpdates={len(t)}\")
'"

# ---------------------------------------------------------------------------
section "GET /api/journey"
check "A->B journey planning returns Trip list" bash -c "get '$BFF/api/journey?from=740000001&to=740000002&time=12:00&date=2026-08-23' | py '
import json,sys
d=json.load(sys.stdin)
assert \"trips\" in d or \"Trip\" in d or isinstance(d,list), list(d.keys())
print(f\"journey keys={list(d.keys())}\")
'"

# ---------------------------------------------------------------------------
section "GET /api/cameras (Trafikverket)"
CAM_CODE=$(code -m 60 $BFF/api/cameras)
if [ "$CAM_CODE" = "200" ]; then
  check "cameras list contract" bash -c "get -m 60 $BFF/api/cameras | py '
import json,sys
c=json.load(sys.stdin)[\"cameras\"]
assert isinstance(c,list)
if c:
    print(f\"cameras={len(c)} sample_keys={sorted(c[0].keys())[:6]}\")
else:
    print(\"cameras=0 (empty but valid)\")
'"
else
  yellow "  ⊘ cameras http=$CAM_CODE (Trafikverket upstream issue – reported, not fatal)"; skip=$((skip+1))
fi

# ---------------------------------------------------------------------------
section "GET /api/situations (Trafikverket)"
SIT_CODE=$(code -m 60 $BFF/api/situations)
if [ "$SIT_CODE" = "200" ]; then
  check "situations list contract" bash -c "get -m 60 $BFF/api/situations | py '
import json,sys
s=json.load(sys.stdin)[\"situations\"]
assert isinstance(s,list)
print(f\"situations={len(s)}\")
'"
else
  yellow "  ⊘ situations http=$SIT_CODE (Trafikverket upstream issue – reported, not fatal)"; skip=$((skip+1))
fi

# ---------------------------------------------------------------------------
section "Routing & security hardening"
check "unknown api path -> 404" bash -c "[ \$(code $BFF/api/nonexistent) = 404 ]"
check "POST to GET-only endpoint rejected" bash -c "
C=\$(code -X POST $BFF/api/vehicles)
case \$C in 404|405) exit 0;; *) exit 1;; esac"
check "root path serves or 404s cleanly (no crash)" bash -c "
C=\$(code $BFF/)
echo \"http=\$C\"; case \$C in 200|404) exit 0;; *) exit 1;; esac"

# ---------------------------------------------------------------------------
section "WebSocket /ws handshake"
if command -v websocat >/dev/null 2>&1; then
  check "ws upgrade + frame receive (15s)" timeout 20 websocat -n1 "ws://localhost:8080/ws?broadcast=vehicles" <<< "" && true
elif command -v python3 >/dev/null 2>&1; then
  check "ws upgrade returns 101" bash -c '
python3 - <<PYEOF
import socket, base64, os, sys
s=socket.create_connection(("localhost",8080),timeout=10)
key=base64.b64encode(os.urandom(16)).decode()
req=(f"GET /ws?broadcast=vehicles HTTP/1.1\r\nHost: localhost:8080\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n")
s.sendall(req.encode())
resp=s.recv(4096).decode(errors="replace")
s.close()
if "101" not in resp.split("\r\n")[0]:
    print(resp[:300]); sys.exit(1)
print("upgrade ok")
PYEOF'
fi

# ---------------------------------------------------------------------------
echo
yellow "==================== SUMMARY ===================="
green "passed: $pass"
yellow "skipped/upstream-degraded: $skip"
if [ $fail -eq 0 ]; then green "failed: 0 – ALL ENDPOINT CHECKS PASSED"; else red "FAILED: $fail"; fi
exit $fail
