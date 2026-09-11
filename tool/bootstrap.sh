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

flutter pub get
dart run build_runner build --delete-conflicting-outputs
