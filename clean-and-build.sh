#!/bin/bash

set -e

#clean flutter
flutter clean
flutter pub get
flutter pub run flutter_launcher_icons

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

OS="`uname`"
case $OS in
  'Linux')
    OS='Linux'
    ;;
  'FreeBSD')
    OS='FreeBSD'
    ;;
  'WindowsNT')
    OS='Windows'
    #build windows
    flutter build windows
    ;;
  'Darwin') 
    OS='Mac'
    #build macos
    flutter precache --macos
    flutter build macos
    ;;
  'SunOS')
    OS='Solaris'
    ;;
  'AIX') ;;
  *) ;;
esac

echo "-----------------------------"
echo ""
echo "Cleaned and builded everything successfully!"
echo ""
echo "-----------------------------"