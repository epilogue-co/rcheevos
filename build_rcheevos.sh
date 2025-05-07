#!/bin/bash
set -euo pipefail

BUILD_DIR="build"
INSTALL_LIB_DIR="lib"
BUILD_TYPE="Release"
DEFAULT_MACOS_DEPLOYMENT_TARGET="12.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_ABS_PATH="${SCRIPT_DIR}/${BUILD_DIR}"
INSTALL_LIB_ABS_PATH="${SCRIPT_DIR}/${INSTALL_LIB_DIR}"

echo "Building rcheevos library..."
mkdir -p "${BUILD_ABS_PATH}"
cd "${BUILD_ABS_PATH}"

echo "Configuring CMake..."
CMAKE_ARGS=("-DCMAKE_BUILD_TYPE=${BUILD_TYPE}")

if [[ "$OSTYPE" == "darwin"* ]]; then
    MACOS_TARGET_VERSION="${MACOS_DEPLOYMENT_TARGET_FOR_RCHEEVOS:-${DEFAULT_MACOS_DEPLOYMENT_TARGET}}"
    echo "macOS detected. Configuring for universal (arm64;x86_64) build."
    echo "Using macOS Deployment Target: ${MACOS_TARGET_VERSION}"
    CMAKE_ARGS+=("-DCMAKE_OSX_ARCHITECTURES=arm64;x86_64")
    CMAKE_ARGS+=("-DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOS_TARGET_VERSION}")
fi

cmake "${SCRIPT_DIR}" "${CMAKE_ARGS[@]}"
if [ $? -ne 0 ]; then echo "CMake configuration failed"; exit 1; fi

echo "Compiling..."
cmake --build . --config "${BUILD_TYPE}" --parallel
if [ $? -ne 0 ]; then echo "Build failed"; exit 1; fi

cd "${SCRIPT_DIR}"
mkdir -p "${INSTALL_LIB_ABS_PATH}"

RCHEEVOS_LIB_CONFIG_SUBDIR="${BUILD_ABS_PATH}/${BUILD_TYPE}"
RCHEEVOS_LIB_FILE_A_CONFIG="${RCHEEVOS_LIB_CONFIG_SUBDIR}/librcheevos.a"
RCHEEVOS_LIB_FILE_LIB_CONFIG="${RCHEEVOS_LIB_CONFIG_SUBDIR}/rcheevos.lib"
RCHEEVOS_LIB_FILE_A_ROOT="${BUILD_ABS_PATH}/librcheevos.a"
RCHEEVOS_LIB_FILE_LIB_ROOT="${BUILD_ABS_PATH}/rcheevos.lib"
RCHEEVOS_LIB_FILE_TO_COPY=""

if [ -f "${RCHEEVOS_LIB_FILE_A_CONFIG}" ]; then
    RCHEEVOS_LIB_FILE_TO_COPY="${RCHEEVOS_LIB_FILE_A_CONFIG}"
elif [ -f "${RCHEEVOS_LIB_FILE_LIB_CONFIG}" ]; then
     RCHEEVOS_LIB_FILE_TO_COPY="${RCHEEVOS_LIB_FILE_LIB_CONFIG}"
elif [ -f "${RCHEEVOS_LIB_FILE_A_ROOT}" ]; then
    RCHEEVOS_LIB_FILE_TO_COPY="${RCHEEVOS_LIB_FILE_A_ROOT}"
elif [ -f "${RCHEEVOS_LIB_FILE_LIB_ROOT}" ]; then
     RCHEEVOS_LIB_FILE_TO_COPY="${RCHEEVOS_LIB_FILE_LIB_ROOT}"
fi

if [ -z "${RCHEEVOS_LIB_FILE_TO_COPY}" ]; then
    echo "Error: Compiled library not found in ${RCHEEVOS_LIB_CONFIG_SUBDIR}/ or ${BUILD_ABS_PATH}/"
    exit 1
fi

echo "Copying $(basename ${RCHEEVOS_LIB_FILE_TO_COPY}) to ${INSTALL_LIB_ABS_PATH}/"
cp "${RCHEEVOS_LIB_FILE_TO_COPY}" "${INSTALL_LIB_ABS_PATH}/$(basename ${RCHEEVOS_LIB_FILE_TO_COPY})"
if [ $? -ne 0 ]; then echo "Copy failed"; exit 1; fi

echo "rcheevos build completed: ${INSTALL_LIB_ABS_PATH}/$(basename ${RCHEEVOS_LIB_FILE_TO_COPY})"
exit 0
