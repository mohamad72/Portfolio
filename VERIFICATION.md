# Verification status

Generated on 2026-09-11.

## Checks completed in this artifact environment

- `pubspec.yaml`, `analysis_options.yaml`, and `.github/workflows/flutter-ci.yml` parse as YAML.
- All non-generated relative Dart imports in `lib/` and `test/` resolve to existing files.
- `git diff --check` reports no whitespace errors.
- `tool/bootstrap.sh` passes `bash -n` syntax validation.
- No `.har` capture is present inside the project tree.
- A targeted scan found no literal captured JWT/Bearer credential in project files.
- The only source-visible password intentionally present is the LAN portfolio-sharing password `portfolio123`, paired with username `viewer`, per the requested product behavior. It is unrelated to the Mofid account.
- The LAN sharing implementation is read-only: it serves a cached portfolio snapshot through `GET /portfolio` and does not expose order-placement endpoints or the Mofid access token.

## Checks that cannot be executed in this environment

The artifact environment does not have the Flutter or Dart SDK installed, so these commands have **not** been executed here:

```bash
dart format lib test
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug
```

The included GitHub Actions workflow installs Flutter stable and runs bootstrap, formatting, analysis, tests, and a debug APK build after the repository is available to a writable GitHub/Codex environment.

## Device verification still required

- Complete Mofid OIDC/PKCE login on a real Android device.
- Confirm Mofid money/price unit mapping against the live EasyTrader UI.
- Start LAN sharing on one Android phone and connect from a second phone on the same Wi-Fi using the displayed host address and `viewer / portfolio123`.
- Confirm Android/OEM networking permits the local HTTP server while the app is active.
- Confirm the generated debug APK installs and launches.
