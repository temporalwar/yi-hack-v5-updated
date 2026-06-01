# ============================================================
# yi-hack-v5 updated package update build system
# (Optimized Lightweight Pure C Client Implementation)
# ============================================================

# ── Toolchain ─────────────────────────────────────────────────────────────
TOOLCHAIN_DIR ?= /opt/hisi-linux/x86-arm/arm-hisiv300-linux
TC_BIN       := $(TOOLCHAIN_DIR)/bin
CROSS_PREFIX := arm-hisiv300-linux-uclibcgnueabi-
CROSS        := $(TC_BIN)/$(CROSS_PREFIX)
SYSROOT      := $(TOOLCHAIN_DIR)/target
export PATH  := $(TC_BIN):$(PATH)

CC      := $(CROSS)gcc
CXX     := $(CROSS)g++
AR      := $(CROSS)ar
RANLIB  := $(CROSS)ranlib
STRIP   := $(CROSS)strip
LD      := $(CROSS)ld
HOST_TRIPLE := arm-hisiv300-linux-uclibcgnueabi

# ── Output layout ─────────────────────────────────────────────────────────
BUILD_DIR   := $(CURDIR)/build
STAGING_DIR := $(CURDIR)/staging
OUT_DIR     := $(CURDIR)/output

STAGING_LIB  := $(STAGING_DIR)/lib
STAGING_BIN  := $(STAGING_DIR)/bin
STAGING_SBIN := $(STAGING_DIR)/sbin
STAGING_INC  := $(STAGING_DIR)/include

# ── Compiler flags ────────────────────────────────────────────────────────
COMMON_CFLAGS := -Os -mcpu=arm926ej-s -march=armv5te -mfloat-abi=soft -msoft-float -fno-short-enums -ffunction-sections -fdata-sections --sysroot=$(SYSROOT)
COMMON_LDFLAGS := -Wl,--gc-sections -L$(STAGING_LIB) -L$(SYSROOT)/armv5te_arm9_soft/lib --sysroot=$(SYSROOT) -latomic -lm
PKG_CONFIG_PATH := $(STAGING_LIB)/pkgconfig

# ── Package versions ───────────────────────────────────────────────────────
OPENSSL_VER   := 3.3.7
CURL_VER      := 8.20.0
DROPBEAR_VER  := 2025.89
CJSON_VER     := 1.7.18
MOSQUITTO_VER := 2.1.2
PUREFTPD_VER  := 1.0.54
LIBFUSE_VER   := 3.4.2

# ── Download URLs ──────────────────────────────────────────────────────────
OPENSSL_URL   := https://github.com/openssl/openssl/releases/download/openssl-$(OPENSSL_VER)/openssl-$(OPENSSL_VER).tar.gz
CURL_URL      := https://github.com/curl/curl/releases/download/curl-$(subst .,_,$(CURL_VER))/curl-$(CURL_VER).tar.gz
DROPBEAR_URL  := https://matt.ucc.asn.au/dropbear/releases/dropbear-$(DROPBEAR_VER).tar.bz2
CJSON_URL     := https://github.com/DaveGamble/cJSON/archive/refs/tags/v$(CJSON_VER).tar.gz
MOSQUITTO_URL := https://github.com/eclipse-mosquitto/mosquitto/archive/refs/tags/v$(MOSQUITTO_VER).tar.gz
PUREFTPD_URL  := https://download.pureftpd.org/pub/pure-ftpd/releases/pure-ftpd-$(PUREFTPD_VER).tar.gz
LIBFUSE_URL   := https://github.com/libfuse/libfuse/releases/download/fuse-$(LIBFUSE_VER)/fuse-$(LIBFUSE_VER).tar.xz
DOWNLOAD_DIR  := $(CURDIR)/downloads

# ── Phony targets ──────────────────────────────────────────────────────────
.PHONY: all clean distclean dirs openssl curl dropbear cjson mosquitto pureftpd libfuse strip-all package

all: dirs openssl curl dropbear cjson mosquitto pureftpd libfuse strip-all package
	@echo ""
	@echo "========================================================"

dirs:
	@mkdir -p $(BUILD_DIR) $(STAGING_DIR) $(OUT_DIR) $(DOWNLOAD_DIR)

# 1. OpenSSL
OPENSSL_SRC := $(BUILD_DIR)/openssl-$(OPENSSL_VER)
openssl: $(STAGING_LIB)/libssl.so.3

$(STAGING_LIB)/libssl.so.3:
	@if [ ! -f $(DOWNLOAD_DIR)/openssl-$(OPENSSL_VER).tar.gz ]; then echo " DL openssl-$(OPENSSL_VER).tar.gz"; wget -q --show-progress -P $(DOWNLOAD_DIR) $(OPENSSL_URL); fi
	@if [ ! -d $(OPENSSL_SRC) ]; then tar -xzf $(DOWNLOAD_DIR)/openssl-$(OPENSSL_VER).tar.gz -C $(BUILD_DIR); fi
	cd $(OPENSSL_SRC) && ./Configure linux-armv4 shared --cross-compile-prefix=$(CROSS_PREFIX) --prefix=$(STAGING_DIR) --openssldir=$(STAGING_DIR)/ssl no-async
	$(MAKE) -C $(OPENSSL_SRC) -j$(shell nproc)
	$(MAKE) -C $(OPENSSL_SRC) install_sw

# 2. Curl
CURL_SRC := $(BUILD_DIR)/curl-$(CURL_VER)
curl: $(STAGING_LIB)/libcurl.so

$(STAGING_LIB)/libcurl.so: openssl
	@if [ ! -f $(DOWNLOAD_DIR)/curl-$(CURL_VER).tar.gz ]; then echo " DL curl-$(CURL_VER).tar.gz"; wget -q --show-progress -P $(DOWNLOAD_DIR) $(CURL_URL); fi
	@if [ ! -d $(CURL_SRC) ]; then tar -xzf $(DOWNLOAD_DIR)/curl-$(CURL_VER).tar.gz -C $(BUILD_DIR); fi
	cd $(CURL_SRC) && ./configure --host=$(HOST_TRIPLE) --prefix=$(STAGING_DIR) --with-ssl=$(STAGING_DIR) --disable-static --enable-shared --without-libpsl
	$(MAKE) -C $(CURL_SRC) -j$(shell nproc)
	$(MAKE) -C $(CURL_SRC) install
