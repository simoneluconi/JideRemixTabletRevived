#!/usr/bin/env python3
"""Render the sk1wg mini recovery's status screen as a raw framebuffer dump.

The panel is 1920x1080 landscape, 32 bits per pixel. Only black and white
(and greys with R=G=B) are used, so the result looks the same whatever the
channel order of the Tegra framebuffer is. The output is gzipped; init
zcats it to /dev/fb0.

Usage: mkscreen.py <out.raw.gz>
"""
import gzip
import sys

from PIL import Image, ImageDraw, ImageFont

FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
MONO = '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf'
W, H = 1920, 1080

LINES = [
    ('text', 'Runs from RAM only: nothing on the tablet has been changed.'),
    ('gap', None),
    ('text', 'Connect USB and use adb:'),
    ('mono', 'adb shell rootrun <command>      run a command as root'),
    ('mono', 'adb shell su -c backup-critical  copy the small partitions to /tmp/backup'),
    ('mono', 'adb shell rootrun reboot-to bootloader'),
    ('gap', None),
    ('text', 'Without a computer: hold Power for 15 seconds to switch off.'),
    ('text', 'The next start is Remix OS, as usual.'),
]


def main(out):
    img = Image.new('L', (W, H), 0)
    d = ImageDraw.Draw(img)
    title = ImageFont.truetype(FONT, 72)
    text = ImageFont.truetype(FONT, 40)
    mono = ImageFont.truetype(MONO, 34)
    y = 120
    d.text((120, y), 'Jide Remix Tablet mini recovery', font=title, fill=255)
    y += 150
    for kind, line in LINES:
        if kind == 'gap':
            y += 36
            continue
        d.text((120, y), line, font=mono if kind == 'mono' else text,
               fill=200 if kind == 'mono' else 230)
        y += 62 if kind == 'text' else 54
    # grey -> 4 identical bytes per pixel (alpha too: opaque white, black)
    raw = bytes(b for v in img.tobytes() for b in (v, v, v, 255))
    with gzip.open(out, 'wb', compresslevel=9) as f:
        f.write(raw)


if __name__ == '__main__':
    main(sys.argv[1])
