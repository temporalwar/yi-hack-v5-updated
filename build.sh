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
TC_BIN="${TOOLCHAIN_DIR}/bin"

# ── Preflight checks ───────────────────────────────────────────────────────
echo "=== yi-hack-v5 cross-compile build ==="
echo ""

if [ ! -d "${TOOLCHAIN_DIR}" ]; then
    echo "ERROR: Toolchain not found at ${TOOLCHAIN_DIR}"
    echo ""
    echo "Install it first:"
    echo "  mkdir -p /opt/hisi-linux/x86-arm"
    echo "  cd /opt/his
