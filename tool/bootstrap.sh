#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK is required." >&2
  exit 1
fi

if [[ ! -d android ]]; then
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT
  flutter create \
    --platforms=android \
    --org com.mohamad72 \
    --project-name portfolio \
    "$tmp_dir/portfolio"
  cp -R "$tmp_dir/portfolio/android" "$ROOT/android"
  cp "$tmp_dir/portfolio/.metadata" "$ROOT/.metadata"
fi

manifest="$ROOT/android/app/src/main/AndroidManifest.xml"
if [[ -f "$manifest" ]]; then
  python3 - "$manifest" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
permission = '    <uses-permission android:name="android.permission.INTERNET"/>\n'
if 'android.permission.INTERNET' not in text:
    text = text.replace(
        '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n',
        '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n' + permission,
        1,
    )
if 'android:usesCleartextTraffic=' not in text:
    text = text.replace(
        '<application\n',
        '<application\n        android:usesCleartextTraffic="true"\n',
        1,
    )
path.write_text(text)
PY
fi

flutter pub get
dart run build_runner build --delete-conflicting-outputs
