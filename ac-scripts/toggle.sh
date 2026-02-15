#!/bin/bash
source "$(dirname "$0")/config.sh"
MODE=$(curl -s "$HA_URL/api/states/$ENTITY" -H "Authorization: Bearer $HA_TOKEN" | python3 -c "import sys,json; print(json.load(sys.stdin)['state'])" 2>/dev/null)

if [ "$MODE" = "off" ]; then
    NEW_MODE="cool"
else
    NEW_MODE="off"
fi

curl -s -X POST "$HA_URL/api/services/climate/set_hvac_mode" \
  -H "Authorization: Bearer $HA_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"entity_id\": \"$ENTITY\", \"hvac_mode\": \"$NEW_MODE\"}" > /dev/null

sleep 0.5
"$(dirname "$0")/status.sh"
