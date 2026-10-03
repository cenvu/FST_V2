#!/usr/bin/env bash
# FST v1.4.0 Intel package; canonical ARM resources are never modified here.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${FST_SOURCE_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
DIST_DIR="${FST_DIST_DIR:-$REPO_ROOT/dist}"
RSYNC_INTEL="${RSYNC_INTEL:?Set RSYNC_INTEL to the validated native rsync 3.4.4 binary}"
PACKAGE_LABEL=macOS13_5plus-x86_64
APP_VERSION=1.4.0
BUILD_NUMBER=20261003
[[ "$(uname -m)" == x86_64 ]] || { echo 'Native Intel runner required' >&2; exit 1; }
[[ "$(lipo -archs "$RSYNC_INTEL")" == x86_64 ]]
mkdir -p "$DIST_DIR"
DIST_DIR="$(cd "$DIST_DIR" && pwd)"
ZIP_PATH="$DIST_DIR/FishSockTransfer-v${APP_VERSION}-b${BUILD_NUMBER}-local-${PACKAGE_LABEL}.zip"
[[ ! -e "$ZIP_PATH" ]] || { echo 'Package already exists; refusing overwrite' >&2; exit 1; }
TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/fst-local-intel.XXXXXX")"
trap 'rm -rf "$TEMP_ROOT"' EXIT
STAGED_APP="$TEMP_ROOT/FishSockTransfer.app"
COPYFILE_DISABLE=1 xcodebuild \
  -project "$REPO_ROOT/FishSockTransfer/FishSockTransfer.xcodeproj" \
  -scheme FishSockTransfer -configuration Release \
  -destination 'platform=macOS,arch=x86_64' \
  -derivedDataPath "$TEMP_ROOT/DerivedData" \
  CODE_SIGNING_ALLOWED=NO ARCHS=x86_64 ONLY_ACTIVE_ARCH=YES \
  MACOSX_DEPLOYMENT_TARGET=13.5 MARKETING_VERSION="$APP_VERSION" \
  CURRENT_PROJECT_VERSION="$BUILD_NUMBER" build
COPYFILE_DISABLE=1 ditto --norsrc "$TEMP_ROOT/DerivedData/Build/Products/Release/FishSockTransfer.app" "$STAGED_APP"
# Xcode copies the canonical ARM resources. Replace only staged rsync runtime.
rm -f "$STAGED_APP/Contents/Resources/rsync"
find "$STAGED_APP/Contents/Resources" -maxdepth 1 -name 'lib*.dylib' -type f -delete
cp "$RSYNC_INTEL" "$STAGED_APP/Contents/Resources/rsync"
chmod 755 "$STAGED_APP/Contents/Resources/rsync"
cp "$(dirname "$RSYNC_INTEL")/rsync-3.4.4/COPYING" "$STAGED_APP/Contents/Resources/rsync-COPYING.txt"
"$SCRIPT_DIR/stage-third-party-notices.sh" "$STAGED_APP" x86_64
xattr -cr "$STAGED_APP"
python3 "$SCRIPT_DIR/audit-intel-package.py" "$STAGED_APP" --unsigned
codesign --force --deep --sign - \
  --entitlements "$REPO_ROOT/FishSockTransfer/FishSockTransfer/FishSockTransfer.entitlements" \
  --timestamp=none "$STAGED_APP"
python3 "$SCRIPT_DIR/audit-intel-package.py" "$STAGED_APP"
COPYFILE_DISABLE=1 ditto -c -k --norsrc --keepParent "$STAGED_APP" "$ZIP_PATH"
python3 "$SCRIPT_DIR/audit-intel-package.py" "$ZIP_PATH"
(
  cd "$DIST_DIR"
  shasum -a 256 "$(basename "$ZIP_PATH")" > SHA256SUMS-v1.4.0-x86_64.txt
)
echo "PACKAGE=$ZIP_PATH"
cat "$DIST_DIR/SHA256SUMS-v1.4.0-x86_64.txt"
