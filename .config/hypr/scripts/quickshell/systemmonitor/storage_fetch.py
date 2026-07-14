#!/usr/bin/env python3
# One line per physical block device (real disks only - zram/loop excluded):
# name<0x1f>kind<0x1f>model<0x1f>sizeBytes<0x1f>usedBytes<0x1f>fsTotalBytes<0x1f>mountpoint
# kind is one of: hdd, nvme, usb, sd, ssd (sata/other non-rotational fallback).
# mountpoint is the "primary" mount for the whole disk ("/" if any partition
# is the root, otherwise the first real mountpoint found) - empty if nothing
# on this disk is currently mounted.

import json
import subprocess

FS = "\x1f"


def classify(dev):
    name = dev.get("name") or ""
    if name.startswith("mmcblk"):
        return "sd"
    if dev.get("rm") or dev.get("tran") == "usb":
        return "usb"
    if dev.get("tran") == "nvme":
        return "nvme"
    if dev.get("rota"):
        return "hdd"
    return "ssd"


def collect_usage(dev):
    used = 0
    total = 0
    for child in dev.get("children") or []:
        if child.get("fssize"):
            used += child.get("fsused") or 0
            total += child.get("fssize") or 0
        c_used, c_total = collect_usage(child)
        used += c_used
        total += c_total
    return used, total


def collect_mountpoints(dev):
    mps = []
    mp = dev.get("mountpoint")
    if mp and mp != "[SWAP]":
        mps.append(mp)
    for child in dev.get("children") or []:
        mps.extend(collect_mountpoints(child))
    return mps


def primary_mountpoint(dev):
    mps = collect_mountpoints(dev)
    if "/" in mps:
        return "/"
    return mps[0] if mps else ""


def main():
    proc = subprocess.run(
        ["lsblk", "-b", "-J", "-o",
         "NAME,SIZE,TYPE,TRAN,ROTA,MOUNTPOINT,FSUSED,FSSIZE,MODEL,RM"],
        capture_output=True, text=True,
    )
    try:
        data = json.loads(proc.stdout or "{}")
    except ValueError:
        data = {}

    lines = []
    for dev in data.get("blockdevices", []):
        if dev.get("type") != "disk":
            continue
        name = dev.get("name") or ""
        if name.startswith("zram") or name.startswith("loop"):
            continue

        kind = classify(dev)
        model = (dev.get("model") or "").strip() or name
        size = dev.get("size") or 0
        used, fs_total = collect_usage(dev)
        mountpoint = primary_mountpoint(dev)

        lines.append(FS.join([name, kind, model, str(size), str(used), str(fs_total), mountpoint]))

    # TEMP TEST MOCK - remove after visually checking the illustrations
    lines.append(FS.join(["sdz", "hdd", "Seagate BarraCuda 2TB", "2000000000000", "1200000000000", "1900000000000", "/mnt/test-hdd"]))
    lines.append(FS.join(["sdy", "usb", "SanDisk Ultra 64GB", "64000000000", "48000000000", "64000000000", "/run/media/useracc/SANDISK"]))
    lines.append(FS.join(["mmcblk0", "sd", "SanDisk SDHC 32GB", "32000000000", "9000000000", "32000000000", "/run/media/useracc/SDCARD"]))

    print("\n".join(lines))


if __name__ == "__main__":
    main()
