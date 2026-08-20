#!/usr/bin/env bash
# Build Android release APK and AAB
# Ensure keystore is configured in android/app/build.gradle
set -e

# Clean previous builds
flutter clean

# Build APK
flutter build apk --release

# Build App Bundle (AAB) for Play Store
flutter build appbundle --release

echo "Release builds completed."
