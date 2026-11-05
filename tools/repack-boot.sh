#!/bin/bash
# Swap the kernel of a boot image, keeping its ramdisk and header values.
# Used to boot the stock Remix OS ramdisk on our own kernel, with
# "fastboot boot" only (RAM, nothing is written).
#
# Usage: repack-boot.sh <boot.img> <zImage> <out.img>
# Needs python3 and mkbootimg.py from an Android tree (MKBOOTIMG to
# override the default path).
set -euo pipefail

img=$1
zimage=$2
out=$3
here=$(cd "$(dirname "$0")/.." && pwd)
mkbootimg=${MKBOOTIMG:-$HOME/android/lineage/system/tools/mkbootimg/mkbootimg.py}
max_size=8388608    # LNX and SOS are both 8 MB

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
python3 "$here/tools/unpackboot.py" "$img" "$work/u" > /dev/null

python3 "$mkbootimg" --header_version 0 \
    --kernel "$zimage" --ramdisk "$work/u/ramdisk.cpio.gz" \
    --base 0x10000000 --pagesize 2048 \
    --kernel_offset 0x00008000 --ramdisk_offset 0x01000000 \
    --second_offset 0x00f00000 --tags_offset 0x00000100 \
    --output "$out"

size=$(stat -c %s "$out")
if [ "$size" -gt "$max_size" ]; then
    echo "$out is $size bytes, larger than the boot partition ($max_size)" >&2
    exit 1
fi
ls -l "$out"
sha1sum "$out"
