# FIT Repair Studio

FIT Repair Studio is an open-source native macOS app for inspecting, editing,
repairing, and saving `.fit` activity files.

It is intended for cyclists, runners, triathletes, coaches, and activity-data
users who need to recover malformed FIT files that fail to upload to services
such as Strava, TrainingPeaks, intervals.icu, or GoldenCheetah.

## Links

- Website: https://fitrepairstudio.site/
- Download for macOS: https://fit-repair-studio.b-cdn.net/FITRepairStudio-mac.zip
- Source code: https://github.com/bradacz/FITRepairStudio
- Voluntary support: https://www.buymeacoffee.com/mariantomay

## Open Source And Voluntary Support

FIT Repair Studio is free and open-source software released under the MIT
License. You can download, use, build, inspect, modify, and share the source
code under the terms in [LICENSE](LICENSE).

Payment is not required to download or use the app. Voluntary contributions are
welcome and help cover Apple Developer Program membership, notarized macOS
builds, hosting, and maintenance. Donations do not unlock extra features and do
not change how issues or pull requests are handled.

## Privacy

FIT Repair Studio processes activity files locally on your Mac. The app does
not require an account and does not upload FIT files to FIT Repair Studio
servers.

FIT files can contain sensitive location, health, device, and training data.
Do not publish real activity files in GitHub issues or pull requests unless you
have removed private data and are comfortable making the file public.

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

## Contributing

Issues and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md)
before opening a pull request, especially the notes about private activity
files and test data.

## Support

Use GitHub issues for reproducible bugs and feature requests. For private
support or security reports, see [SUPPORT.md](SUPPORT.md) and
[SECURITY.md](SECURITY.md).

## License

FIT Repair Studio is released under the MIT License. See [LICENSE](LICENSE).
