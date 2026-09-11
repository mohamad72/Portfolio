# Verification status

Generated on 2026-09-11.

Checks completed in the artifact environment:

- `pubspec.yaml`, `analysis_options.yaml`, and `.github/workflows/flutter-ci.yml` parse as YAML.
- All non-generated relative Dart imports resolve to files.
- Required bootstrap/source/test/workflow files are present.
- A targeted scan found no captured Bearer token, access token, or request-verification token in app source/tests/README.
- `tool/bootstrap.sh` passes `bash -n` syntax validation.
- Working tree was clean after generation.

Checks not executable in the artifact environment:

- `dart format`
- `flutter analyze`
- `flutter test`
- `flutter build apk`

Reason: Flutter and Dart SDKs are not installed in the artifact environment.

The included GitHub Actions workflow installs Flutter stable and runs bootstrap, formatting verification, analysis, tests, and a debug APK build after the files are uploaded to GitHub.
