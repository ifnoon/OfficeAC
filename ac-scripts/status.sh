#!/bin/bash
source "$(dirname "$0")/config.sh"
STATE=$(curl -s "$HA_URL/api/states/$ENTITY" -H "Authorization: Bearer $HA_TOKEN")
MODE=$(echo "$STATE" | python3 -c "import sys,json; print(json.load(sys.stdin)['state'])" 2>/dev/null)
TEMP=$(echo "$STATE" | python3 -c "import sys,json; print(json.load(sys.stdin)['attributes']['temperature'])" 2>/dev/null)
CURRENT=$(echo "$STATE" | python3 -c "import sys,json; print(json.load(sys.stdin)['attributes']['current_temperature'])" 2>/dev/null)

if [ "$MODE" = "off" ]; then
    echo "OFF"
else
    echo "${TEMP%%.0}°"
fi
