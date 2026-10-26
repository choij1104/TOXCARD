# TOXCARD — App Store build

The App Store build and the web build come from the same `index.html`. The App Store build
adds one meta tag (`toxcard-build=reference`). With it:

- every dose is shown exactly as its source states it,
- the weight-based calculator, the weight and height fields, and the computed dose panels are absent,
- everything else — toxins, agents, protocols, pitfalls, toxidromes, search, saved entries — is identical.

This keeps the App Store build within App Store Review Guideline 1.4.2, which limits drug
dosage calculators to approved entities. The web build keeps the calculator.

## Build

```
cd ios
npm install
npm run sync        # builds ios/www and syncs the Xcode project
```

`ios/www` and `ios/ios` are generated on every build and are not committed.

The reference bundle also:
- bundles the IBM Plex fonts from `@fontsource` (SIL OFL 1.1) in place of the Google Fonts links,
  so the app makes no network request;
- replaces `privacy.html` with `ios/privacy-reference.html`, which describes this build.

- adds the iOS layer, `ios/app/native.css` and `ios/app/native.js` (with Capacitor's `capacitor.js`):
  the iPhone interface (Cards, Antidotes, Triage, Pinned tabs, large titles, grouped lists, A–Z
  index, settings sheet) and the bridge to the native code. It renders every card with the web
  build's own `viewToxin()` / `doseTable()` / `txdHTML()`; the build fails if the embedded data or
  those functions differ from the repository's `index.html`;
- removes the online dataset check and the service worker, and fails if any fetch/XHR is left.

`scripts/native-setup.py` then prepares the generated Xcode project: TOXCARD iOS icon
(`ios/icons/icon-1024.png`, drawn by `scripts/make-icon.py`, alpha removed), light and dark launch
screen, `ITSAppUsesNonExemptEncryption = NO`, iPhone only, `PrivacyInfo.xcprivacy`, static quick
actions, `NSUserActivityTypes`, `CoreSpotlightContinuation`, and the Swift sources in `ios/native/`:

| File | What it does |
|---|---|
| `SpotlightPlugin.swift` | Core Spotlight index of every toxin and agent; current card offered to Siri Suggestions |
| `ToxcardIntents.swift` | App Intents and App Shortcuts: look up an antidote / a toxin, toxidrome triage, search |
| `QuickActionsPlugin.swift` | Home Screen quick actions, dynamic ones for pinned cards |
| `EntryRouter.swift` | Routes Spotlight, Siri, quick actions into the web layer (`Launch.take()`) |
| `NativeUIPlugin.swift` | Haptics, window appearance, share sheet, AirPrint of a card |
| `AppViewController.swift` | Registers the plugins; web view ground colour |

## Checks before upload

```
cd ios
npm run build:www
npm run qa          # loads ios/www behind a simulated native bridge and runs every flow
npm run shots       # App Store screenshots -> ios/store/screenshots (1206x2622)
```

Store texts: `ios/store/description.txt`, `promo.txt`, `review-notes.txt`.

In CI: Actions → "iOS build (App Store reference)" → Run workflow. Manual only.
Signing is automatic through an App Store Connect API key (Admin role). Secrets:
`APPSTORE_API_KEY_ID`, `APPSTORE_API_ISSUER_ID`, `APPSTORE_API_PRIVATE_KEY`, `APPLE_TEAM_ID`.
The build number is the workflow run number; the App Store version is a workflow input.

## Publisher

Published under HAKOYA LLC's Apple Developer account. Bundle ID `com.hakoya.toxcard`.

## Icons

The iOS app icon is `ios/icons/icon-1024.png` (square, no transparency), drawn by `ios/scripts/make-icon.py`.
The web icons (`icons/`, rendered from `icon.svg`) are unchanged.
