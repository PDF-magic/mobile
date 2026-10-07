#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
GENERATED="$TMP_ROOT/generated"
BACKUP="$TMP_ROOT/overlays"

cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

mkdir -p "$BACKUP/android" "$BACKUP/ios"

backup_if_present() {
  local source="$1"
  local target="$2"
  if [[ -f "$source" ]]; then
    mkdir -p "$(dirname "$target")"
    cp "$source" "$target"
  fi
}

restore_if_present() {
  local source="$1"
  local target="$2"
  if [[ -f "$source" ]]; then
    mkdir -p "$(dirname "$target")"
    cp "$source" "$target"
  fi
}

backup_if_present   "$ROOT/android/app/src/main/AndroidManifest.xml"   "$BACKUP/android/app/src/main/AndroidManifest.xml"
backup_if_present   "$ROOT/android/app/src/main/kotlin/org/pdfmagic/mobile/MainActivity.kt"   "$BACKUP/android/app/src/main/kotlin/org/pdfmagic/mobile/MainActivity.kt"
backup_if_present   "$ROOT/android/app/src/main/res/values/styles.xml"   "$BACKUP/android/app/src/main/res/values/styles.xml"
backup_if_present   "$ROOT/android/app/src/main/res/values-night/styles.xml"   "$BACKUP/android/app/src/main/res/values-night/styles.xml"
backup_if_present   "$ROOT/android/app/src/main/res/drawable/launch_background.xml"   "$BACKUP/android/app/src/main/res/drawable/launch_background.xml"
backup_if_present "$ROOT/android/README.md" "$BACKUP/android/README.md"

for file in Info.plist AppDelegate.swift SceneDelegate.swift Runner-Bridging-Header.h; do
  backup_if_present "$ROOT/ios/Runner/$file" "$BACKUP/ios/Runner/$file"
done
backup_if_present "$ROOT/ios/README.md" "$BACKUP/ios/README.md"

flutter create   --empty   --no-pub   --platforms=android,ios,linux   --org org.pdfmagic   --project-name mobile   "$GENERATED"

mkdir -p "$ROOT/android" "$ROOT/ios" "$ROOT/linux"
cp -R "$GENERATED/android/." "$ROOT/android/"
cp -R "$GENERATED/ios/." "$ROOT/ios/"
cp -R "$GENERATED/linux/." "$ROOT/linux/"
cp "$GENERATED/.metadata" "$ROOT/.metadata"

restore_if_present   "$BACKUP/android/app/src/main/AndroidManifest.xml"   "$ROOT/android/app/src/main/AndroidManifest.xml"
restore_if_present   "$BACKUP/android/app/src/main/kotlin/org/pdfmagic/mobile/MainActivity.kt"   "$ROOT/android/app/src/main/kotlin/org/pdfmagic/mobile/MainActivity.kt"
restore_if_present   "$BACKUP/android/app/src/main/res/values/styles.xml"   "$ROOT/android/app/src/main/res/values/styles.xml"
restore_if_present   "$BACKUP/android/app/src/main/res/values-night/styles.xml"   "$ROOT/android/app/src/main/res/values-night/styles.xml"
restore_if_present   "$BACKUP/android/app/src/main/res/drawable/launch_background.xml"   "$ROOT/android/app/src/main/res/drawable/launch_background.xml"
restore_if_present "$BACKUP/android/README.md" "$ROOT/android/README.md"

for file in Info.plist AppDelegate.swift SceneDelegate.swift Runner-Bridging-Header.h; do
  restore_if_present "$BACKUP/ios/Runner/$file" "$ROOT/ios/Runner/$file"
done
restore_if_present "$BACKUP/ios/README.md" "$ROOT/ios/README.md"

echo "Generated Android, iOS, and Linux hosts and restored PDF Magic platform integrations."
