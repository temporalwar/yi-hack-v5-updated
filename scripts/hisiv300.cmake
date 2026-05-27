# CMake cross-compilation toolchain for arm-hisiv300-linux-uclibcgnueabi
# Used by: mosquitto
#
# Usage:
#   cmake -DCMAKE_TOOLCHAIN_FILE=/build/scripts/hisiv300.cmake ...

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

# Toolchain prefix — set TOOLCHAIN_DIR env var to override
set(TOOLCHAIN_DIR "$ENV{TOOLCHAIN_DIR}")
if(NOT TOOLCHAIN_DIR)
    set(TOOLCHAIN_DIR "/opt/hisi-linux/x86-arm/arm-hisiv300-linux")
endif()

set(TC_BIN "${TOOLCHAIN_DIR}/target/bin")
set(CROSS_PREFIX "arm-hisiv300-linux")

set(CMAKE_C_COMPILER   "${TC_BIN}/${CROSS_PREFIX}-gcc")
set(CMAKE_CXX_COMPILER "${TC_BIN}/${CROSS_PREFIX}-g++")
set(CMAKE_AR           "${TC_BIN}/${CROSS_PREFIX}-ar"  CACHE FILEPATH "Archiver")
set(CMAKE_RANLIB       "${TC_BIN}/${CROSS_PREFIX}-ranlib" CACHE FILEPATH "Ranlib")
set(CMAKE_STRIP        "${TC_BIN}/${CROSS_PREFIX}-strip")
set(CMAKE_LINKER       "${TC_BIN}/${CROSS_PREFIX}-ld")

set(CMAKE_SYSROOT "${TOOLCHAIN_DIR}/target/arm-hisiv300-linux-uclibcgnueabi/sysroot")
set(CMAKE_FIND_ROOT_PATH "${CMAKE_SYSROOT}" "$ENV{STAGING_DIR}")

# Do NOT search host paths for libs/includes/programs
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Architecture flags: ARMv5te, soft-float, size-optimised
set(ARCH_FLAGS "-march=armv5te -mtune=arm926ej-s -msoft-float")
set(CMAKE_C_FLAGS_INIT   "${ARCH_FLAGS} -Os -ffunction-sections -fdata-sections")
set(CMAKE_CXX_FLAGS_INIT "${ARCH_FLAGS} -Os -ffunction-sections -fdata-sections")
set(CMAKE_EXE_LINKER_FLAGS_INIT "-Wl,--gc-sections")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "-Wl,--gc-sections")
