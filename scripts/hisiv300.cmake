# CMake cross-compilation toolchain for arm-hisiv300-linux-uclibcgnueabi
# Confirmed bin path: /opt/hisi-linux/x86-arm/arm-hisiv300-linux/bin/
# Sysroot: target/ (crt1.o/crti.o live here)
# Arch libs: target/armv5te_arm9_soft/lib (added via linker flags)
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

set(TOOLCHAIN_DIR "$ENV{TOOLCHAIN_DIR}")
if(NOT TOOLCHAIN_DIR)
    set(TOOLCHAIN_DIR "/opt/hisi-linux/x86-arm/arm-hisiv300-linux")
endif()

set(TC_BIN        "${TOOLCHAIN_DIR}/bin")
set(CROSS_PREFIX  "arm-hisiv300-linux-uclibcgnueabi")

set(CMAKE_C_COMPILER   "${TC_BIN}/${CROSS_PREFIX}-gcc")
set(CMAKE_CXX_COMPILER "${TC_BIN}/${CROSS_PREFIX}-g++")
set(CMAKE_AR           "${TC_BIN}/${CROSS_PREFIX}-ar"     CACHE FILEPATH "Archiver")
set(CMAKE_RANLIB       "${TC_BIN}/${CROSS_PREFIX}-ranlib"  CACHE FILEPATH "Ranlib")
set(CMAKE_STRIP        "${TC_BIN}/${CROSS_PREFIX}-strip")
set(CMAKE_LINKER       "${TC_BIN}/${CROSS_PREFIX}-ld")

# Use target/ as sysroot — this is where crt1.o and crti.o are found
# armv5te_arm9_soft/lib is added to linker flags for arch-specific shared libs
set(CMAKE_SYSROOT "${TOOLCHAIN_DIR}/target")

set(CMAKE_FIND_ROOT_PATH "${CMAKE_SYSROOT}" "$ENV{STAGING_DIR}")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# ARM926EJ-S: no FPU, soft-float mandatory
set(ARCH_FLAGS "-mcpu=arm926ej-s -march=armv5te -mfloat-abi=soft -msoft-float -fno-short-enums")

set(CMAKE_C_FLAGS_INIT   "${ARCH_FLAGS} -Os -ffunction-sections -fdata-sections")
set(CMAKE_CXX_FLAGS_INIT "${ARCH_FLAGS} -Os -ffunction-sections -fdata-sections")

set(CMAKE_EXE_LINKER_FLAGS_INIT    "-Wl,--gc-sections -L${TOOLCHAIN_DIR}/target/armv5te_arm9_soft/lib")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "-Wl,--gc-sections -L${TOOLCHAIN_DIR}/target/armv5te_arm9_soft/lib")
