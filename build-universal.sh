#!/bin/bash

set -e

flutter build appbundle

bundletool build-apks \
  --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=build/app/outputs/bundle/release/app-release-universal.apks \
  --mode=universal

mv \
  build/app/outputs/bundle/release/app-release-universal.apks \
  build/app/outputs/bundle/release/app-release-universal.zip

echo "-----------------------------"
echo ""
echo "Build completed successfully!"
echo ""
echo "-----------------------------"
