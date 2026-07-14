cmake_minimum_required(VERSION 3.10)
project(rcheevos-standalone LANGUAGES C)

add_library(rcheevos STATIC

    # Public Headers
    include/rcheevos.h
    include/rc_api_editor.h
    include/rc_api_info.h
    include/rc_api_request.h
    include/rc_api_runtime.h
    include/rc_api_user.h
    include/rc_client.h
    include/rc_consoles.h
    include/rc_error.h
    include/rc_hash.h
    include/rc_libretro.h
    include/rc_runtime.h
    include/rc_runtime_types.h
    include/rc_util.h

    # Core client and utilities (src/)
    src/rc_client_internal.h
    src/rc_compat.h
    src/rc_version.h
    src/rc_client.c
    src/rc_compat.c
    src/rc_libretro.c
    src/rc_util.c

    # API implementation (src/rapi/)
    src/rapi/rc_api_common.h
    src/rapi/rc_api_common.c
    src/rapi/rc_api_editor.c
    src/rapi/rc_api_info.c
    src/rapi/rc_api_runtime.c
    src/rapi/rc_api_user.c

    # Cheevos logic (src/rcheevos/)
    src/rcheevos/rc_internal.h
    src/rcheevos/alloc.c
    src/rcheevos/condition.c
    src/rcheevos/condset.c
    src/rcheevos/consoleinfo.c
    src/rcheevos/format.c
    src/rcheevos/lboard.c
    src/rcheevos/memref.c
    src/rcheevos/operand.c
    src/rcheevos/richpresence.c
    src/rcheevos/runtime.c
    src/rcheevos/runtime_progress.c
    src/rcheevos/trigger.c
    src/rcheevos/value.c

    # Hashing utilities (src/rhash/)
    src/rhash/aes.h
    src/rhash/md5.h
    src/rhash/aes.c
    src/rhash/hash.c
    src/rhash/hash_disc.c
    src/rhash/hash_encrypted.c
    src/rhash/hash_rom.c
    src/rhash/hash_zip.c
    src/rhash/cdreader.c
    src/rhash/md5.c
)

target_include_directories(rcheevos
    INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/include"
    PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/include"
)

target_compile_definitions(rcheevos PRIVATE
    "RCHEEVOS_URL_SSL=1"
    "RC_NO_THREADS=1"
    "RC_DISABLE_LUA=1"
)
