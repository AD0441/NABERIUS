#!/usr/bin/env bash
set -euo pipefail
MODE="${1:-run}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export CLANG_MODULE_CACHE_PATH="${TMPDIR:-/tmp}/naberius-clang"
export SWIFTPM_MODULECACHE_OVERRIDE="${TMPDIR:-/tmp}/naberius-swift"
BUILD_DIR="${NABERIUS_BUILD_DIR:-$ROOT_DIR/.build}"
STAGE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/NaberiusBuild.XXXXXX")"
trap 'rm -rf "$STAGE_DIR"' EXIT
APP="$STAGE_DIR/Naberius.app"
if [[ "$MODE" != "--build-only" ]]; then pkill -x Naberius >/dev/null 2>&1 || true; fi
swift build --scratch-path "$BUILD_DIR" --disable-sandbox
BIN_DIR="$(swift build --scratch-path "$BUILD_DIR" --show-bin-path --disable-sandbox)"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/Naberius" "$APP/Contents/MacOS/Naberius"
cp -R "$BIN_DIR/Naberius_NaberiusCore.bundle" "$APP/Contents/Resources/"
if [[ ! -f Resources/AppIcon.icns ]]; then
    xcrun swift script/make_brand.swift
    python3 script/make_icns.py
fi
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp -R Sources/NaberiusCore/Localization/es.lproj "$APP/Contents/Resources/"
mkdir -p "$APP/Contents/Resources/Licenses"
cp LICENSE COPYRIGHT THIRD_PARTY_NOTICES.md "$APP/Contents/Resources/Licenses/"
cp docs/licenses/* "$APP/Contents/Resources/Licenses/"
printf '%s\n' 'Corresponding source: https://github.com/AD0441/NABERIUS' > "$APP/Contents/Resources/Licenses/SOURCE.txt"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Naberius</string>
<key>CFBundleIdentifier</key><string>cl.sebastianpasten.Naberius</string>
<key>CFBundleName</key><string>Naberius</string>
<key>CFBundleDisplayName</key><string>Naberius</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.4.0</string>
<key>CFBundleVersion</key><string>4</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>NSHighResolutionCapable</key><true/>
<key>CFBundleDevelopmentRegion</key><string>es</string>
<key>CFBundleLocalizations</key><array><string>es</string></array>
<key>NSHumanReadableCopyright</key><string>Creado por Sebastián Pastén F.</string>
<key>CFBundleDocumentTypes</key><array><dict><key>CFBundleTypeName</key><string>Documento Naberius</string><key>CFBundleTypeRole</key><string>Editor</string><key>LSItemContentTypes</key><array><string>cl.sebastianpasten.nab-document</string></array></dict></array>
<key>UTExportedTypeDeclarations</key><array><dict><key>UTTypeIdentifier</key><string>cl.sebastianpasten.nab-document</string><key>UTTypeDescription</key><string>Documento Naberius</string><key>UTTypeConformsTo</key><array><string>public.data</string></array><key>UTTypeTagSpecification</key><dict><key>public.filename-extension</key><array><string>nab</string></array></dict></dict></array>
</dict></plist>
PLIST
xattr -cr "$APP"
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"
mkdir -p "$ROOT_DIR/dist"
# A clean archive preserves the signed bundle when the source folder is synchronized.
ditto -c -k --norsrc --noextattr --keepParent "$APP" "$ROOT_DIR/dist/Naberius.zip"
if [[ "$MODE" != "--build-only" ]]; then
    RUNTIME_DIR="${NABERIUS_APP_DIR:-$HOME/Applications}"
    RUNTIME_APP="$RUNTIME_DIR/Naberius.app"
    mkdir -p "$RUNTIME_DIR"
    rm -rf "$RUNTIME_APP"
    ditto --norsrc --noextattr "$APP" "$RUNTIME_APP"
    codesign --verify --deep --strict "$RUNTIME_APP"
    APP="$RUNTIME_APP"
    ln -sfn "$RUNTIME_APP" "$ROOT_DIR/Naberius.app"
fi
case "$MODE" in
--build-only) echo "$ROOT_DIR/dist/Naberius.zip" ;;
--debug) lldb -- "$APP/Contents/MacOS/Naberius" --project-root "$ROOT_DIR" ;;
--verify) open -n "$APP" --args --project-root "$ROOT_DIR"; sleep 2; pgrep -x Naberius ;;
--demo) open -n "$APP" --args --demo --project-root "$ROOT_DIR" ;;
--logs|--telemetry) open -n "$APP" --args --project-root "$ROOT_DIR"; /usr/bin/log stream --info --style compact --predicate 'subsystem == "cl.sebastianpasten.Naberius"' ;;
*) open -n "$APP" --args --project-root "$ROOT_DIR" ;;
esac
