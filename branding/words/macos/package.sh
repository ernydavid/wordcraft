#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
. "$ROOT/packaging/env.sh"
export MACOSX_DEPLOYMENT_TARGET=11.0
WORK="$CARGO_TARGET_DIR/words-macos-stage"
APP="$WORK/Words.app"
STAGE="$WORK/dmg-stage"
DMG="$DIST/Words-$VERSION-macOS-universal.dmg"
rm -rf "$WORK"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/Licenses" "$STAGE"
cargo build --release --locked -p wordcraft --target aarch64-apple-darwin --target x86_64-apple-darwin
lipo -create "$CARGO_TARGET_DIR/aarch64-apple-darwin/release/wordcraft" "$CARGO_TARGET_DIR/x86_64-apple-darwin/release/wordcraft" -output "$APP/Contents/MacOS/Words"
chmod +x "$APP/Contents/MacOS/Words"
cp "$ROOT/branding/words/generated/words.icns" "$APP/Contents/Resources/Words.icns"
for f in LICENSE-MIT LICENSE-APACHE NOTICE ATTRIBUTION.md; do cp "$ROOT/$f" "$APP/Contents/Resources/Licenses/"; done
sed -e "s/@SHORT_VERSION@/${VERSION%%-*}/g" "$HERE/Info.plist.in" > "$APP/Contents/Info.plist"
plutil -lint "$APP/Contents/Info.plist"
xattr -cr "$APP"
IDENTITY="${MACOS_SIGN_IDENTITY:--}"
if [[ "$IDENTITY" == '-' ]]; then
  codesign --force --sign - --timestamp=none "$APP/Contents/MacOS/Words"
  codesign --force --sign - --timestamp=none "$APP"
  echo 'WARNING: ad-hoc signed; not intended for public distribution'
else
  KC=()
  if [[ -n "${MACOS_KEYCHAIN:-}" ]]; then KC=(--keychain "$MACOS_KEYCHAIN"); fi
  codesign --force --options runtime --timestamp --sign "$IDENTITY" "${KC[@]}" "$APP/Contents/MacOS/Words"
  codesign --force --options runtime --timestamp --sign "$IDENTITY" "${KC[@]}" "$APP"
fi
codesign --verify --deep --strict "$APP"
if [[ "$IDENTITY" != '-' && -n "${APPLE_ID:-}" && -n "${APPLE_PASSWORD:-}" && -n "${APPLE_TEAM_ID:-}" ]]; then
  ditto -c -k --keepParent "$APP" "$WORK/Words-notarize.zip"
  xcrun notarytool submit "$WORK/Words-notarize.zip" --apple-id "$APPLE_ID" --password "$APPLE_PASSWORD" --team-id "$APPLE_TEAM_ID" --wait
  xcrun stapler staple "$APP"
fi
ditto "$APP" "$STAGE/Words.app"
ln -s /Applications "$STAGE/Applications"
hdiutil create -srcfolder "$STAGE" -volname Words -fs HFS+ -format UDZO -ov "$DMG"
codesign --verify --deep --strict "$STAGE/Words.app"
if [[ "$IDENTITY" != '-' ]]; then
  codesign --force --timestamp --sign "$IDENTITY" "$DMG"
  if [[ -n "${APPLE_ID:-}" && -n "${APPLE_PASSWORD:-}" && -n "${APPLE_TEAM_ID:-}" ]]; then
    xcrun notarytool submit "$DMG" --apple-id "$APPLE_ID" --password "$APPLE_PASSWORD" --team-id "$APPLE_TEAM_ID" --wait
    xcrun stapler staple "$DMG"
  fi
fi
echo "Created $DMG"
