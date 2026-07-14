#!/usr/bin/env bash
#
# build.sh: build librcheevos.a for the host (macOS universal / Windows
# MinGW / generic Unix) or cross-compile it for ios|android (arm64). rcheevos
# compiles rc_libretro against the frontend's libretro.h, copied in via --lhp.
#
# Usage: ./build.sh [host|ios|android] [--lhp <dir-with-core/libretro.h>]
#   host output:    lib/librcheevos.a
#   ios/android:    lib/<platform>/librcheevos.a
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_TYPE=Release
IOS_DEPLOYMENT_TARGET=16.0
ANDROID_MIN_API=26

# --------------------------------- helpers ----------------------------------

die() { echo "error: $*" >&2; exit 1; }
log() { echo "==> $*"; }

require() {
  local cmd
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || die "required tool not found: $cmd"
  done
}

copy_libretro_header() {
  local src_dir="${LHP_DIR:-$SCRIPT_DIR/../../src}"
  [[ "$src_dir" = /* ]] || src_dir="$PWD/$src_dir"
  local header="$src_dir/core/libretro.h"
  [ -f "$header" ] || die "libretro.h not found: $header (pass --lhp <dir>)"
  cp "$header" "$SCRIPT_DIR/include/libretro.h"
  log "copied libretro.h from $header"
}

configure_platform() {
  CMAKE_FLAGS=(-DCMAKE_BUILD_TYPE="$BUILD_TYPE")
  case "$PLATFORM" in
    host)
      if [[ "$OSTYPE" == darwin* ]]; then
        CMAKE_FLAGS+=(
          "-DCMAKE_OSX_ARCHITECTURES=arm64;x86_64"
          -DCMAKE_OSX_DEPLOYMENT_TARGET="${MACOS_DEPLOYMENT_TARGET_FOR_RCHEEVOS:-12.0}"
        )
      elif [[ "$OSTYPE" == msys* || "$OSTYPE" == cygwin* ]]; then
        CMAKE_FLAGS+=(-G "MinGW Makefiles")
      fi ;;
    ios)
      require xcrun
      xcrun --sdk iphoneos --show-sdk-path >/dev/null 2>&1 || die "iPhoneOS SDK not found (install Xcode, run xcode-select)"
      CMAKE_FLAGS+=(
        -DCMAKE_SYSTEM_NAME=iOS
        -DCMAKE_OSX_ARCHITECTURES=arm64
        -DCMAKE_OSX_SYSROOT=iphoneos
        -DCMAKE_OSX_DEPLOYMENT_TARGET="$IOS_DEPLOYMENT_TARGET"
      ) ;;
    android)
      [ -n "${ANDROID_HOME:-}" ] || die "ANDROID_HOME is not set"
      NDK="$(find "$ANDROID_HOME/ndk" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -V | tail -1 || true)"
      [ -n "$NDK" ] || die "no NDK found under $ANDROID_HOME/ndk"
      CMAKE_FLAGS+=(
        -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake"
        -DANDROID_ABI=arm64-v8a
        -DANDROID_PLATFORM="android-$ANDROID_MIN_API"
      ) ;;
  esac
}

# ----------------------------------- main -----------------------------------

PLATFORM=host
LHP_DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    host|ios|android) PLATFORM="$1" ;;
    --lhp) LHP_DIR="${2:-}"; shift ;;
    *) die "unknown argument: $1 (usage: $0 [host|ios|android] [--lhp <dir>])" ;;
  esac
  shift
done

require cmake
configure_platform
copy_libretro_header

BUILD_DIR="$SCRIPT_DIR/build-$PLATFORM"
LIB_DIR="$SCRIPT_DIR/lib"
[ "$PLATFORM" = host ] || LIB_DIR="$LIB_DIR/$PLATFORM"

log "configure rcheevos ($PLATFORM, $BUILD_TYPE)"
cmake -S "$SCRIPT_DIR" -B "$BUILD_DIR" "${CMAKE_FLAGS[@]}"
log "build"
cmake --build "$BUILD_DIR" --parallel

[ -f "$BUILD_DIR/librcheevos.a" ] || die "expected archive not produced: $BUILD_DIR/librcheevos.a"
mkdir -p "$LIB_DIR"
cp "$BUILD_DIR/librcheevos.a" "$LIB_DIR/"
log "rcheevos ready: $LIB_DIR/librcheevos.a"
