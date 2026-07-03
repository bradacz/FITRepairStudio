# FIT Repair Studio

FIT Repair Studio is a native macOS app for inspecting, editing, repairing, and
saving `.fit` activity files.

It is intended for cyclists, runners, triathletes, coaches, and activity-data
power users who need to recover malformed FIT files that fail to upload to
services such as Strava, TrainingPeaks, intervals.icu, or GoldenCheetah.

## Features

- Open native `.fit` activity files on macOS.
- Inspect FIT diagnostics and parsed file structure.
- Detect common FIT CRC/checksum issues.
- Repair FIT header and file CRC values where possible.
- Browse record data in a table.
- Edit selected record fields.
- Save a repaired `.fit` copy.
- Process files locally on the Mac.
- Czech and English localization.

FIT Repair Studio is not affiliated with Garmin, Bryton, Strava, Wahoo, COROS,
TrainingPeaks, Apple, or any other device or platform vendor.

## Requirements

- macOS 13 or newer.
- Xcode command line tools or Xcode for building from source.
- Python with Pillow only when regenerating the app icon from
  `Assets/AppIcon-source.png`.

## Build And Run

Build and run the debug app bundle locally:

```sh
./script/build_and_run.sh
```

Create a distributable universal macOS app bundle and ZIP:

```sh
./script/package_mac.sh
```

Outputs:

```text
dist/FITRepairStudio.app
dist/FITRepairStudio-mac.zip
```

By default, `package_mac.sh` creates an ad-hoc signed build for local testing.

## Developer ID Notarization

To create a notarized public ZIP, first store Apple notary credentials in the
Keychain:

```sh
xcrun notarytool store-credentials FITRepairStudioNotary \
  --apple-id "you@example.com" \
  --team-id "TEAMID" \
  --password "app-specific-password"
```

Then run:

```sh
export FIT_REPAIR_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
export FIT_REPAIR_BUNDLE_ID="com.yourcompany.fitrepairstudio"
./script/notarize_mac.sh
```

The notarized output is:

```text
dist/FITRepairStudio-mac.zip
```

Use `FIT_REPAIR_NOTARY_PROFILE` if the notary credentials are stored under a
different Keychain profile name.

## App Icon

The app icon source and generated assets live in `Assets/`:

```text
Assets/AppIcon-source.png
Assets/AppIcon.png
Assets/AppIcon.icns
```

Regenerate icon assets after changing the source PNG:

```sh
python3 script/create_app_icon.py
```

## Localization

The app includes Czech and English localizations:

```text
Sources/FITRepairStudio/Resources/cs.lproj/Localizable.strings
Sources/FITRepairStudio/Resources/en.lproj/Localizable.strings
```
