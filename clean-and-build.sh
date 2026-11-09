#!/bin/bash

set -e

#clean flutter
flutter clean
flutter pub get

#build web
flutter build web

#build universal
flutter build appbundle

bundletool build-apks \
  --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=build/app/outputs/bundle/release/app-release-universal.apks \
  --mode=universal

mv \
  build/app/outputs/bundle/release/app-release-universal.apks \
  build/app/outputs/bundle/release/app-release-universal.zip

#build macos PUT LAST WILL ALWAYS FAIL
flutter precache --macos
flutter build macos

echo "-----------------------------"
echo ""
echo "Cleaned and builded everything successfully!"
echo ""
echo "-----------------------------"