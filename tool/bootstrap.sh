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
permissions = [
    '    <uses-permission android:name="android.permission.INTERNET"/>\n',
    '    <uses-permission android:name="android.permission.USE_BIOMETRIC"/>\n',
]
for permission in permissions:
    name = permission.split('android:name="', 1)[1].split('"', 1)[0]
    if name not in text:
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

main_activity="$(find "$ROOT/android/app/src/main" -name MainActivity.kt -print -quit 2>/dev/null || true)"
if [[ -n "$main_activity" && -f "$main_activity" ]]; then
  python3 - "$main_activity" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()
text = text.replace(
    'import io.flutter.embedding.android.FlutterActivity',
    'import io.flutter.embedding.android.FlutterFragmentActivity',
)
text = text.replace('FlutterActivity()', 'FlutterFragmentActivity()')
path.write_text(text)
PY
fi

for styles in "$ROOT/android/app/src/main/res/values/styles.xml" "$ROOT/android/app/src/main/res/values-night/styles.xml"; do
  if [[ -f "$styles" ]]; then
    python3 - "$styles" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()
text = re.sub(
    r'(<style\s+name="LaunchTheme"\s+parent=")[^"]+("[^>]*>)',
    r'\1Theme.AppCompat.DayNight\2',
    text,
)
path.write_text(text)
PY
  fi
done

for gradle in "$ROOT/android/app/build.gradle.kts" "$ROOT/android/app/build.gradle"; do
  if [[ -f "$gradle" ]]; then
    python3 - "$gradle" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()
text = text.replace('minSdk = flutter.minSdkVersion', 'minSdk = 24')
text = re.sub(r'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 24', text)
path.write_text(text)
PY
  fi
done

flutter pub get
dart run build_runner build --delete-conflicting-outputs
