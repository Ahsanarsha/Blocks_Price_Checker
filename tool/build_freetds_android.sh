#!/usr/bin/env bash
# Builds the FreeTDS DB-Library (libsybdb.so) and CT-Library (libct.so) for
# Android with 16 KB page-size alignment and copies them into
# android/app/src/main/jniLibs/<abi>/.
#
# The mssql_connection package ships prebuilt copies of these libraries, but
# they are only 4 KB aligned, which Google Play rejects for apps targeting
# Android 15+ (hard block from 1 February 2027). This script mirrors the
# package's own build (scripts/build-android.sh in the package: FreeTDS 1.5.4,
# API 21, MS-style dblib, no OpenSSL, internal iconv) and adds the 16 KB
# linker flags. NDK r28+ already defaults to 16 KB, the flags make it explicit.
#
# Usage:
#   tool/build_freetds_android.sh [abi ...]
#
# Environment (defaults shown):
#   ANDROID_SDK_ROOT  ~/Library/Android/sdk
#   ANDROID_NDK       $ANDROID_SDK_ROOT/ndk/28.2.13676358
#   CMAKE_BIN         $ANDROID_SDK_ROOT/cmake/3.22.1/bin
#   FREETDS_VERSION   1.5.4
#   WORK_DIR          /tmp/freetds-android-build
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}"
ANDROID_NDK="${ANDROID_NDK:-$ANDROID_SDK_ROOT/ndk/28.2.13676358}"
CMAKE_BIN="${CMAKE_BIN:-$ANDROID_SDK_ROOT/cmake/3.22.1/bin}"
FREETDS_VERSION="${FREETDS_VERSION:-1.5.4}"
WORK_DIR="${WORK_DIR:-/tmp/freetds-android-build}"
ABIS=("$@")
if [ ${#ABIS[@]} -eq 0 ]; then
  ABIS=(arm64-v8a armeabi-v7a x86_64)
fi

CMAKE="$CMAKE_BIN/cmake"
NINJA="$CMAKE_BIN/ninja"
STRIP="$(ls "$ANDROID_NDK"/toolchains/llvm/prebuilt/*/bin/llvm-strip | head -1)"
READELF="$(ls "$ANDROID_NDK"/toolchains/llvm/prebuilt/*/bin/llvm-readelf | head -1)"
OUT_ROOT="$PROJECT_ROOT/android/app/src/main/jniLibs"

for tool in "$CMAKE" "$NINJA" "$STRIP" "$READELF"; do
  [ -x "$tool" ] || { echo "missing tool: $tool" >&2; exit 1; }
done

mkdir -p "$WORK_DIR"
SRC_DIR="$WORK_DIR/freetds-$FREETDS_VERSION"
if [ ! -d "$SRC_DIR" ]; then
  TARBALL="$WORK_DIR/freetds-$FREETDS_VERSION.tar.gz"
  echo ">> downloading FreeTDS $FREETDS_VERSION"
  curl -fsSL -o "$TARBALL" "https://www.freetds.org/files/stable/freetds-$FREETDS_VERSION.tar.gz"
  tar xzf "$TARBALL" -C "$WORK_DIR"
fi

# FreeTDS's CMakeLists links gssapi_krb5 unconditionally on non-Windows hosts
# even with ENABLE_KRB5=OFF ("TODO check libraries"). Android has no Kerberos
# library, so drop it. The sed is idempotent.
sed -i.bak -e 's/^\([[:space:]]*\)set(lib_NETWORK gssapi_krb5)$/\1set(lib_NETWORK)/' "$SRC_DIR/CMakeLists.txt"

for ABI in "${ABIS[@]}"; do
  BUILD_DIR="$WORK_DIR/build-$ABI"
  rm -rf "$BUILD_DIR" && mkdir -p "$BUILD_DIR"
  echo ">> configuring $ABI"
  "$CMAKE" -S "$SRC_DIR" -B "$BUILD_DIR" -G Ninja \
    -DCMAKE_MAKE_PROGRAM="$NINJA" \
    -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK/build/cmake/android.toolchain.cmake" \
    -DANDROID_NDK="$ANDROID_NDK" \
    -DANDROID_ABI="$ABI" \
    -DANDROID_PLATFORM=21 \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_MSDBLIB=ON \
    -DWITH_OPENSSL=OFF \
    -DCMAKE_SHARED_LINKER_FLAGS="-Wl,-z,max-page-size=16384 -Wl,-z,common-page-size=16384" \
    > "$BUILD_DIR/configure.log" 2>&1

  # Android has no system iconv; make FreeTDS use its internal replacement,
  # exactly as the package's own build does.
  CONFIG_H="$BUILD_DIR/include/config.h"
  if [ -f "$CONFIG_H" ]; then
    sed -i.bak -e 's/^#define HAVE_ICONV 1$/#undef HAVE_ICONV/' "$CONFIG_H"
  fi

  echo ">> building $ABI"
  "$CMAKE" --build "$BUILD_DIR" --target sybdb ct > "$BUILD_DIR/build.log" 2>&1

  mkdir -p "$OUT_ROOT/$ABI"
  for LIB in libsybdb.so libct.so; do
    SRC_LIB="$(find "$BUILD_DIR" -name "$LIB" -maxdepth 4 | head -1)"
    [ -n "$SRC_LIB" ] || { echo "$LIB not produced for $ABI" >&2; exit 1; }
    "$STRIP" --strip-unneeded -o "$OUT_ROOT/$ABI/$LIB" "$SRC_LIB"
    ALIGN="$("$READELF" -l "$OUT_ROOT/$ABI/$LIB" | awk '/LOAD/ {print $NF}' | sort -u | tr '\n' ' ')"
    echo "   $ABI/$LIB  LOAD align: $ALIGN"
  done
done

echo ">> done. Libraries are in $OUT_ROOT/<abi>/"
