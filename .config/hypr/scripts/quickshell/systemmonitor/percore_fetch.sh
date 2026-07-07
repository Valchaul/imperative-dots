#!/usr/bin/env bash

# One line: comma-separated CPU usage percentage per core, in core order
# (cpu0, cpu1, ...). Same delta-sampling approach as ../watchers/sys_fetcher.sh,
# just applied per-core instead of to the aggregate "cpu " line.

mapfile -t lines1 < <(grep '^cpu[0-9]' /proc/stat)
sleep 0.3
mapfile -t lines2 < <(grep '^cpu[0-9]' /proc/stat)

result=()
for i in "${!lines1[@]}"; do
    read -r _ u1 n1 s1 i1 io1 ir1 so1 st1 _ <<< "${lines1[$i]}"
    read -r _ u2 n2 s2 i2 io2 ir2 so2 st2 _ <<< "${lines2[$i]}"

    idle1=$((i1 + io1)); total1=$((u1 + n1 + s1 + i1 + io1 + ir1 + so1 + st1))
    idle2=$((i2 + io2)); total2=$((u2 + n2 + s2 + i2 + io2 + ir2 + so2 + st2))

    dt=$((total2 - total1)); di=$((idle2 - idle1))
    if [ "$dt" -le 0 ]; then pct=0; else pct=$(( 100 * (dt - di) / dt )); fi

    result+=("$pct")
done

IFS=,
echo "${result[*]}"
