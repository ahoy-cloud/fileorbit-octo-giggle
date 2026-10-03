#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h}"
OUTPUT_DIR="${ROOT_DIR}/dist"
APP_DIR="${OUTPUT_DIR}/FileOrbit.app"

cd "$ROOT_DIR"
mkdir -p ".build"
export CLANG_MODULE_CACHE_PATH="${ROOT_DIR}/.build/ModuleCache"
mkdir -p "$CLANG_MODULE_CACHE_PATH"
/usr/bin/clang -fobjc-arc -fmodules -mmacosx-version-min=13.0 \
  -framework Cocoa -framework CoreGraphics -framework QuartzCore \
  "SourcesObjC/main.m" -o ".build/FileOrbit"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp ".build/FileOrbit" "$APP_DIR/Contents/MacOS/FileOrbit"
cp "Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "Resources/PkgInfo" "$APP_DIR/Contents/PkgInfo"
".build/FileOrbit" --render-icon "$APP_DIR/Contents/Resources/AppIcon.icns"
chmod +x "$APP_DIR/Contents/MacOS/FileOrbit"
codesign --force --deep --sign - "$APP_DIR"

echo "$APP_DIR"
