#!/usr/bin/env bash
# Construit l'APK arm64 (< 25 Mo visé) et l'APK multi-ABI.
set -euo pipefail
cd "$(dirname "$0")/.."

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter introuvable dans PATH. Installez le SDK stable puis relancez." >&2
  exit 1
fi

flutter pub get
flutter test
flutter build apk --release --target-platform android-arm64

mkdir -p artifacts
cp -f build/app/outputs/flutter-apk/app-release.apk \
  artifacts/skull-king-scorekeeper-arm64-release.apk
cp -f build/app/outputs/flutter-apk/app-release.apk \
  artifacts/skull-king-scorekeeper.apk

flutter build apk --release
cp -f build/app/outputs/flutter-apk/app-release.apk \
  artifacts/skull-king-scorekeeper-fat-release.apk

echo "APK prêts :"
ls -lh artifacts/*.apk
