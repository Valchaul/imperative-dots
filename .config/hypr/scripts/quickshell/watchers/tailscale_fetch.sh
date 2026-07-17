#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/../../caching.sh"

if ! command -v tailscale >/dev/null 2>&1; then
    echo '{"available":false,"connected":false,"state":"unavailable","ip":"","hostname":""}'
    exit 0
fi

RAW=$(tailscale status --json 2>/dev/null)
if [ -z "$RAW" ]; then
    echo '{"available":true,"connected":false,"state":"unknown","ip":"","hostname":""}'
    exit 0
fi

echo "$RAW" | jq -c '{
    available: true,
    connected: (.BackendState == "Running"),
    state: .BackendState,
    ip: (.Self.TailscaleIPs[0] // ""),
    hostname: (.Self.HostName // "")
}'
