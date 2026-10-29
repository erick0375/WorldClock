#!/usr/bin/env bash
set -euo pipefail

export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="/tmp/WorldClockBuild"
APP_BUNDLE="$BUILD_DIR/WorldClock.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_PLUGINS="$APP_CONTENTS/PlugIns"

WIDGET_BUNDLE="$APP_PLUGINS/WorldClockWidgetExtension.appex"
WIDGET_CONTENTS="$WIDGET_BUNDLE/Contents"
WIDGET_MACOS="$WIDGET_CONTENTS/MacOS"
WIDGET_RESOURCES="$WIDGET_CONTENTS/Resources"

echo "==> Cleaning previous build artifacts..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES" "$APP_PLUGINS" "$WIDGET_MACOS" "$WIDGET_RESOURCES"

echo "==> Generating custom AppIcon.icns..."
ICONSET_DIR="$BUILD_DIR/AppIcon.iconset"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"
MASTER_PNG="$BUILD_DIR/AppIcon_1024.png"
xcrun swift "$PROJECT_DIR/generate_icon.swift" "$MASTER_PNG"

for sz in 16 32 128 256 512; do
  sips -z $sz $sz "$MASTER_PNG" --out "$ICONSET_DIR/icon_${sz}x${sz}.png" >/dev/null
  sz2=$((sz * 2))
  sips -z $sz2 $sz2 "$MASTER_PNG" --out "$ICONSET_DIR/icon_${sz}x${sz}@2x.png" >/dev/null
done

iconutil -c icns "$ICONSET_DIR" -o "$APP_RESOURCES/AppIcon.icns"
cp "$APP_RESOURCES/AppIcon.icns" "$WIDGET_RESOURCES/AppIcon.icns"

SDK_PATH="$(xcrun --show-sdk-path)"
TARGET_ARCH="$(uname -m)-apple-macos14.0"

echo "==> Compiling WorldClockWidgetExtension.appex (WidgetKit Extension)..."
xcrun swiftc \
  -sdk "$SDK_PATH" \
  -target "$TARGET_ARCH" \
  -O \
  -parse-as-library \
  -application-extension \
  -Xlinker -e -Xlinker _NSExtensionMain \
  -framework SwiftUI \
  -framework WidgetKit \
  -framework Foundation \
  "$PROJECT_DIR/Shared/WorldClockModels.swift" \
  "$PROJECT_DIR/Shared/WidgetMultiClockGridView.swift" \
  "$PROJECT_DIR/WorldClockWidget/WorldClockWidget.swift" \
  -o "$WIDGET_MACOS/WorldClockWidgetExtension"

cat > "$WIDGET_CONTENTS/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleDisplayName</key>
	<string>World Clock Widget</string>
	<key>CFBundleExecutable</key>
	<string>WorldClockWidgetExtension</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>com.worldclock.macos.widget</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>WorldClockWidgetExtension</string>
	<key>CFBundlePackageType</key>
	<string>XPC!</string>
	<key>CFBundleShortVersionString</key>
	<string>1.2</string>
	<key>CFBundleSupportedPlatforms</key>
	<array>
		<string>MacOSX</string>
	</array>
	<key>CFBundleVersion</key>
	<string>3</string>
	<key>NSHumanReadableCopyright</key>
	<string>© 2026 Eric K • MIT License</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>NSExtension</key>
	<dict>
		<key>NSExtensionPointIdentifier</key>
		<string>com.apple.widgetkit-extension</string>
	</dict>
</dict>
</plist>
EOF

echo "==> Compiling WorldClock.app (Main macOS Application)..."
xcrun swiftc \
  -sdk "$SDK_PATH" \
  -target "$TARGET_ARCH" \
  -O \
  -parse-as-library \
  -framework SwiftUI \
  -framework AppKit \
  -framework WidgetKit \
  -framework Combine \
  "$PROJECT_DIR/Shared/WorldClockModels.swift" \
  "$PROJECT_DIR/Shared/DigitalClockCardView.swift" \
  "$PROJECT_DIR/Shared/WidgetMultiClockGridView.swift" \
  "$PROJECT_DIR/WorldClockApp/WorldClockStore.swift" \
  "$PROJECT_DIR/WorldClockApp/DesktopFloatingWidgetView.swift" \
  "$PROJECT_DIR/WorldClockApp/AddCitySheetView.swift" \
  "$PROJECT_DIR/WorldClockApp/ContentView.swift" \
  "$PROJECT_DIR/WorldClockApp/WorldClockApp.swift" \
  -o "$APP_MACOS/WorldClock"

cat > "$APP_CONTENTS/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleDisplayName</key>
	<string>World Clock</string>
	<key>CFBundleExecutable</key>
	<string>WorldClock</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleIdentifier</key>
	<string>com.worldclock.macos</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>WorldClock</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.2</string>
	<key>CFBundleVersion</key>
	<string>3</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSHumanReadableCopyright</key>
	<string>Created by Eric K • MIT License</string>
</dict>
</plist>
EOF

echo "==> Code-signing app and embedded WidgetKit extension..."
find "$APP_BUNDLE" -name '._*' -delete 2>/dev/null || true
xattr -cr "$PROJECT_DIR" "$APP_BUNDLE" 2>/dev/null || true
codesign --force --sign - --entitlements "$PROJECT_DIR/WorldClockWidget/WorldClockWidget.entitlements" "$WIDGET_BUNDLE"
xattr -cr "$PROJECT_DIR" "$APP_BUNDLE" 2>/dev/null || true
codesign --force --sign - --entitlements "$PROJECT_DIR/WorldClockApp/WorldClockApp.entitlements" "$APP_BUNDLE"

if [ -d "/Applications" ] && [ -w "/Applications" ]; then
  echo "==> Installing WorldClock.app to /Applications for macOS WidgetKit discovery..."
  rm -rf "/Applications/WorldClock.app"
  cp -R "$APP_BUNDLE" "/Applications/WorldClock.app"
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "/Applications/WorldClock.app" || true
  pluginkit -a "/Applications/WorldClock.app/Contents/PlugIns/WorldClockWidgetExtension.appex" || true
fi

mkdir -p "$PROJECT_DIR/build"
rm -rf "$PROJECT_DIR/build/WorldClock.app"
cp -R "$APP_BUNDLE" "$PROJECT_DIR/build/WorldClock.app"

echo "==> Packaging WorldClock.dmg installer..."
DMG_STAGING="$BUILD_DIR/dmg_staging"
DMG_PATH="$PROJECT_DIR/build/WorldClock.dmg"
rm -rf "$DMG_STAGING" "$DMG_PATH"
mkdir -p "$DMG_STAGING"
cp -R "$APP_BUNDLE" "$DMG_STAGING/WorldClock.app"
ln -s /Applications "$DMG_STAGING/Applications"
hdiutil create \
  -volname "World Clock" \
  -srcfolder "$DMG_STAGING" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

echo "==> Build succeeded!"
echo "    App Bundle: /Applications/WorldClock.app"
echo "    DMG Image : $DMG_PATH"
