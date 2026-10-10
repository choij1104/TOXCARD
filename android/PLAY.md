# TOXCARD — Google Play build

The Google Play build and the App Store build use the same reference web bundle (`ios/www`):
every dose is shown exactly as its source states it, the dose calculator is absent, fonts are
bundled, and the app makes no network request. The only change is the privacy page's platform
line ("Android app").

## Build

GitHub Actions → "Android build (Google Play reference)". Runs on a push to `android-build`
or by manual dispatch. It produces an **unsigned** App Bundle:

- as a workflow artifact, and
- committed to the `android-artifacts` branch at `dist/toxcard-<version>-<code>-unsigned.aab`.

`android/android` and `android/www` are generated on every build and are not committed.
`scripts/native-setup.py` sets the launcher icon (legacy, round, adaptive), the splash, and
the version, and checks the application ID and target SDK.

## Signing

No key is stored in this repository. The bundle is signed with the HAKOYA LLC **upload key**
(held by the account holder, outside GitHub) and then uploaded to Play Console. Google
re-signs it with the app signing key (Play App Signing).

```
jarsigner -keystore toxcard-upload.jks -signedjar toxcard-signed.aab \
  toxcard-<version>-<code>-unsigned.aab toxcard-upload
jarsigner -verify toxcard-signed.aab
```

## Publisher

HAKOYA LLC Google Play developer account. Package `com.hakoya.toxcard`. Capacitor 8,
minSdk 24, targetSdk 36. versionCode = workflow run number.
