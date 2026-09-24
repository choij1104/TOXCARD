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

In CI: Actions → "iOS build (App Store reference)" → Run workflow. Manual only.

## Publisher

Published under HAKOYA LLC's Apple Developer account. Bundle ID `com.hakoya.toxcard`.

## Icons

`icons/icon-1024.png` is the App Store icon (square, no transparency). `icons/apple-touch-icon-180.png`
is the home-screen icon. Both are rendered from `icon.svg`.
