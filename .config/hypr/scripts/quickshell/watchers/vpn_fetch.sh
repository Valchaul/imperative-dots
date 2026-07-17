#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../caching.sh"

if ! command -v mullvad >/dev/null 2>&1; then
    echo '{"available":false,"connected":false,"state":"unavailable","country":"","city":""}'
    exit 0
fi

RAW=$(mullvad status --json 2>/dev/null)
if [ -z "$RAW" ]; then
    echo '{"available":true,"connected":false,"state":"unknown","country":"","city":""}'
    exit 0
fi

echo "$RAW" | jq -c '{
    available: true,
    connected: (.state == "connected"),
    state: .state,
    country: (.details.location.country // ""),
    city: (.details.location.city // "")
}'
