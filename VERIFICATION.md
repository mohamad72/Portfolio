# Verification status

Generated on 2026-09-11.

## Checks completed in this artifact environment

- `pubspec.yaml`, `analysis_options.yaml`, and `.github/workflows/flutter-ci.yml` parse as YAML.
- All non-generated relative Dart imports in `lib/` and `test/` resolve to existing files.
- `git diff --check` reports no whitespace errors.
- `tool/bootstrap.sh` passes `bash -n` syntax validation.
- No `.har` capture is present inside the project tree.
- A targeted scan found no literal captured Mofid/iPasargad JWT, Bearer token, session cookie, login name, or password from the HAR captures in project files.
- The only source-visible password intentionally present is the LAN portfolio-sharing password `portfolio123`, paired with username `viewer`, per the requested product behavior. It is unrelated to the Mofid account.
- The iPasargad adapter contains only public endpoint paths and the cookie name `otauth-FU`; no captured token or personal holding values are embedded.
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
- Complete iPasargad captcha/login on a real Android device and confirm the observed `otauth-FU` cookie contract works outside the browser session.
- The browser HAR already contained a `cookiesession1` WAF/session cookie whose creation was not captured; verify whether direct app login works without it before treating the iPasargad login path as production-ready.
- Compare iPasargad Riton sell price/value against the live UI to confirm rial→toman conversion exactly once.
- Verify that the same ISIN connected through Mofid and iPasargad appears as two separate account-labelled cards.
- Confirm Mofid money/price unit mapping against the live EasyTrader UI.
- Start LAN sharing on one Android phone and connect from a second phone on the same Wi-Fi using the displayed host address and `viewer / portfolio123`.
- Confirm Android/OEM networking permits the local HTTP server while the app is active.
- Confirm the generated debug APK installs and launches.
