#!/usr/bin/env bash

# FST / CenVu | (+84) 842 841 222

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PROJECT="$REPO_ROOT/FishSockTransfer/FishSockTransfer.xcodeproj"
SCHEME="FishSockTransfer"
APP_NAME="FishSockTransfer.app"
PACKAGE_LABEL="macOS13_5plus-arm64"

# Version — override from environment if needed:
# APP_VERSION=1.2.2 BUILD_NUMBER=20260704 ./scripts/package-local-arm64.sh
APP_VERSION="${APP_VERSION:-1.2.2}"
BUILD_NUMBER="${BUILD_NUMBER:-20260704}"
ZIP_NAME="FishSockTransfer-v${APP_VERSION}-b${BUILD_NUMBER}-local-${PACKAGE_LABEL}.zip"

DIST_DIR="$REPO_ROOT/dist"
ZIP_PATH="$DIST_DIR/$ZIP_NAME"
LEGACY_DIST_APP="$DIST_DIR/$APP_NAME"

TEMP_ROOT="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/fst-local-arm64.XXXXXX")"
DERIVED_DATA="$TEMP_ROOT/DerivedData-local-arm64"
STAGED_APP="$TEMP_ROOT/$APP_NAME"
LOCAL_ENTITLEMENTS="$TEMP_ROOT/FishSockTransfer-local.entitlements"

APP_BINARY="$STAGED_APP/Contents/MacOS/FishSockTransfer"
RSYNC_BINARY="$STAGED_APP/Contents/Resources/rsync"
INFO_PLIST="$STAGED_APP/Contents/Info.plist"

cleanup() {
  rm -rf "$TEMP_ROOT"
}
trap cleanup EXIT

fail() {
  echo "ERROR: $*" >&2
  exit 1
}

warn() {
  echo "WARNING: $*" >&2
}

archs_for() {
  /usr/bin/lipo -archs "$1" 2>/dev/null || fail "Could not inspect architectures for $1"
}

require_arm64() {
  local path="$1"
  local label="$2"
  local archs
  archs="$(archs_for "$path")"
  if [[ " $archs " != *" arm64 "* ]]; then
    fail "$label does not contain arm64 architecture: $archs"
  fi
  echo "$label architectures: $archs"
}

human_size() {
  /usr/bin/du -sh "$1" | /usr/bin/awk '{print $1}'
}

scrub_blocking_xattrs() {
  local path="$1"
  local bad_xattrs
  /usr/bin/xattr -cr "$path" 2>/dev/null || true
  while IFS= read -r item; do
    /usr/bin/xattr -d com.apple.FinderInfo "$item" 2>/dev/null || true
    /usr/bin/xattr -d com.apple.ResourceFork "$item" 2>/dev/null || true
    /usr/bin/xattr -d com.apple.quarantine "$item" 2>/dev/null || true
  done < <(/usr/bin/find "$path" -print)

  bad_xattrs="$(/usr/bin/xattr -lr "$path" 2>/dev/null | /usr/bin/grep -E 'com\.apple\.(FinderInfo|ResourceFork|quarantine)' || true)"
  if [[ -n "$bad_xattrs" ]]; then
    echo "$bad_xattrs" >&2
    fail "Blocking xattrs remain under $path"
  fi
  echo "xattr cleanup: no FinderInfo, ResourceFork, or quarantine metadata found"
}

ensure_executable() {
  local path="$1"
  local label="$2"
  [[ -f "$path" ]] || fail "$label missing: $path"
  if [[ ! -x "$path" ]]; then
    echo "$label is not executable; applying chmod +x to staged app file"
    /bin/chmod +x "$path"
  fi
  [[ -x "$path" ]] || fail "$label is still not executable after chmod: $path"
}

verify_loader_paths() {
  local binary="$1"
  local label="$2"
  local linked
  linked="$(/usr/bin/otool -L "$binary")"
  if echo "$linked" | /usr/bin/grep -Eq '/opt/homebrew|/usr/local/opt|/usr/local/Cellar|/opt/local'; then
    echo "$linked" >&2
    fail "$label has Homebrew/MacPorts absolute runtime dependency"
  fi
  if echo "$linked" | /usr/bin/grep -E '\.dylib' | /usr/bin/grep -Ev '@loader_path|/usr/lib|/System/Library|^\S+:' >/dev/null; then
    echo "$linked" >&2
    fail "$label has non-system dylib linkage outside @loader_path"
  fi
  echo "$label dylib linkage: bundled dylibs use @loader_path and no Homebrew absolute dependency"
}

validate_zip_entry() {
  local listing="$1"
  local entry="$2"
  if ! echo "$listing" | /usr/bin/grep -Fxq "$entry"; then
    fail "Zip is missing expected entry: $entry"
  fi
}

validate_zip_contains_basename() {
  local listing="$1"
  local basename="$2"
  if ! echo "$listing" | /usr/bin/grep -Fxq "FishSockTransfer.app/Contents/Resources/$basename"; then
    fail "Zip is missing expected entry: FishSockTransfer.app/Contents/Resources/$basename"
  fi
}

echo "Packaging FishSock Transfer local ${PACKAGE_LABEL} build"
warn "Local owner-side ad-hoc build only."
warn "Not notarized."
warn "Not Developer ID signed."
warn "Apple Silicon arm64 package only."
warn "Minimum macOS: 13.5."
warn "Not for Intel Macs."
warn "Intel support requires x86_64/universal bundled rsync 3.4.4 and matching dylibs."

mkdir -p "$DIST_DIR"

# Remove only generated outputs owned by this packaging script.
rm -rf "$ZIP_PATH" "$LEGACY_DIST_APP" "$DIST_DIR/DerivedData-local-arm64" "$DIST_DIR/FishSockTransfer-local.entitlements"

echo "Building Release app for macOS arm64 (v${APP_VERSION} build ${BUILD_NUMBER})..."
COPYFILE_DISABLE=1 /usr/bin/xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  MARKETING_VERSION="$APP_VERSION" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
  build

BUILT_APP="$DERIVED_DATA/Build/Products/Release/$APP_NAME"
if [[ ! -d "$BUILT_APP" ]]; then
  BUILT_APP="$(/usr/bin/find "$DERIVED_DATA/Build/Products" -type d -name "$APP_NAME" -print -quit 2>/dev/null || true)"
fi
[[ -n "${BUILT_APP:-}" && -d "$BUILT_APP" ]] || fail "Built app could not be found under $DERIVED_DATA"

echo "Copying app to external staging path $STAGED_APP"
COPYFILE_DISABLE=1 /usr/bin/ditto --norsrc "$BUILT_APP" "$STAGED_APP"

[[ -d "$STAGED_APP" ]] || fail "Staged app missing: $STAGED_APP"
[[ -f "$INFO_PLIST" ]] || fail "Info.plist missing: $INFO_PLIST"

# --- Info.plist version validation ---
BUNDLE_SHORT_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST" 2>/dev/null || true)"
BUNDLE_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$INFO_PLIST" 2>/dev/null || true)"
MINIMUM_SYSTEM_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :LSMinimumSystemVersion' "$INFO_PLIST" 2>/dev/null || true)"

echo "--- Info.plist version check ---"
echo "App Version (CFBundleShortVersionString): ${BUNDLE_SHORT_VERSION:-<missing>}"
echo "Build Number (CFBundleVersion):           ${BUNDLE_VERSION:-<missing>}"
echo "LSMinimumSystemVersion:                   ${MINIMUM_SYSTEM_VERSION:-<missing>}"

[[ "$BUNDLE_SHORT_VERSION" == "$APP_VERSION" ]] || \
  fail "CFBundleShortVersionString mismatch: expected ${APP_VERSION}, got '${BUNDLE_SHORT_VERSION}'"
[[ -n "$BUNDLE_VERSION" ]] || fail "CFBundleVersion is missing from $INFO_PLIST"
[[ -n "$MINIMUM_SYSTEM_VERSION" ]] || fail "LSMinimumSystemVersion missing from $INFO_PLIST"
if [[ "$MINIMUM_SYSTEM_VERSION" != 13.5* ]]; then
  fail "LSMinimumSystemVersion is not 13.5-compatible: $MINIMUM_SYSTEM_VERSION"
fi
echo "--- Info.plist version check: PASSED ---"

ensure_executable "$APP_BINARY" "Main app executable"
ensure_executable "$RSYNC_BINARY" "Bundled rsync"
scrub_blocking_xattrs "$STAGED_APP"

RSYNC_VERSION_OUTPUT="$("$RSYNC_BINARY" --version 2>&1)" || fail "Bundled rsync --version failed"
if [[ "$RSYNC_VERSION_OUTPUT" != *"rsync  version 3.4.4"* && "$RSYNC_VERSION_OUTPUT" != *"rsync version 3.4.4"* ]]; then
  fail "Bundled rsync version is not 3.4.4"
fi
echo "Bundled rsync version: $(echo "$RSYNC_VERSION_OUTPUT" | /usr/bin/head -n 1)"

APP_ARCHS="$(archs_for "$APP_BINARY")"
echo "App binary architectures: $APP_ARCHS"
if [[ " $APP_ARCHS " != *" arm64 "* ]]; then
  fail "App binary does not contain arm64 architecture: $APP_ARCHS"
fi
if [[ " $APP_ARCHS " == *" x86_64 "* ]]; then
  warn "App binary also contains x86_64, but this package remains arm64-only because bundled rsync/dylibs are validated only for arm64."
fi

require_arm64 "$RSYNC_BINARY" "Bundled rsync"
verify_loader_paths "$APP_BINARY" "App binary"
verify_loader_paths "$RSYNC_BINARY" "Bundled rsync"

shopt -s nullglob
DYLIBS=("$STAGED_APP"/Contents/Resources/lib*.dylib)
if (( ${#DYLIBS[@]} == 0 )); then
  fail "No bundled dylibs found under $STAGED_APP/Contents/Resources"
fi
for dylib in "${DYLIBS[@]}"; do
  require_arm64 "$dylib" "Bundled dylib $(basename "$dylib")"
  verify_loader_paths "$dylib" "Bundled dylib $(basename "$dylib")"
done
shopt -u nullglob

cat > "$LOCAL_ENTITLEMENTS" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>com.apple.security.app-sandbox</key>
  <true/>
  <key>com.apple.security.files.user-selected.read-write</key>
  <true/>
</dict>
</plist>
PLIST

echo "Ad-hoc signing staged app..."
/usr/bin/codesign --force --deep --sign - --entitlements "$LOCAL_ENTITLEMENTS" --timestamp=none "$STAGED_APP"
rm -f "$LOCAL_ENTITLEMENTS"
scrub_blocking_xattrs "$STAGED_APP"
ensure_executable "$APP_BINARY" "Main app executable"
ensure_executable "$RSYNC_BINARY" "Bundled rsync"

if /usr/bin/codesign --verify --deep --strict --verbose=4 "$STAGED_APP"; then
  echo "Staged app codesign verification: passed"
else
  fail "Staged app codesign verification failed structurally"
fi

echo "Creating zip $ZIP_PATH from staged app"
(
  cd "$TEMP_ROOT"
  COPYFILE_DISABLE=1 /usr/bin/ditto -c -k --norsrc --keepParent "$APP_NAME" "$ZIP_PATH"
)
[[ -f "$ZIP_PATH" ]] || fail "Zip was not created: $ZIP_PATH"

ZIP_LISTING="$(/usr/bin/zipinfo -1 "$ZIP_PATH")"
if echo "$ZIP_LISTING" | /usr/bin/grep -Eq '(^|/)\._'; then
  fail "Zip contains AppleDouble ._ entries"
fi
validate_zip_entry "$ZIP_LISTING" "FishSockTransfer.app/Contents/MacOS/FishSockTransfer"
validate_zip_entry "$ZIP_LISTING" "FishSockTransfer.app/Contents/Resources/rsync"
for dylib in "${DYLIBS[@]}"; do
  validate_zip_contains_basename "$ZIP_LISTING" "$(basename "$dylib")"
done
echo "Zip AppleDouble check: passed"

echo "Staged app path: $STAGED_APP"
echo "Zip path: $ZIP_PATH"
echo "Zip size: $(human_size "$ZIP_PATH")"
echo "Main app executable permission:"
/bin/ls -l "$APP_BINARY"
echo "Bundled rsync executable permission:"
/bin/ls -l "$RSYNC_BINARY"
echo
echo "Local testing instructions:"
echo "1. Send the generated zip, not the raw .app."
echo "2. Avoid sending the raw .app through Telegram because it can attach quarantine metadata or alter bundle handling."
echo "3. On another Apple Silicon Mac, unzip $ZIP_NAME."
echo "4. Move $APP_NAME to Desktop or Applications."
echo "5. Try Right click > Open."
echo "6. If macOS blocks it because it is unsigned/unnotarized, that is expected for local ad-hoc builds."
echo "7. For owner-controlled testing only, remove quarantine:"
echo "   xattr -dr com.apple.quarantine /path/to/$APP_NAME"
echo "8. Confirm app binary and rsync are executable:"
echo "   ls -l /path/to/$APP_NAME/Contents/MacOS/FishSockTransfer"
echo "   ls -l /path/to/$APP_NAME/Contents/Resources/rsync"
echo "9. Confirm bundled rsync:"
echo "   /path/to/$APP_NAME/Contents/Resources/rsync --version"
echo "Package complete: $ZIP_PATH"
