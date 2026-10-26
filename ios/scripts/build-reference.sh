#!/usr/bin/env bash
# Builds ios/www from the repository root for the App Store reference build.
# Differences from the web build, all applied to the copy in ios/www (the web files are not touched):
#   1. One meta tag, toxcard-build=reference. With it, index.html computes no doses —
#      every dose is shown exactly as its source states it (Guideline 1.4.2).
#   2. IBM Plex fonts are bundled from @fontsource (SIL OFL 1.1) and the Google Fonts
#      link tags are replaced, so the app makes no network request at all.
#   3. privacy.html is replaced with ios/privacy-reference.html, which describes this build
#      (no dose calculator, no network) instead of the web build.
#   4. The iOS presentation layer, ios/app/native.css and ios/app/native.js, is added after the
#      app's own style and script, with Capacitor's core runtime (capacitor.js) before them.
#      It brings the iOS navigation and design and the bridge to the Swift code in ios/native.
#   5. The online dataset check and the service worker registration are removed: this build
#      makes no network request at all, and the build fails if any fetch/XHR is left.
# The clinical data (TOXINS, AGENTS, PROTOCOLS, TOXIDROMES, VERSION) is copied byte for byte and
# checked against the repository's index.html.
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
# 3. iOS layer: styles after the app's stylesheet, scripts after the app's script
assert s.count('</style>')==1 and s.count('</head>')==1, "style/head markers not found exactly once"
s=s.replace('</head>','<link rel="stylesheet" href="native.css">\n</head>',1)
# 4. No network in this build: drop the online dataset check and the service worker registration
refresh=re.findall(r'\n/\* data refresh .*?\n\}\)\(\);\n', s, re.S)
assert len(refresh)==1 and 'fetch(' in refresh[0], f"data refresh block not found exactly once ({len(refresh)})"
s=s.replace(refresh[0], '\n/* data refresh: not in the App Store build (no network). */\n',1)
sw=re.findall(r'<script>\nif\("serviceWorker" in navigator.*?</script>\n', s, re.S)
assert len(sw)==1, "service worker registration not found exactly once"
s=s.replace(sw[0], '<script src="capacitor.js"></script>\n<script src="native.js"></script>\n',1)
open(p,'w',encoding='utf-8').write(s)
PY
cp "$IOS/app/native.css" "$IOS/app/native.js" "$OUT/"
CAPJS="$IOS/node_modules/@capacitor/core/dist/capacitor.js"
[ -f "$CAPJS" ] || { echo "@capacitor/core dist/capacitor.js missing: run npm install in ios/ first" >&2; exit 1; }
cp "$CAPJS" "$OUT/capacitor.js"
rm -f "$OUT/sw.js"

# Clinical data must be byte-identical to the repository's index.html
python3 - "$ROOT/index.html" "$OUT/index.html" <<'PY'
import sys, re
a=open(sys.argv[1],encoding='utf-8').read(); b=open(sys.argv[2],encoding='utf-8').read()
for name in ("TOXINS","AGENTS","PROTOCOLS","TOXIDROMES","VERSION"):
    ra=re.findall(rf'^const {name}=.*$', a, re.M); rb=re.findall(rf'^const {name}=.*$', b, re.M)
    assert len(ra)==1 and ra==rb, f"{name} differs between the web index.html and the App Store bundle"
# every render function of the web build is present unchanged
for fn in ("viewToxin","doseTable","txdHTML","badgeFor","computeDoses","calcHTML"):
    fa=re.search(rf'^function {fn}\(.*?^}}$', a, re.M|re.S); fb=re.search(rf'^function {fn}\(.*?^}}$', b, re.M|re.S)
    assert fa and fb and fa.group(0)==fb.group(0), f"{fn} differs in the App Store bundle"
print("clinical data and render functions identical to the web build")
PY

# --- Checks: fail the build rather than ship a wrong bundle ---
grep -q '^<meta name="toxcard-build" content="reference">' "$OUT/index.html"
grep -q 'href="fonts/fonts.css"' "$OUT/index.html"
if grep -rnoE '(https?:)?//[a-z0-9.-]+\.(googleapis|gstatic)\.com' "$OUT" ; then
  echo "External font reference left in the bundle" >&2; exit 1; fi
if grep -nE '(src|href)="https?://' "$OUT/index.html" ; then
  echo "External resource reference in index.html" >&2; exit 1; fi
grep -qi 'dose calculator' "$OUT/privacy.html" && { echo "Web privacy text in the reference bundle" >&2; exit 1; }
for f in "$OUT/index.html" "$OUT/native.js"; do
  if grep -nE '\bfetch\(|XMLHttpRequest|navigator\.sendBeacon|new WebSocket|serviceWorker\.register' "$f"; then
    echo "Network call left in $(basename "$f")" >&2; exit 1; fi
done
grep -q '<script src="native.js"></script>' "$OUT/index.html"
grep -q 'href="native.css"' "$OUT/index.html"
echo "Reference build written to $OUT ($(ls "$OUT/fonts" | grep -c woff2) font files)"
