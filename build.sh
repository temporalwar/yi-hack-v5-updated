#!/bin/bash
# ============================================================
#  yi-hack-v5 package updater — run on a Linux host with
#  the arm-hisiv300-linux toolchain already installed.
#
#  Usage:
#    chmod +x build.sh
#    ./build.sh
#
#  Or build individual packages:
#    ./build.sh openssl
#    ./build.sh curl
#    ./build.sh dropbear
#    ./build.sh mosquitto
#    ./build.sh pureftpd
#    ./build.sh libfuse
# ============================================================
set -euo pipefail

TOOLCHAIN_DIR="${TOOLCHAIN_DIR:-/opt/hisi-linux/x86-arm/arm-hisiv300-linux}"
TC_BIN="${TOOLCHAIN_DIR}/target/bin"

# ── Preflight checks ───────────────────────────────────────────────────────
echo "=== yi-hack-v5 cross-compile build ==="
echo ""

if [ ! -d "${TOOLCHAIN_DIR}" ]; then
    echo "ERROR: Toolchain not found at ${TOOLCHAIN_DIR}"
    echo ""
    echo "Install it first:"
    echo "  mkdir -p /opt/hisi-linux/x86-arm"
    echo "  cd /opt/hisi-linux/x86-arm"
    echo "  curl -fL https://github.com/OpenIPC/toolchains/releases/download/v1/arm-hisiv300-linux.tar.bz2 -o arm-hisiv300-linux.tar.bz2"
    echo "  tar -xjf arm-hisiv300-linux.tar.bz2"
    echo ""
    exit 1
fi

GCC="${TC_BIN}/arm-hisiv300-linux-uclibcgnueabi-gcc"
if [ ! -x "${GCC}" ]; then
    echo "ERROR: Compiler not found: ${GCC}"
    exit 1
fi

echo "  Toolchain:  ${TOOLCHAIN_DIR}"
echo "  Compiler:   $("${GCC}" --version | head -1)"
echo ""

# ── Host tool checks ───────────────────────────────────────────────────────
for tool in make cmake meson ninja wget; do
    if ! command -v "$tool" &>/dev/null; then
        echo "ERROR: '$tool' not found. Install it with:"
        echo "  sudo apt install build-essential cmake ninja-build meson wget"
        exit 1
    fi
done

# ── Run make ───────────────────────────────────────────────────────────────
export TOOLCHAIN_DIR

TARGET="${1:-all}"
echo "Building target: ${TARGET}"
echo ""

make "${TARGET}" TOOLCHAIN_DIR="${TOOLCHAIN_DIR}"
