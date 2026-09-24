#!/usr/bin/env bash
# Builds ios/www from the repository root for the App Store reference build.
# The only difference from the web build is one meta tag: toxcard-build=reference.
# With it, index.html computes no doses — every dose is shown exactly as its source states it.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/ios/www"
rm -rf "$OUT"; mkdir -p "$OUT"
cp "$ROOT/index.html" "$ROOT/manifest.json" "$ROOT/icon.svg" "$ROOT/privacy.html" "$ROOT/sw.js" "$OUT/"
cp -r "$ROOT/data" "$ROOT/icons" "$OUT/"
python3 - "$OUT/index.html" <<'PY'
import sys
p=sys.argv[1]; s=open(p,encoding='utf-8').read()
tag='<meta name="toxcard-build" content="reference">'
import re
if not re.search(r'^<meta name="toxcard-build"', s, re.M):
    n=s.count('<meta charset="utf-8">')
    assert n==1, "charset meta not found exactly once; reference flag not injected"
    s=s.replace('<meta charset="utf-8">','<meta charset="utf-8">\n'+tag,1)
open(p,'w',encoding='utf-8').write(s)
PY
grep -q '^<meta name="toxcard-build" content="reference">' "$OUT/index.html"
echo "Reference build written to $OUT"
