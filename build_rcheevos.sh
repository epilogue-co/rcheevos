#!/bin/bash
set -euo pipefail

BUILD_DIR="build"
INSTALL_LIB_DIR="lib"
INCLUDE_DIR="include"
BUILD_TYPE="Release"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_ABS_PATH="${SCRIPT_DIR}/${BUILD_DIR}"
INSTALL_LIB_ABS_PATH="${SCRIPT_DIR}/${INSTALL_LIB_DIR}"
TARGET_INCLUDE_ABS_PATH="${SCRIPT_DIR}/${INCLUDE_DIR}"
LIBRETRO_H_SOURCE_DIR_INPUT=""


while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --lhp)
        LIBRETRO_H_SOURCE_DIR_INPUT="$2"
        shift
        shift
        ;;
        *)
        shift
        ;;
    esac
done

LIBRETRO_H_FILENAME="libretro.h"
LIBRETRO_H_SOURCE_FILE_PATH=""

if [ -n "${LIBRETRO_H_SOURCE_DIR_INPUT}" ]; then
    if [[ "${LIBRETRO_H_SOURCE_DIR_INPUT}" = /* ]]; then
        LIBRETRO_H_SOURCE_DIR_RESOLVED="${LIBRETRO_H_SOURCE_DIR_INPUT}"
    else
        LIBRETRO_H_SOURCE_DIR_RESOLVED="$(cd "$(pwd)/${LIBRETRO_H_SOURCE_DIR_INPUT}" && pwd)"
    fi
    LIBRETRO_H_SOURCE_FILE_PATH="${LIBRETRO_H_SOURCE_DIR_RESOLVED}/core/${LIBRETRO_H_FILENAME}"
else
    DEFAULT_LIBRETRO_H_SOURCE_DIR_RESOLVED="$(cd "${SCRIPT_DIR}/../../src" && pwd)"
    LIBRETRO_H_SOURCE_FILE_PATH="${DEFAULT_LIBRETRO_H_SOURCE_DIR_RESOLVED}/core/${LIBRETRO_H_FILENAME}"
fi

echo "Preparing to copy ${LIBRETRO_H_FILENAME}..."
echo "Source path: ${LIBRETRO_H_SOURCE_FILE_PATH}"
echo "Target directory: ${TARGET_INCLUDE_ABS_PATH}"

if [ ! -f "${LIBRETRO_H_SOURCE_FILE_PATH}" ]; then
    echo "Error: ${LIBRETRO_H_FILENAME} not found at ${LIBRETRO_H_SOURCE_FILE_PATH}"
    exit 1
fi

cp "${LIBRETRO_H_SOURCE_FILE_PATH}" "${TARGET_INCLUDE_ABS_PATH}/${LIBRETRO_H_FILENAME}"
if [ $? -ne 0 ]; then echo "Error: Failed to copy ${LIBRETRO_H_FILENAME} to ${TARGET_INCLUDE_ABS_PATH}"; exit 1; fi
echo "${LIBRETRO_H_FILENAME} copied successfully to ${TARGET_INCLUDE_ABS_PATH}"

echo "Building rcheevos library..."
mkdir -p "${BUILD_ABS_PATH}"
cd "${BUILD_ABS_PATH}"

CMAKE_ARGS=("-DCMAKE_BUILD_TYPE=${BUILD_TYPE}")

if [[ "$OSTYPE" == "darwin"* ]]; then
    MACOS_TARGET_VERSION="${MACOS_DEPLOYMENT_TARGET_FOR_RCHEEVOS:-12.0}"
    CMAKE_ARGS+=("-DCMAKE_OSX_ARCHITECTURES=arm64;x86_64")
    CMAKE_ARGS+=("-DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOS_TARGET_VERSION}")
    echo "Configuring for macOS Universal (Target: ${MACOS_TARGET_VERSION})"
elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then
    echo "Configuring for Windows (MinGW Makefiles)"
    CMAKE_ARGS+=("-G" "MinGW Makefiles")
else
    echo "Configuring for generic Unix"
fi

cmake "${SCRIPT_DIR}" "${CMAKE_ARGS[@]}"
if [ $? -ne 0 ]; then echo "Error: CMake configuration failed"; exit 1; fi

echo "Compiling rcheevos (${BUILD_TYPE})..."
if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then
    cmake --build . --parallel
else
    cmake --build . --config "${BUILD_TYPE}" --parallel
fi
if [ $? -ne 0 ]; then echo "Error: Build failed"; exit 1; fi

cd "${SCRIPT_DIR}"
mkdir -p "${INSTALL_LIB_ABS_PATH}"

RCHEEVOS_LIB_FILE_TO_COPY=""
POSSIBLE_LIBS=(
    "${BUILD_ABS_PATH}/${BUILD_TYPE}/librcheevos.a"
    "${BUILD_ABS_PATH}/${BUILD_TYPE}/rcheevos.lib"
    "${BUILD_ABS_PATH}/librcheevos.a"
    "${BUILD_ABS_PATH}/rcheevos.lib"
)

for lib_path in "${POSSIBLE_LIBS[@]}"; do
    if [ -f "${lib_path}" ]; then
        RCHEEVOS_LIB_FILE_TO_COPY="${lib_path}"
        break
    fi
done

if [ -z "${RCHEEVOS_LIB_FILE_TO_COPY}" ]; then
    echo "Error: Compiled library not found in build directory or build/${BUILD_TYPE}/ subdir."
    exit 1
fi

cp "${RCHEEVOS_LIB_FILE_TO_COPY}" "${INSTALL_LIB_ABS_PATH}/$(basename "${RCHEEVOS_LIB_FILE_TO_COPY}")"
if [ $? -ne 0 ]; then echo "Error: Copy failed"; exit 1; fi

echo "rcheevos build completed: ${INSTALL_LIB_ABS_PATH}/$(basename "${RCHEEVOS_LIB_FILE_TO_COPY}")"
exit 0
