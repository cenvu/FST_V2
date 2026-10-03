#!/usr/bin/env bash
# Include distribution notices and corresponding-source material before signing.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
STAGED_APP="${1:?Usage: stage-third-party-notices.sh STAGED_APP arm64|x86_64}"
PACKAGE_ARCH="${2:?Package architecture required}"
RESOURCES="$STAGED_APP/Contents/Resources"
[[ -d "$RESOURCES" ]] || { echo 'Staged app Resources missing' >&2; exit 1; }
case "$PACKAGE_ARCH" in
  arm64)
    SOURCE_ARCHIVE="${RSYNC_ARM64_SOURCE_ARCHIVE:?Set RSYNC_ARM64_SOURCE_ARCHIVE to the reviewed complete corresponding-source archive}"
    SOURCE_NAME=rsync-arm64-corresponding-source.tar.gz
    ;;
  x86_64)
    SOURCE_ARCHIVE="$(dirname "${RSYNC_INTEL:?Set RSYNC_INTEL to the validated native binary}")/rsync-3.4.4.tar.gz"
    SOURCE_NAME=rsync-3.4.4.tar.gz
    [[ -f "$SOURCE_ARCHIVE" ]] || { echo 'Intel rsync source archive missing' >&2; exit 1; }
    [[ "$(shasum -a 256 "$SOURCE_ARCHIVE" | awk '{print $1}')" == bd88cf82fa653da32314fb229136407c5c90f80d1758d8f4b091767877d8fa96 ]] || { echo 'Intel rsync source checksum mismatch' >&2; exit 1; }
    ;;
  *) echo 'Unsupported package architecture' >&2; exit 1 ;;
esac
[[ -f "$SOURCE_ARCHIVE" ]] || { echo 'Corresponding-source archive missing' >&2; exit 1; }
tar -tzf "$SOURCE_ARCHIVE" >/dev/null
NOTICES="$RESOURCES/ThirdPartyNotices"
SOURCES="$RESOURCES/ThirdPartySources"
mkdir -p "$NOTICES/docs/legal" "$SOURCES"
cp "$REPO_ROOT/LICENSE" "$REPO_ROOT/NOTICE" "$NOTICES/"
cp "$REPO_ROOT/docs/legal/THIRD_PARTY_LICENSES.md" "$REPO_ROOT/docs/legal/TRADEMARKS.md" "$NOTICES/docs/legal/"
cp -R "$REPO_ROOT/docs/legal/LICENSES" "$NOTICES/docs/legal/"
cp "$SOURCE_ARCHIVE" "$SOURCES/$SOURCE_NAME"
if [[ "$PACKAGE_ARCH" == x86_64 ]]; then
  cp "$SCRIPT_DIR/build-rsync-intel.sh" "$SOURCES/"
fi
(
  cd "$SOURCES"
  shasum -a 256 "$SOURCE_NAME" > SHA256SUMS.txt
)
cat > "$SOURCES/README.txt" <<'TEXT'
rsync 3.4.4 is distributed under GPL version 3 or later.
Full license and component notices accompany this app in ThirdPartyNotices.
The source archive in this directory accompanies the bundled rsync executable.
For Intel, build-rsync-intel.sh records the native build recipe.
For ARM64, the supplied archive must include the reviewed source, changes,
dependency sources and build/install recipes corresponding to the executable.
Archive readability and checksums do not certify legal completeness.
The upstream rsync source is also available at:
https://download.samba.org/pub/rsync/src/rsync-3.4.4.tar.gz
TEXT
echo "Distribution notices and source material staged for $PACKAGE_ARCH"
