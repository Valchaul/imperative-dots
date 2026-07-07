#!/usr/bin/env python3
"""
Prints one process per line: PID<0x1f>CPU%<0x1f>CORE%<0x1f>MEM_MB<0x1f>NAME

Unlike a plain `ps -eo %cpu`, which reports a *lifetime average* (total CPU
time divided by total time the process has existed - can sit well above
current usage for a long-running process that had a busy moment earlier),
this samples every process's /proc/[pid]/stat twice, ~0.3s apart, and computes
a true instantaneous delta - the same methodology sys_fetcher.sh and
percore_fetch.sh use for the Ressources gauge and Cores grid, so all three
are now directly comparable instead of one being a longer-window average.

Pure Python (single process, no subprocess spawning) since sampling ~300-400
/proc entries twice via spawned commands would itself be real overhead - the
whole point of the earlier volume-slider CPU investigation this session.

CPU% is normalized so all cores combined = 100% (matches the Ressources
gauge); CORE% is unnormalized, one fully-busy core = 100% (traditional ps/top
convention, can exceed 100% for multi-threaded processes).
"""
import os
import time

MYPID = os.getpid()
NPROC = os.cpu_count() or 1
HZ = os.sysconf("SC_CLK_TCK")


def read_stats():
    stats = {}
    for entry in os.listdir("/proc"):
        if not entry.isdigit():
            continue
        pid = int(entry)
        if pid == MYPID:
            continue
        try:
            with open(f"/proc/{entry}/stat", "r") as f:
                content = f.read()
            l = content.index("(")
            r = content.rindex(")")
            comm = content[l + 1 : r]
            rest = content[r + 2 :].split()
            utime = int(rest[11])
            stime = int(rest[12])
            stats[pid] = (utime, stime, comm)
        except (FileNotFoundError, ProcessLookupError, ValueError, IndexError):
            continue
    return stats


def read_rss_mb(pid):
    try:
        with open(f"/proc/{pid}/status", "r") as f:
            for line in f:
                if line.startswith("VmRSS:"):
                    return int(line.split()[1]) / 1024.0
    except (FileNotFoundError, ProcessLookupError, ValueError, IndexError):
        pass
    return 0.0


def main():
    stats1 = read_stats()
    t1 = time.monotonic()
    time.sleep(0.3)
    t2 = time.monotonic()
    stats2 = read_stats()
    elapsed = t2 - t1

    results = []
    for pid, (u2, s2, comm) in stats2.items():
        prev = stats1.get(pid)
        if prev is None:
            continue
        u1, s1, _ = prev
        delta_ticks = max(0, (u2 - u1) + (s2 - s1))
        cpu_seconds = delta_ticks / HZ
        core_pct = (cpu_seconds / elapsed) * 100.0
        cpu_pct = core_pct / NPROC
        results.append([pid, cpu_pct, core_pct, comm])

    results.sort(key=lambda r: -r[1])
    total_count = len(results)
    results = results[:80]

    # First line is the true total process count (before the top-80 cap
    # below), so the UI can show "N processes" even though only the busiest
    # 80 are actually listed.
    lines = [str(total_count)]
    for pid, cpu_pct, core_pct, comm in results:
        mem_mb = read_rss_mb(pid)
        lines.append(f"{pid}\x1f{cpu_pct:.2f}\x1f{core_pct:.1f}\x1f{mem_mb:.1f}\x1f{comm}")

    print("\n".join(lines))


if __name__ == "__main__":
    main()