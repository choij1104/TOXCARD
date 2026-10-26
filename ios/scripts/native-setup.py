#!/usr/bin/env python3
"""Prepares the generated Xcode project (ios/ios/App) for the App Store reference build.

Run after `npx cap add ios` / `npx cap sync ios`. The ios/ios directory is regenerated in CI
on every run, so everything that differs from Capacitor's template is applied here, in one
place, and the script fails loudly if the template has changed shape.

  1. App icon      ios/icons/icon-1024.png (drawn by scripts/make-icon.py) -> AppIcon set, alpha
                   channel removed (App Store rule). The template otherwise ships Capacitor's logo.
  2. Launch screen Template splash (Capacitor logo) replaced with the app icon centred on the
                   app's ground colour, with a dark-appearance variant, so launch and first screen match.
  3. Info.plist    ITSAppUsesNonExemptEncryption = NO (no own encryption; skips the export
                   question on every upload). iPad orientation keys removed with the iPad target.
  4. Devices       iPhone only (TARGETED_DEVICE_FAMILY = 1). An iPad target would require 13-inch
                   iPad screenshots and an iPad layout review.
  5. Privacy       PrivacyInfo.xcprivacy added to the app target: no tracking, no data collected,
                   no required-reason APIs. Capacitor's frameworks carry their own manifests.
  6. iOS 15.0      Minimum iOS raised from Capacitor's 14.0 in the app target and the Podfile
                   (ITMS-90068: uploads must target iOS 15.0 or later from April 2027).
                   Run this script before `npx cap sync ios` so pod install picks up the Podfile.
  7. Native code   ios/native/*.swift copied into the app target with fixed file IDs:
                   Core Spotlight index of every toxin and antidote, Siri / Shortcuts App Intents,
                   Home Screen quick actions, haptics, share sheet, AirPrint, and the view controller
                   that registers them. Main.storyboard switched to AppViewController.
  8. Entry points  Info.plist: static quick actions, NSUserActivityTypes for Siri Suggestions,
                   CoreSpotlightContinuation for "Search in App". AppDelegate's continue-userActivity
                   hands Spotlight and Siri activities to EntryRouter before Capacitor's proxy.
"""
import os, plistlib, re, sys
from PIL import Image

IOS = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))   # .../ios
ROOT = os.path.dirname(IOS)
APP = os.path.join(IOS, "ios", "App", "App")
PBX = os.path.join(IOS, "ios", "App", "App.xcodeproj", "project.pbxproj")
SPLASH_BG = (239, 240, 237)        # #EFF0ED, --ground in ios/app/native.css (light)
SPLASH_BG_DARK = (10, 11, 11)      # #0A0B0B, --ground (dark)

def die(msg):
    sys.exit(f"native-setup: {msg}")

for p in (APP, PBX):
    if not os.path.exists(p):
        die(f"{p} not found; run `npx cap add ios` first")

# 1. App icon --------------------------------------------------------------------------
icon_dir = os.path.join(APP, "Assets.xcassets", "AppIcon.appiconset")
names = [f for f in os.listdir(icon_dir) if f.endswith(".png")]
if len(names) != 1:
    die(f"expected one PNG in AppIcon.appiconset, found {names}")
src = Image.open(os.path.join(IOS, "icons", "icon-1024.png"))
if src.size != (1024, 1024):
    die(f"ios/icons/icon-1024.png is {src.size}, expected 1024x1024")
flat = Image.new("RGB", src.size, (255, 255, 255))
flat.paste(src, mask=src.split()[-1] if src.mode in ("RGBA", "LA") else None)
flat.save(os.path.join(icon_dir, names[0]))

# 2. Launch screen ---------------------------------------------------------------------
import json
splash_dir = os.path.join(APP, "Assets.xcassets", "Splash.imageset")
mark = flat.resize((360, 360), Image.LANCZOS)
def splash_img(bg):
    im = Image.new("RGB", (2732, 2732), bg)
    im.paste(mark, ((2732 - 360) // 2, (2732 - 360) // 2))
    return im
light, dark = splash_img(SPLASH_BG), splash_img(SPLASH_BG_DARK)
contents_path = os.path.join(splash_dir, "Contents.json")
contents = json.load(open(contents_path, encoding="utf-8"))
base = [i for i in contents.get("images", []) if i.get("filename", "").endswith(".png") and "appearances" not in i]
if not base:
    die("no splash images found in Splash.imageset")
images = []
for i in base:
    light.save(os.path.join(splash_dir, i["filename"]))
    images.append({"idiom": i["idiom"], "filename": i["filename"], "scale": i["scale"]})
    dname = "dark-" + i["filename"]
    dark.save(os.path.join(splash_dir, dname))
    images.append({"idiom": i["idiom"], "filename": dname, "scale": i["scale"],
                   "appearances": [{"appearance": "luminosity", "value": "dark"}]})
contents["images"] = images
json.dump(contents, open(contents_path, "w", encoding="utf-8"), indent=2)
count = len(images)

# 3. Info.plist ------------------------------------------------------------------------
plist_path = os.path.join(APP, "Info.plist")
with open(plist_path, "rb") as fh:
    info = plistlib.load(fh)
info["ITSAppUsesNonExemptEncryption"] = False
info.pop("UISupportedInterfaceOrientations~ipad", None)
# Static Home Screen quick actions; the pinned-entry ones are set at run time (QuickActionsPlugin).
info["UIApplicationShortcutItems"] = [
    {"UIApplicationShortcutItemType": "com.hakoya.toxcard.search",
     "UIApplicationShortcutItemTitle": "Search",
     "UIApplicationShortcutItemSubtitle": "Toxins, antidotes, brands",
     "UIApplicationShortcutItemIconType": "UIApplicationShortcutIconTypeSearch"},
    {"UIApplicationShortcutItemType": "com.hakoya.toxcard.triage",
     "UIApplicationShortcutItemTitle": "Toxidrome Triage",
     "UIApplicationShortcutItemSubtitle": "No history? Start here",
     "UIApplicationShortcutItemIconSymbolName": "stethoscope"},
]
info["NSUserActivityTypes"] = ["com.hakoya.toxcard.entry"]   # Siri Suggestions for viewed entries
info["CoreSpotlightContinuation"] = True                     # "Search in App" from Spotlight
with open(plist_path, "wb") as fh:
    plistlib.dump(info, fh)

# 4 + 5. Xcode project -----------------------------------------------------------------
pbx = open(PBX, encoding="utf-8").read()

n = len(re.findall(r'TARGETED_DEVICE_FAMILY = "1,2";', pbx))
if n == 0 and "TARGETED_DEVICE_FAMILY = 1;" not in pbx:
    die("TARGETED_DEVICE_FAMILY not found in project.pbxproj")
pbx = pbx.replace('TARGETED_DEVICE_FAMILY = "1,2";', "TARGETED_DEVICE_FAMILY = 1;")

MIN_IOS = "15.0"
pbx, n_ios = re.subn(r"IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;", f"IPHONEOS_DEPLOYMENT_TARGET = {MIN_IOS};", pbx)
if n_ios == 0:
    die("IPHONEOS_DEPLOYMENT_TARGET not found in project.pbxproj")
podfile = os.path.join(IOS, "ios", "App", "Podfile")
pod = open(podfile, encoding="utf-8").read()
pod, n_pod = re.subn(r"platform :ios, '[0-9.]+'", f"platform :ios, '{MIN_IOS}'", pod)
if n_pod != 1:
    die("platform :ios line not found in Podfile")
open(podfile, "w", encoding="utf-8").write(pod)

manifest = {
    "NSPrivacyTracking": False,
    "NSPrivacyTrackingDomains": [],
    "NSPrivacyCollectedDataTypes": [],
    "NSPrivacyAccessedAPITypes": [],
}
with open(os.path.join(APP, "PrivacyInfo.xcprivacy"), "wb") as fh:
    plistlib.dump(manifest, fh)

FILE_ID, BUILD_ID = "7A0C0FFEE0000000000000A1", "7A0C0FFEE0000000000000A2"
if FILE_ID not in pbx:
    anchor_ref = re.search(r"^\t\t(\w{24}) /\* Info\.plist \*/ = \{isa = PBXFileReference;[^\n]*\n", pbx, re.M)
    anchor_bld = re.search(r"^\t\t\w{24} /\* Assets\.xcassets in Resources \*/ = \{isa = PBXBuildFile;[^\n]*\n", pbx, re.M)
    res_phase = re.search(r"isa = PBXResourcesBuildPhase;.*?files = \(\n", pbx, re.S)
    if not (anchor_ref and anchor_bld and res_phase):
        die("Xcode template changed: could not find Info.plist / Assets / Resources entries")
    info_id = anchor_ref.group(1)
    group_line = re.search(rf"^(\t+){info_id} /\* Info\.plist \*/,\n", pbx, re.M)
    if not group_line:
        die("Info.plist not found in the App group")
    # insert from the end of the file backwards so earlier offsets stay valid
    edits = sorted([
        (anchor_ref.end(), f'\t\t{FILE_ID} /* PrivacyInfo.xcprivacy */ = {{isa = PBXFileReference; lastKnownFileType = text.xml; path = PrivacyInfo.xcprivacy; sourceTree = "<group>"; }};\n'),
        (anchor_bld.end(), f'\t\t{BUILD_ID} /* PrivacyInfo.xcprivacy in Resources */ = {{isa = PBXBuildFile; fileRef = {FILE_ID} /* PrivacyInfo.xcprivacy */; }};\n'),
        (group_line.end(), f"{group_line.group(1)}{FILE_ID} /* PrivacyInfo.xcprivacy */,\n"),
        (res_phase.end(), f"\t\t\t\t{BUILD_ID} /* PrivacyInfo.xcprivacy in Resources */,\n"),
    ], key=lambda e: e[0], reverse=True)
    for pos, text in edits:
        pbx = pbx[:pos] + text + pbx[pos:]

# 7. Native Swift sources --------------------------------------------------------------
import shutil
NATIVE = os.path.join(IOS, "native")
SWIFT = [("AppViewController.swift",   "7A0C0FFEE0000000000000C1", "7A0C0FFEE0000000000000C2"),
         ("EntryRouter.swift",         "7A0C0FFEE0000000000000C3", "7A0C0FFEE0000000000000C4"),
         ("SpotlightPlugin.swift",     "7A0C0FFEE0000000000000C5", "7A0C0FFEE0000000000000C6"),
         ("ToxcardIntents.swift",      "7A0C0FFEE0000000000000C7", "7A0C0FFEE0000000000000C8"),
         ("QuickActionsPlugin.swift",  "7A0C0FFEE0000000000000C9", "7A0C0FFEE0000000000000CA"),
         ("NativeUIPlugin.swift",      "7A0C0FFEE0000000000000CB", "7A0C0FFEE0000000000000CC")]
on_disk = sorted(f for f in os.listdir(NATIVE) if f.endswith(".swift"))
if on_disk != sorted(n for n, _, _ in SWIFT):
    die(f"ios/native has {on_disk}; SWIFT list in native-setup.py must name every file")
for name, fid, bid in SWIFT:
    shutil.copy(os.path.join(NATIVE, name), os.path.join(APP, name))
    if fid in pbx:
        continue
    ad_ref = re.search(r"^\t\t(\w{24}) /\* AppDelegate\.swift \*/ = \{isa = PBXFileReference;[^\n]*\n", pbx, re.M)
    ad_bld = re.search(r"^\t\t\w{24} /\* AppDelegate\.swift in Sources \*/ = \{isa = PBXBuildFile;[^\n]*\n", pbx, re.M)
    src_phase = re.search(r"isa = PBXSourcesBuildPhase;.*?files = \(\n", pbx, re.S)
    if not (ad_ref and ad_bld and src_phase):
        die("Xcode template changed: could not find AppDelegate.swift / Sources entries")
    grp = re.search(rf"^(\t+){ad_ref.group(1)} /\* AppDelegate\.swift \*/,\n", pbx, re.M)
    if not grp:
        die("AppDelegate.swift not found in the App group")
    edits = sorted([
        (ad_ref.end(), f'\t\t{fid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = "<group>"; }};\n'),
        (ad_bld.end(), f'\t\t{bid} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {fid} /* {name} */; }};\n'),
        (grp.end(), f"{grp.group(1)}{fid} /* {name} */,\n"),
        (src_phase.end(), f"\t\t\t\t{bid} /* {name} in Sources */,\n"),
    ], key=lambda e: e[0], reverse=True)
    for pos, text in edits:
        pbx = pbx[:pos] + text + pbx[pos:]

sb_path = os.path.join(APP, "Base.lproj", "Main.storyboard")
sb = open(sb_path, encoding="utf-8").read()
if 'customClass="AppViewController"' not in sb:
    old = 'customClass="CAPBridgeViewController" customModule="Capacitor"'
    if sb.count(old) != 1:
        die("Main.storyboard: CAPBridgeViewController not found")
    sb = sb.replace(old, 'customClass="AppViewController" customModule="App" customModuleProvider="target"')
    open(sb_path, "w", encoding="utf-8").write(sb)

# 8. AppDelegate: Spotlight results, "Search in App" and Siri Suggestions open an entry -------
ad_path = os.path.join(APP, "AppDelegate.swift")
ad = open(ad_path, encoding="utf-8").read()
HOOK = "if EntryRouter.handle(userActivity) { return true }"
if HOOK not in ad:
    call = "return ApplicationDelegateProxy.shared.application(application, continue: userActivity, restorationHandler: restorationHandler)"
    if ad.count(call) != 1:
        die("AppDelegate.swift: continue-userActivity call not found exactly once")
    ad = ad.replace(call, HOOK + "\n        " + call)
    if "performActionFor" in ad:
        die("AppDelegate.swift already implements performActionFor; QuickActionsPlugin.swift would duplicate it")
    open(ad_path, "w", encoding="utf-8").write(ad)

open(PBX, "w", encoding="utf-8").write(pbx)

# Checks ---------------------------------------------------------------------------------
pbx = open(PBX, encoding="utf-8").read()
assert pbx.count(FILE_ID) == 3 and pbx.count(BUILD_ID) == 2, "PrivacyInfo not wired into the project"
assert '"1,2"' not in pbx
assert re.findall(r"IPHONEOS_DEPLOYMENT_TARGET = ([0-9.]+);", pbx) and set(re.findall(r"IPHONEOS_DEPLOYMENT_TARGET = ([0-9.]+);", pbx)) == {MIN_IOS}
assert Image.open(os.path.join(icon_dir, names[0])).mode == "RGB"
for name, fid, bid in SWIFT:
    assert pbx.count(fid) == 3 and pbx.count(bid) == 2, f"{name} not wired into the project"
    assert os.path.exists(os.path.join(APP, name)), f"{name} not copied"
assert 'customClass="AppViewController"' in open(sb_path, encoding="utf-8").read()
assert open(ad_path, encoding="utf-8").read().count(HOOK) == 1
with open(plist_path, "rb") as fh:
    _i = plistlib.load(fh)
assert len(_i["UIApplicationShortcutItems"]) == 2 and _i["CoreSpotlightContinuation"] is True
print(f"native-setup: icon, {count} splash images, Info.plist, iPhone-only, PrivacyInfo.xcprivacy, iOS {MIN_IOS}, {len(SWIFT)} native sources (Spotlight, App Intents, quick actions, haptics, share, print), AppDelegate routing done")
