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

`scripts/native-setup.py` then prepares the generated Xcode project: TOXCARD icon (alpha removed),
launch screen, `ITSAppUsesNonExemptEncryption = NO`, iPhone only, and `PrivacyInfo.xcprivacy`.

In CI: Actions → "iOS build (App Store reference)" → Run workflow. Manual only.
Signing is automatic through an App Store Connect API key (Admin role). Secrets:
`APPSTORE_API_KEY_ID`, `APPSTORE_API_ISSUER_ID`, `APPSTORE_API_PRIVATE_KEY`, `APPLE_TEAM_ID`.
The build number is the workflow run number; the App Store version is a workflow input.

## Publisher

Published under HAKOYA LLC's Apple Developer account. Bundle ID `com.hakoya.toxcard`.

## Icons

`icons/icon-1024.png` is the App Store icon (square, no transparency). `icons/apple-touch-icon-180.png`
is the home-screen icon. Both are rendered from `icon.svg`.
