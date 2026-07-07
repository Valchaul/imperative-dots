#!/usr/bin/env bash

# One process per line: PID<0x1f>CPU%<0x1f>CORE%<0x1f>MEM%<0x1f>NAME
# 0x1f (unit separator) avoids ambiguity with spaces in process names.
#
# CPU% is normalized so all cores combined = 100%, matching the Ressources
# tab's aggregate CPU gauge (see note below). CORE% is ps's own raw value,
# scaled so one fully-busy core = 100% (can exceed 100% for multi-threaded
# processes) - the traditional ps/top convention, shown alongside for anyone
# who wants to see "how busy is the core(s) this thing is actually pegging."
#
# ps/awk/head are excluded: as extremely short-lived helper processes, ps
# measuring their own %cpu right as they start/exit produces a nonsensical
# instantaneous ratio, not a real sustained cost.
NPROC=$(nproc)

ps -eo pid,%cpu,%mem,comm --no-headers --sort=-%cpu | awk -v nproc="$NPROC" '
    $4 == "ps" || $4 == "awk" || $4 == "head" { next }
    {
        cmd = $4
        for (i = 5; i <= NF; i++) cmd = cmd " " $i
        printf "%s\x1f%.1f\x1f%s\x1f%s\x1f%s\n", $1, $2 / nproc, $2, $3, cmd
    }
' | head -n 80
