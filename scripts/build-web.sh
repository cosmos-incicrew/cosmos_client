#!/usr/bin/env bash
set -euo pipefail

if [[ $# -gt 1 ]]; then
  echo "usage: scripts/build-web.sh [dart-define-json]" >&2
  exit 2
fi

readonly defines_file="${1:-dart_defines/prod.json}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK is required. Install Flutter 3.44 or newer." >&2
  exit 1
fi

if [[ ! -f "$defines_file" ]]; then
  echo "Missing $defines_file. Copy dart_defines/prod.example.json and fill it first." >&2
  exit 1
fi

flutter pub get
flutter analyze
flutter test
flutter build web --release --dart-define-from-file="$defines_file"

# Vercel must serve index.html for Flutter's client-side routes.
cp vercel.json build/web/vercel.json

echo "Web build is ready in build/web"
