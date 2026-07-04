# Contributing

Thanks for improving FIT Repair Studio.

## Good Contributions

- FIT parsing, validation, and repair fixes.
- macOS UI improvements that follow the existing SwiftUI structure.
- Localization fixes for Czech or English.
- Documentation improvements.
- Small reproducible test cases that do not expose private activity data.

## Local Development

```sh
swift build
./script/build_and_run.sh
```

Use the packaging scripts only when you need to verify app bundle behavior:

```sh
./script/package_mac.sh
```

Developer ID signing and notarization require local Apple credentials and are
not required for ordinary pull requests.

## Pull Request Guidelines

- Keep changes focused.
- Explain the malformed FIT scenario or UI behavior being fixed.
- Include before/after notes when changing repair logic.
- Do not commit generated build output, notarized ZIPs, `.fit` files, `.csv`
  exports, logs, credentials, or `.env` files.
- Run `swift build` before opening a pull request when the change touches Swift
  code.

## Test Data And Privacy

FIT files often contain GPS tracks, timestamps, device identifiers, heart-rate
data, power data, and other personal training information. Do not attach real
activity files to public GitHub issues or pull requests unless they have been
anonymized and you are comfortable making them public.

Prefer synthetic, minimized, or manually redacted samples.

## Voluntary Contributions

Financial support is optional and never required for code contributions, issue
reports, downloads, or support. Donations do not affect review priority.
