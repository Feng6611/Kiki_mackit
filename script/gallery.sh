#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR/Examples/ComponentGallery"
swift build
BIN_DIR="$(swift build --show-bin-path)"
APP_DIR="$ROOT_DIR/.build/Kiki Component Gallery.app"
mkdir -p "$APP_DIR/Contents/MacOS"
cp "$BIN_DIR/KikiComponentGallery" "$APP_DIR/Contents/MacOS/KikiComponentGallery.next"
mv -f "$APP_DIR/Contents/MacOS/KikiComponentGallery.next" "$APP_DIR/Contents/MacOS/KikiComponentGallery"
cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>dev.kiki.ComponentGallery</string>
<key>CFBundleExecutable</key><string>KikiComponentGallery</string>
<key>CFBundleName</key><string>Kiki Component Gallery</string>
<key>CFBundlePackageType</key><string>APPL</string>
</dict></plist>
PLIST
/usr/bin/codesign --force --sign - "$APP_DIR"
/usr/bin/open "$APP_DIR"
