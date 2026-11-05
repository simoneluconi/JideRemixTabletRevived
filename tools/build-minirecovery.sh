#!/bin/bash
# Build the sk1wg mini recovery: a boot image made of a kernel (stock 2.0.305
# by default) and our own ramdisk (busybox init, the stock adbd, a setuid su).
# See minirecovery/init for why the stock Android init is not used.
#
# Usage: build-minirecovery.sh <stock boot.img> <stock recovery.img> \
#            <busybox static ARM binary> <su static ARM binary> <out dir>
# REBOOT_TO=<static ARM build of minirecovery/reboot-to.c> is required too.
# KERNEL=<zImage> replaces the stock kernel, to test our own kernel with this
# known-good ramdisk.
# Needs python3, cpio and mkbootimg.py from an Android tree (MKBOOTIMG to
# override the default path).
#
# Use it with "fastboot boot <out>/minirecovery.img" only: it is never
# flashed, so it runs from RAM and a reboot always brings back the stock
# system.
set -euo pipefail

boot=$1
recovery=$2
busybox=$3
su=$4
out=$5
here=$(cd "$(dirname "$0")/.." && pwd)
src=$here/minirecovery
mkbootimg=${MKBOOTIMG:-$HOME/android/lineage/system/tools/mkbootimg/mkbootimg.py}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
python3 "$here/tools/unpackboot.py" "$boot" "$work/boot" > /dev/null
python3 "$here/tools/unpackboot.py" "$recovery" "$work/recovery" > /dev/null
r=$work/root

for d in dev proc sys tmp sbin system system/bin data; do
    install -d -m 0755 "$r/$d"
done

# Ours
install -m 0750 "$src/init" "$r/init"
install -m 0644 "$src/sbin/minirecovery-lib.sh" "$r/sbin/"
install -m 0750 "$src/sbin/backup-critical" "$r/sbin/"
install -m 0755 "$src/sbin/rootrun" "$r/sbin/"

# From the stock recovery: the static 5.1 adbd
install -m 0750 "$work/recovery/ramdisk/sbin/adbd" "$r/sbin/adbd"

# busybox: applet links in /sbin, /system/bin/sh for adb shell. Tools that
# discard, format or repartition the eMMC get no link.
install -m 0755 "$busybox" "$r/sbin/busybox"
for a in $("$here/tools/busybox-applets.sh" "$busybox"); do
    case "$a" in
        busybox|blkdiscard|fstrim|fdisk|shred|mkswap|mkdosfs|mkfs.vfat|mkfs.ext2|mke2fs|nanddump|nandwrite|flash_eraseall|flash_lock|flash_unlock|flashcp|init|linuxrc) continue ;;
    esac
    [ -e "$r/sbin/$a" ] || ln -s busybox "$r/sbin/$a"
done
ln -s /sbin/busybox "$r/system/bin/sh"
[ -e "$r/sbin/sh" ] || ln -s busybox "$r/sbin/sh"

# setuid-root su: adbd drops to the shell uid and keeps only CAP_SETUID and
# CAP_SETGID in the bounding set. Root still owns the block devices, so
# reading them works; mounting does not.
install -m 4755 "$su" "$r/sbin/su"
# "rootrun reboot-to bootloader" replaces "adb reboot bootloader" (su
# lacks CAP_SYS_BOOT, rootrun runs it as PID 1)
install -m 0750 "${REBOOT_TO:?set REBOOT_TO to the static ARM reboot-to binary}" "$r/sbin/reboot-to"

(cd "$r" && find . | sort | cpio -o -H newc -R 0:0 --quiet) | gzip -9n > "$work/ramdisk.gz"

mkdir -p "$out"
python3 "$mkbootimg" --header_version 0 \
    --kernel "${KERNEL:-$work/boot/zImage}" --ramdisk "$work/ramdisk.gz" \
    --base 0x10000000 --pagesize 2048 \
    --kernel_offset 0x00008000 --ramdisk_offset 0x01000000 \
    --second_offset 0x00f00000 --tags_offset 0x00000100 \
    --output "$out/minirecovery.img"
ls -l "$out/minirecovery.img"
sha1sum "$out/minirecovery.img"
