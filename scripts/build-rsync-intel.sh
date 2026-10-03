#!/usr/bin/env bash
# Build the exact production rsync without third-party runtime libraries.
set -euo pipefail
[[ "$(uname -m)" == x86_64 ]] || { echo 'Native Intel runner required' >&2; exit 1; }
OUTPUT="${1:?Usage: build-rsync-intel.sh OUTPUT_DIRECTORY}"
mkdir -p "$OUTPUT"
OUTPUT="$(cd "$OUTPUT" && pwd)"
SOURCE_SHA=bd88cf82fa653da32314fb229136407c5c90f80d1758d8f4b091767877d8fa96
curl --fail --location --retry 3 https://download.samba.org/pub/rsync/src/rsync-3.4.4.tar.gz -o "$OUTPUT/rsync-3.4.4.tar.gz"
[[ "$(shasum -a 256 "$OUTPUT/rsync-3.4.4.tar.gz" | awk '{print $1}')" == "$SOURCE_SHA" ]] || { echo 'rsync source checksum mismatch' >&2; exit 1; }
tar -xzf "$OUTPUT/rsync-3.4.4.tar.gz" -C "$OUTPUT"
cd "$OUTPUT/rsync-3.4.4"
./configure --help > "$OUTPUT/configure-help.txt"
FLAGS=(--disable-debug --disable-md2man --disable-openssl --disable-xxhash --disable-zstd --disable-lz4 --with-included-popt --with-included-zlib)
for flag in "${FLAGS[@]}"; do
  grep -Fq -- "$flag" "$OUTPUT/configure-help.txt" || { echo "Unsupported configure flag: $flag" >&2; exit 1; }
done
# Keep build paths and Homebrew discovery out of the runtime binary.
unset CPPFLAGS LDFLAGS LIBS CPATH LIBRARY_PATH PKG_CONFIG_PATH
export MACOSX_DEPLOYMENT_TARGET=13.5
export CC="$(xcrun --find clang)" CXX="$(xcrun --find clang++)"
export CFLAGS="-O2 -arch x86_64 -mmacosx-version-min=13.5 -ffile-prefix-map=$OUTPUT=/rsync-source"
export CXXFLAGS="$CFLAGS"
export LDFLAGS='-arch x86_64 -mmacosx-version-min=13.5'
./configure "${FLAGS[@]}"
make -j "$(sysctl -n hw.ncpu)" rsync
cp rsync "$OUTPUT/rsync"
chmod 755 "$OUTPUT/rsync"
file "$OUTPUT/rsync"
[[ "$(lipo -archs "$OUTPUT/rsync")" == x86_64 ]]
"$OUTPUT/rsync" --version | tee "$OUTPUT/rsync-version.txt"
grep -Eq '^rsync +version 3\.4\.4 +protocol version 32$' "$OUTPUT/rsync-version.txt"
otool -L "$OUTPUT/rsync" | tee "$OUTPUT/rsync-loader.txt"
# This build deliberately has no external dylibs to bundle.
awk 'NR > 1 {print $1}' "$OUTPUT/rsync-loader.txt" | while IFS= read -r dependency; do
  case "$dependency" in /usr/lib/*|/System/Library/*) ;; *) echo "Unsafe rsync dependency: $dependency" >&2; exit 1;; esac
done
echo "RSYNC_SOURCE_SHA256=$SOURCE_SHA"
