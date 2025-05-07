#!/bin/bash
set -euo pipefail

BUILD_DIR="build"
INSTALL_LIB_DIR="lib"
BUILD_TYPE="Release"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_ABS_PATH="${SCRIPT_DIR}/${BUILD_DIR}"
INSTALL_LIB_ABS_PATH="${SCRIPT_DIR}/${INSTALL_LIB_DIR}"

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
