# ============================================================
#  yi-hack-v5 package update build system
#  Target: arm-hisiv300-linux-uclibcgnueabi (Hi3518ev200)
#  Host:   x86_64 Linux
# ============================================================

# ── Toolchain ─────────────────────────────────────────────────────────────
TOOLCHAIN_DIR ?= /opt/hisi-linux/x86-arm/arm-hisiv300-linux
TC_BIN        := $(TOOLCHAIN_DIR)/bin/
CROSS         := $(TC_BIN)/arm-hisiv300-linux-uclibcgnueabi-
export PATH   := $(TC_BIN):$(PATH)

CC      := $(CROSS)gcc
CXX     := $(CROSS)g++
AR      := $(CROSS)ar
RANLIB  := $(CROSS)ranlib
STRIP   := $(CROSS)strip
LD      := $(CROSS)ld

HOST_TRIPLE := arm-hisiv300-linux-uclibcgnueabi
SYSROOT     := $(TOOLCHAIN_DIR)/target/$(HOST_TRIPLE)/sysroot

# ── Output layout ─────────────────────────────────────────────────────────
BUILD_DIR   := $(CURDIR)/build
STAGING_DIR := $(CURDIR)/staging
OUT_DIR     := $(CURDIR)/output

STAGING_LIB := $(STAGING_DIR)/lib
STAGING_BIN := $(STAGING_DIR)/bin
STAGING_INC := $(STAGING_DIR)/include

# Flags passed to every configure/cmake
COMMON_CFLAGS   := -Os -march=armv5te -mtune=arm926ej-s -msoft-float -ffunction-sections -fdata-sections
COMMON_LDFLAGS  := -Wl,--gc-sections -L$(STAGING_LIB)
PKG_CONFIG_PATH := $(STAGING_LIB)/pkgconfig

# ── Package versions ───────────────────────────────────────────────────────
OPENSSL_VER    := 3.3.2
CURL_VER       := 8.20.0
DROPBEAR_VER   := 2025.89
CJSON_VER      := 1.7.18
MOSQUITTO_VER  := 2.1.0
PUREFTPD_VER   := 1.0.52
LIBFUSE_VER    := 3.18.1

# ── Download URLs ──────────────────────────────────────────────────────────
OPENSSL_URL    := https://github.com/openssl/openssl/releases/download/openssl-$(OPENSSL_VER)/openssl-$(OPENSSL_VER).tar.gz
CURL_URL       := https://github.com/curl/curl/releases/download/curl-$(subst .,_,$(CURL_VER))/curl-$(CURL_VER).tar.gz
DROPBEAR_URL   := https://matt.ucc.asn.au/dropbear/releases/dropbear-$(DROPBEAR_VER).tar.bz2
CJSON_URL      := https://github.com/DaveGamble/cJSON/archive/refs/tags/v$(CJSON_VER).tar.gz
MOSQUITTO_URL  := https://github.com/eclipse-mosquitto/mosquitto/archive/refs/tags/v$(MOSQUITTO_VER).tar.gz
PUREFTPD_URL   := https://download.pureftpd.org/pub/pure-ftpd/releases/pure-ftpd-$(PUREFTPD_VER).tar.gz
LIBFUSE_URL    := https://github.com/libfuse/libfuse/releases/download/fuse-$(LIBFUSE_VER)/fuse-$(LIBFUSE_VER).tar.gz

DOWNLOAD_DIR := $(CURDIR)/downloads

# ── Phony targets ──────────────────────────────────────────────────────────
.PHONY: all clean distclean dirs \
        openssl curl dropbear cjson mosquitto pureftpd libfuse \
        download-all strip-all package

all: dirs openssl curl dropbear cjson mosquitto pureftpd libfuse strip-all package
	@echo ""
	@echo "========================================================"
	@echo "  Build complete! Artifacts in: $(OUT_DIR)"
	@echo "========================================================"

dirs:
	@mkdir -p $(BUILD_DIR) $(STAGING_DIR) $(STAGING_LIB) $(STAGING_BIN) \
	          $(STAGING_INC) $(OUT_DIR) $(DOWNLOAD_DIR)

# ── Helper: download if missing ────────────────────────────────────────────
define download
	@if [ ! -f $(DOWNLOAD_DIR)/$(notdir $(1)) ]; then \
	    echo "  DL  $(notdir $(1))"; \
	    wget -q --show-progress -P $(DOWNLOAD_DIR) $(1); \
	fi
endef

# ============================================================
#  1. OpenSSL 3.3.2
# ============================================================
OPENSSL_SRC := $(BUILD_DIR)/openssl-$(OPENSSL_VER)

openssl: $(STAGING_LIB)/libssl.so.3

$(STAGING_LIB)/libssl.so.3:
	$(call download,$(OPENSSL_URL))
	@if [ ! -d $(OPENSSL_