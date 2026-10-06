#!/usr/bin/env bash
# Builds ios/www from the repository root for the App Store reference build.
# Differences from the web build, all applied to the copy in ios/www (the web files are not touched):
#   1. One meta tag, toxcard-build=reference. With it, index.html computes no doses —
#      every dose is shown exactly as its source states it (Guideline 1.4.2).
#   2. IBM Plex fonts are bundled from @fontsource (SIL OFL 1.1) and the Google Fonts
#      link tags are replaced, so the app makes no network request at all.
#   3. privacy.html is replaced with ios/privacy-reference.html, which describes this build
#      (no dose calculator, no network) instead of the web build.
# Run `npm install` in ios/ first so the @fontsource packages are present.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IOS="$ROOT/ios"
OUT="$IOS/www"
rm -rf "$OUT"; mkdir -p "$OUT"
cp "$ROOT/index.html" "$ROOT/manifest.json" "$ROOT/icon.svg" "$ROOT/sw.js" "$OUT/"
cp "$IOS/privacy-reference.html" "$OUT/privacy.html"
cp -r "$ROOT/data" "$ROOT/icons" "$OUT/"

# --- Fonts: same families and weights the web build requests from Google Fonts ---
FS="$IOS/node_modules/@fontsource"
[ -d "$FS/ibm-plex-sans/files" ] && [ -d "$FS/ibm-plex-mono/files" ] \
  || { echo "@fontsource packages missing: run npm install in ios/ first" >&2; exit 1; }
mkdir -p "$OUT/fonts"
# Uses @fontsource's own per-weight CSS so every subset keeps its unicode-range
# (without it the subsets would override one another). Only the woff2 sources are kept.
python3 - "$FS" "$OUT/fonts" <<'PY'
import sys, re, shutil, os
fs, out = sys.argv[1], sys.argv[2]
want = {"ibm-plex-sans": [400, 500, 600, 700], "ibm-plex-mono": [400, 500, 600]}
css = []
for pkg, weights in want.items():
    for w in weights:
        src = open(os.path.join(fs, pkg, f"{w}.css"), encoding="utf-8").read()
        src = re.sub(r",\s*url\([^)]*\.woff\) format\('woff'\)", "", src)
        for f in re.findall(r"url\(\./files/([^)]+\.woff2)\)", src):
            shutil.copy(os.path.join(fs, pkg, "files", f), os.path.join(out, f))
        css.append(src.replace("url(./files/", "url("))
open(os.path.join(out, "fonts.css"), "w", encoding="utf-8").write("\n".join(css))
PY
cp "$FS/ibm-plex-sans/LICENSE" "$OUT/fonts/OFL-IBM-Plex.txt"

python3 - "$OUT/index.html" <<'PY'
import sys, re
p=sys.argv[1]; s=open(p,encoding='utf-8').read()
# 1. Reference flag
tag='<meta name="toxcard-build" content="reference">'
if not re.search(r'^<meta name="toxcard-build"', s, re.M):
    n=s.count('<meta charset="utf-8">')
    assert n==1, "charset meta not found exactly once; reference flag not injected"
    s=s.replace('<meta charset="utf-8">','<meta charset="utf-8">\n'+tag,1)
# 2. Google Fonts -> bundled fonts
links=re.findall(r'^<link[^>]*fonts\.(?:googleapis|gstatic)\.com[^>]*>\n?', s, re.M)
assert len(links)==3, f"expected 3 Google Fonts link tags, found {len(links)}"
for i,l in enumerate(links):
    s=s.replace(l, '<link rel="stylesheet" href="fonts/fonts.css">\n' if i==len(links)-1 else '', 1)
open(p,'w',encoding='utf-8').write(s)
PY

# --- Checks: fail the build rather than ship a wrong bundle ---
grep -q '^<meta name="toxcard-build" content="reference">' "$OUT/index.html"
grep -q 'href="fonts/fonts.css"' "$OUT/index.html"
if grep -rnoE '(https?:)?//[a-z0-9.-]+\.(googleapis|gstatic)\.com' "$OUT" ; then
  echo "External font reference left in the bundle" >&2; exit 1; fi
if grep -nE '(src|href)="https?://' "$OUT/index.html" ; then
  echo "External resource reference in index.html" >&2; exit 1; fi
grep -qi 'dose calculator' "$OUT/privacy.html" && { echo "Web privacy text in the reference bundle" >&2; exit 1; }
echo "Reference build written to $OUT ($(ls "$OUT/fonts" | grep -c woff2) font files)"
