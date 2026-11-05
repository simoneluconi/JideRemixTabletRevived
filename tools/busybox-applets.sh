#!/bin/bash
# Print the applet list of an ARM busybox binary without running it: the
# names are stored as a NUL-separated table that starts with "[" "[[".
set -euo pipefail
python3 - "$1" <<'EOF'
import re, sys
d = open(sys.argv[1], 'rb').read()
i = d.find(b'[\0[[\0')
assert i >= 0, 'applet table not found'
names = []
for n in d[i:].split(b'\0'):
    if not n or not re.fullmatch(rb'[a-z0-9_.\[\]-]+', n):
        break
    names.append(n.decode())
print('\n'.join(names))
EOF
