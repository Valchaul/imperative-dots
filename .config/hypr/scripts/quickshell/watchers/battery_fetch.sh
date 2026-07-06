#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../caching.sh"
qs_ensure_cache "battery"

HISTORY_FILE="$QS_CACHE_BATTERY/history.json"
BOOT_MARKER="$QS_CACHE_BATTERY/boot_marker"
SAMPLE_INTERVAL=200    # 200 = 3.33 minutes between logged samples

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

# --- Throttled history logging: one sample per SAMPLE_INTERVAL ---
# Gated by Settings > General > "Battery history" toggle (default enabled)
HISTORY_ENABLED=$(jq -r '.batteryHistoryEnabled // true' "$HOME/.config/hypr/settings.json" 2>/dev/null || echo true)
if [ "$HISTORY_ENABLED" = "true" ]; then
    # Wipe history.json on a fresh boot — `uptime -s` is a stable per-boot
    # timestamp (unlike /proc/uptime, which drifts every call), so a mismatch
    # against the last-seen marker means the machine rebooted since we last ran.
    CURRENT_BOOT=$(uptime -s 2>/dev/null)
    if [ "$CURRENT_BOOT" != "$(cat "$BOOT_MARKER" 2>/dev/null)" ]; then
        echo "[]" > "$HISTORY_FILE"
        echo "$CURRENT_BOOT" > "$BOOT_MARKER"
    fi

    NOW=$(date +%s)
    LAST_TS=0
    if [ -f "$HISTORY_FILE" ]; then
        LAST_TS=$(jq -r '(.[-1].t // 0)' "$HISTORY_FILE" 2>/dev/null || echo 0)
    fi
    if [ $((NOW - LAST_TS)) -ge $SAMPLE_INTERVAL ]; then
        EXISTING="[]"
        [ -f "$HISTORY_FILE" ] && EXISTING=$(cat "$HISTORY_FILE" 2>/dev/null || echo "[]")
        echo "$EXISTING" | jq --argjson t "$NOW" --argjson p "$PERCENT" \
            '. + [{"t": $t, "p": $p}]' > "${HISTORY_FILE}.tmp" \
            && mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"
    fi
fi

jq -n -c --arg percent "$PERCENT" --arg status "$STATUS" --arg icon "$ICON" '{percent: $percent, status: $status, icon: $icon}'