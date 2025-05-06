#!/bin/bash
set -euo pipefail

# --- Configuration ---
BUILD_DIR="build"
INSTALL_LIB_DIR="lib" # Relative to this script's location (rcheevos root)
BUILD_TYPE="Release"

# --- Get Script Directory ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_ABS_PATH="${SCRIPT_DIR}/${BUILD_DIR}"
INSTALL_LIB_ABS_PATH="${SCRIPT_DIR}/${INSTALL_LIB_DIR}"

# --- Check CMakeLists.txt ---
if [ ! -f "${SCRIPT_DIR}/CMakeLists.txt" ]; then
    echo "Error: CMakeLists.txt not found in script directory: ${SCRIPT_DIR}"
    exit 1
fi

# --- Build Steps ---
echo "Building rcheevos library in ${BUILD_ABS_PATH}..."
mkdir -p "${BUILD_ABS_PATH}"
cd "${BUILD_ABS_PATH}"

echo "Configuring CMake..."
cmake "${SCRIPT_DIR}" -DCMAKE_BUILD_TYPE="${BUILD_TYPE}"
if [ $? -ne 0 ]; then echo "CMake configuration failed"; exit 1; fi

echo "Compiling (using parallel jobs)..."
# Use cmake --build with --parallel (no specific core count needed)
cmake --build . --parallel
if [ $? -ne 0 ]; then echo "Build failed"; exit 1; fi

echo "Compilation successful."
cd "${SCRIPT_DIR}" # Go back to script dir

# --- Installation ---
echo "Creating installation directory: ${INSTALL_LIB_ABS_PATH}"
mkdir -p "${INSTALL_LIB_ABS_PATH}"

# Find the compiled library file (.a for MinGW/Unix, .lib for MSVC)
RCHEEVOS_LIB_FILE_A="${BUILD_ABS_PATH}/librcheevos.a"
RCHEEVOS_LIB_FILE_LIB="${BUILD_ABS_PATH}/rcheevos.lib"
RCHEEVOS_LIB_FILE_RELEASE_LIB="${BUILD_ABS_PATH}/${BUILD_TYPE}/rcheevos.lib" # Common for MSVC

RCHEEVOS_LIB_FILE_TO_COPY=""

if [ -f "${RCHEEVOS_LIB_FILE_A}" ]; then
    RCHEEVOS_LIB_FILE_TO_COPY="${RCHEEVOS_LIB_FILE_A}"
elif [ -f "${RCHEEVOS_LIB_FILE_LIB}" ]; then
     RCHEEVOS_LIB_FILE_TO_COPY="${RCHEEVOS_LIB_FILE_LIB}"
elif [ -f "${RCHEEVOS_LIB_FILE_RELEASE_LIB}" ]; then
     RCHEEVOS_LIB_FILE_TO_COPY="${RCHEEVOS_LIB_FILE_RELEASE_LIB}"
fi

if [ -z "${RCHEEVOS_LIB_FILE_TO_COPY}" ]; then
    echo "Error: Compiled library file (librcheevos.a or rcheevos.lib) not found in expected locations within ${BUILD_ABS_PATH}"
    exit 1
fi

echo "Found library: ${RCHEEVOS_LIB_FILE_TO_COPY}"
echo "Copying to ${INSTALL_LIB_ABS_PATH}/"
cp "${RCHEEVOS_LIB_FILE_TO_COPY}" "${INSTALL_LIB_ABS_PATH}/"
if [ $? -ne 0 ]; then echo "Copy failed"; exit 1; fi

echo "----------------------------------------"
echo "rcheevos build completed successfully!"
echo "Library placed in: ${INSTALL_LIB_ABS_PATH}/$(basename ${RCHEEVOS_LIB_FILE_TO_COPY})"
echo "----------------------------------------"
exit 0
