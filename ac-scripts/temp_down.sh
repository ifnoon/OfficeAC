#!/bin/bash
source "$(dirname "$0")/config.sh"
CURRENT=$(curl -s "$HA_URL/api/states/$ENTITY" -H "Authorization: Bearer $HA_TOKEN" | python3 -c "import sys,json; print(json.load(sys.stdin)['attributes']['temperature'])" 2>/dev/null)
NEW=$(python3 -c "print(max($CURRENT - 0.5, 16))")

curl -s -X POST "$HA_URL/api/services/climate/set_temperature" \
  -H "Authorization: Bearer $HA_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"entity_id\": \"$ENTITY\", \"temperature\": $NEW}" > /dev/null

echo "${NEW%%.0}°"
