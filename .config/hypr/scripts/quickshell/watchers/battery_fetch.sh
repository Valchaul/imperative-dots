#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../caching.sh"
qs_ensure_cache "battery"

HISTORY_FILE="$QS_CACHE_BATTERY/history.json"
SAMPLE_INTERVAL=600    # 10 minutes between logged samples
RETENTION_SECONDS=28800 # keep last 8 hours

get_battery_percent() { LC_ALL=C cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1 || echo "100"; }
get_battery_status() { LC_ALL=C cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1 || echo "Full"; }
get_battery_icon() {
    local percent=$1
    local status=$2
    if [ "$status" = "Charging" ] || [ "$status" = "Full" ]; then
        if [ "$percent" -ge 90 ]; then echo "󰂅"
        elif [ "$percent" -ge 80 ]; then echo "󰂋"
        elif [ "$percent" -ge 60 ]; then echo "󰂊"
        elif [ "$percent" -ge 40 ]; then echo "󰢞"
        elif [ "$percent" -ge 20 ]; then echo "󰂆"
        else echo "󰢜"; fi
    else
        if [ "$percent" -ge 90 ]; then echo "󰁹"
        elif [ "$percent" -ge 80 ]; then echo "󰂂"
        elif [ "$percent" -ge 70 ]; then echo "󰂁"
        elif [ "$percent" -ge 60 ]; then echo "󰂀"
        elif [ "$percent" -ge 50 ]; then echo "󰁿"
        elif [ "$percent" -ge 40 ]; then echo "󰁾"
        elif [ "$percent" -ge 30 ]; then echo "󰁽"
        elif [ "$percent" -ge 20 ]; then echo "󰁼"
        elif [ "$percent" -ge 10 ]; then echo "󰁻"
        else echo "󰁺"; fi
    fi
}

PERCENT=$(get_battery_percent)
STATUS=$(get_battery_status)
ICON=$(get_battery_icon "$PERCENT" "$STATUS")

# --- Throttled history logging: one sample per SAMPLE_INTERVAL, pruned to RETENTION_SECONDS ---
NOW=$(date +%s)
LAST_TS=0
if [ -f "$HISTORY_FILE" ]; then
    LAST_TS=$(jq -r '(.[-1].t // 0)' "$HISTORY_FILE" 2>/dev/null || echo 0)
fi
if [ $((NOW - LAST_TS)) -ge $SAMPLE_INTERVAL ]; then
    CUTOFF=$((NOW - RETENTION_SECONDS))
    EXISTING="[]"
    [ -f "$HISTORY_FILE" ] && EXISTING=$(cat "$HISTORY_FILE" 2>/dev/null || echo "[]")
    echo "$EXISTING" | jq --argjson t "$NOW" --argjson p "$PERCENT" --argjson cutoff "$CUTOFF" \
        '(. + [{"t": $t, "p": $p}]) | map(select(.t >= $cutoff))' > "${HISTORY_FILE}.tmp" \
        && mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
fi

jq -n -c --arg percent "$PERCENT" --arg status "$STATUS" --arg icon "$ICON" '{percent: $percent, status: $status, icon: $icon}'