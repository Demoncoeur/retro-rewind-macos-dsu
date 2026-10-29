#!/bin/sh
# Compile l'app « WiiU Pro.app » et l'outil wiiu-pro-dsu avec les Command Line Tools
# (Xcode non requis). Signature ad hoc.
set -e
cd "$(dirname "$0")"
mkdir -p build

# Outil en ligne de commande
swiftc -O -swift-version 5 -module-cache-path build/ModuleCache \
    -o build/wiiu-pro-dsu Sources/Core/*.swift Sources/CLI/*.swift \
    -framework IOBluetooth \
    -Xlinker -sectcreate -Xlinker __TEXT -Xlinker __info_plist -Xlinker Info.plist
codesign --force --sign - --identifier com.wiiupromac.dsu build/wiiu-pro-dsu

# Application graphique
APP="build/WiiU Pro.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp AppInfo.plist "$APP/Contents/Info.plist"
mkdir -p "$APP/Contents/Resources"
if [ "${WIIUPRO_PORTABLE_BUILD:-0}" = "1" ]; then
    echo "WIIUPRO_APP_SUPPORT" > "$APP/Contents/Resources/project-path.txt"
else
    pwd > "$APP/Contents/Resources/project-path.txt"
fi
cp ../patch-and-build.sh "$APP/Contents/Resources/patch-and-build.sh"
swiftc -module-cache-path build/ModuleCache -framework AppKit \
    Resources/GenerateAppIcon.swift -o build/generate-app-icon
build/generate-app-icon "$APP/Contents/Resources/AppIcon.icns"
swiftc -O -swift-version 5 -parse-as-library -module-cache-path build/ModuleCache \
    -o "$APP/Contents/MacOS/WiiUPro" Sources/Core/*.swift Sources/App/*.swift \
    -framework IOBluetooth -framework SwiftUI -framework AppKit
xattr -cr "$APP"
codesign --force --sign - "$APP"
xattr -d com.apple.FinderInfo "$APP" 2>/dev/null || true

echo "OK : build/wiiu-pro-dsu et $APP"
