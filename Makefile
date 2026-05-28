# ============================================================
#  yi-hack-v5 updated package update build system
#  (Copy-Paste Safe Version - Web UI Packaging Included)
# ============================================================

# ── Toolchain ─────────────────────────────────────────────────────────────
TOOLCHAIN_DIR ?= /opt/hisi-linux/x86-arm/arm-hisiv300-linux
TC_BIN        := $(TOOLCHAIN_DIR)/bin
CROSS_PREFIX  := arm-hisiv300-linux-uclibcgnueabi-
CROSS         := $(TC_BIN)/$(CROSS_PREFIX)

SYSROOT       := $(TOOLCHAIN_DIR)/target
export PATH   := $(TC_BIN):$(PATH)

CC      := $(CROSS)gcc
CXX     := $(CROSS)g++
AR      := $(CROSS)ar
RANLIB  := $(CROSS)ranlib
STRIP   := $(CROSS)strip
LD      := $(CROSS)ld

HOST_TRIPLE := arm-hisiv300-linux-uclibcgnueabi

# ── Output layout ─────────────────────────────────────────────────────────
BUILD_DIR    := $(CURDIR)/build
STAGING_DIR  := $(CURDIR)/staging
OUT_DIR      := $(CURDIR)/output

STAGING_LIB  := $(STAGING_DIR)/lib
STAGING_BIN  := $(STAGING_DIR)/bin
STAGING_SBIN := $(STAGING_DIR)/sbin
STAGING_INC  := $(STAGING_DIR)/include

# ── Compiler flags ────────────────────────────────────────────────────────
COMMON_CFLAGS   := -Os -mcpu=arm926ej-s -march=armv5te -mfloat-abi=soft -msoft-float -fno-short-enums -ffunction-sections -fdata-sections --sysroot=$(SYSROOT)
COMMON_LDFLAGS  := -Wl,--gc-sections -L$(STAGING_LIB) -L$(SYSROOT)/armv5te_arm9_soft/lib --sysroot=$(SYSROOT)
PKG_CONFIG_PATH := $(STAGING_LIB)/pkgconfig

# ── Package versions ───────────────────────────────────────────────────────
OPENSSL_VER   := 3.3.7
CURL_VER      := 8.20.0
DROPBEAR_VER  := 2026.91
CJSON_VER     := 1.7.18
MOSQUITTO_VER := 2.1.2
PUREFTPD_VER  := 1.0.54
LIBFUSE_VER   := 3.18.2

# ── Download URLs ──────────────────────────────────────────────────────────
OPENSSL_URL   := https://github.com/openssl/openssl/releases/download/openssl-$(OPENSSL_VER)/openssl-$(OPENSSL_VER).tar.gz
CURL_URL      := https://github.com/curl/curl/releases/download/curl-$(subst .,_,$(CURL_VER))/curl-$(CURL_VER).tar.gz
DROPBEAR_URL  := https://matt.ucc.asn.au/dropbear/releases/dropbear-$(DROPBEAR_VER).tar.bz2
CJSON_URL     := https://github.com/DaveGamble/cJSON/archive/refs/tags/v$(CJSON_VER).tar.gz
MOSQUITTO_URL := https://github.com/eclipse-mosquitto/mosquitto/archive/refs/tags/v$(MOSQUITTO_VER).tar.gz
PUREFTPD_URL  := https://download.pureftpd.org/pub/pure-ftpd/releases/pure-ftpd-$(PUREFTPD_VER).tar.gz
LIBFUSE_URL   := https://github.com/libfuse/libfuse/releases/download/fuse-$(LIBFUSE_VER)/fuse-$(LIBFUSE_VER).tar.gz

DOWNLOAD_DIR := $(CURDIR)/downloads

# ── Phony targets ──────────────────────────────────────────────────────────
.PHONY: all clean distclean dirs openssl curl dropbear cjson mosquitto pureftpd libfuse strip-all package

all: dirs openssl curl dropbear cjson mosquitto pureftpd libfuse strip-all package
	@echo ""
	@echo "========================================================"
	@echo "  Build complete! Artifacts in: $(OUT_DIR)"
	@echo "========================================================"

dirs:
	@mkdir -p $(BUILD_DIR) $(STAGING_DIR) $(STAGING_LIB) $(STAGING_BIN) $(STAGING_SBIN) $(STAGING_INC) $(OUT_DIR) $(DOWNLOAD_DIR)

define download
	@if [ ! -f $(DOWNLOAD_DIR)/$(notdir $(1)) ]; then echo "  DL  $(notdir $(1))"; wget -q --show-progress -P $(DOWNLOAD_DIR) $(1); fi
endef

# ============================================================
#  1. OpenSSL
# ============================================================
OPENSSL_SRC := $(BUILD_DIR)/openssl-$(OPENSSL_VER)

openssl: $(STAGING_LIB)/libssl.so.3

$(STAGING_LIB)/libssl.so.3:
	$(call download,$(OPENSSL_URL))
	@if [ ! -d $(OPENSSL_SRC) ]; then tar -xzf $(DOWNLOAD_DIR)/openssl-$(OPENSSL_VER).tar.gz -C $(BUILD_DIR); fi
	@echo "  CFG openssl-$(OPENSSL_VER)"
	cd $(OPENSSL_SRC) && PATH="$(TC_BIN):$$PATH" CFLAGS="$(COMMON_CFLAGS)" ./Configure linux-armv4 --cross-compile-prefix="$(CROSS_PREFIX)" --prefix=$(STAGING_DIR) --openssldir=$(STAGING_DIR)/etc/ssl shared no-asm no-hw no-engine no-async no-tests no-docs -fPIC -D_GNU_SOURCE
	@echo "  BUILD openssl-$(OPENSSL_VER)"
	$(MAKE) -C $(OPENSSL_SRC) -j$(shell nproc) PATH="$(TC_BIN):$$PATH"
	@echo "  INSTALL openssl-$(OPENSSL_VER)"
	$(MAKE) -C $(OPENSSL_SRC) install_sw PATH="$(TC_BIN):$$PATH"
	@echo "  OK openssl-$(OPENSSL_VER)"

# ============================================================
#  2. curl
# ============================================================
CURL_SRC := $(BUILD_DIR)/curl-$(CURL_VER)

curl: openssl $(STAGING_BIN)/curl

$(STAGING_BIN)/curl:
	$(call download,$(CURL_URL))
	@if [ ! -d $(CURL_SRC) ]; then tar -xzf $(DOWNLOAD_DIR)/curl-$(CURL_VER).tar.gz -C $(BUILD_DIR); fi
	@echo "  CFG curl-$(CURL_VER)"
	cd $(CURL_SRC) && CC="$(CC)" AR="$(AR)" RANLIB="$(RANLIB)" CFLAGS="$(COMMON_CFLAGS) -I$(STAGING_INC)" LDFLAGS="$(COMMON_LDFLAGS)" PKG_CONFIG_PATH="$(PKG_CONFIG_PATH)" ./configure --host=$(HOST_TRIPLE) --prefix=$(STAGING_DIR) --with-openssl=$(STAGING_DIR) --disable-shared --enable-static --disable-ldap --disable-manual --disable-verbose --without-libpsl --without-libidn2 --without-brotli --without-zstd --disable-ftp --disable-file --disable-dict --disable-telnet --disable-tftp --disable-pop3 --disable-imap --disable-smtp --disable-gopher --disable-rtsp --disable-mqtt
	@echo "  BUILD curl-$(CURL_VER)"
	$(MAKE) -C $(CURL_SRC) -j$(shell nproc)
	$(MAKE) -C $(CURL_SRC) install
	@echo "  OK curl-$(CURL_VER)"

# ============================================================
#  3. Dropbear
# ============================================================
DROPBEAR_SRC := $(BUILD_DIR)/dropbear-$(DROPBEAR_VER)

dropbear: openssl $(STAGING_SBIN)/dropbear

$(STAGING_SBIN)/dropbear:
	$(call download,$(DROPBEAR_URL))
	@if [ ! -d $(DROPBEAR_SRC) ]; then tar -xjf $(DOWNLOAD_DIR)/dropbear-$(DROPBEAR_VER).tar.bz2 -C $(BUILD_DIR); fi
	@if [ -f patches/dropbear-uclibc-compat.patch ]; then patch -N -p1 -d $(DROPBEAR_SRC) < patches/dropbear-uclibc-compat.patch || true; fi
	@echo "  CFG dropbear-$(DROPBEAR_VER)"
	cd $(DROPBEAR_SRC) && CC="$(CC)" AR="$(AR)" RANLIB="$(RANLIB)" CFLAGS="$(COMMON_CFLAGS) -I$(STAGING_INC)" LDFLAGS="$(COMMON_LDFLAGS)" ./configure --host=$(HOST_TRIPLE) --prefix=$(STAGING_DIR) --sysconfdir=/tmp/sd/yi-hack-v5/etc --disable-zlib --disable-wtmp --disable-lastlog --enable-bundled-libtom
	@echo "#define DROPBEAR_SVR_DROP_PRIVS 0" > $(DROPBEAR_SRC)/localoptions.h
	@echo "#define DROPBEAR_SVR_LOCALSTREAMFWD 0" >> $(DROPBEAR_SRC)/localoptions.h
	@echo "#define DROPBEAR_SVR_MULTIUSER 0" >> $(DROPBEAR_SRC)/localoptions.h
	@echo "  BUILD dropbear-$(DROPBEAR_VER)"
	$(MAKE) -C $(DROPBEAR_SRC) -j$(shell nproc) PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp"
	$(MAKE) -C $(DROPBEAR_SRC) install PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp"
	@echo "  OK dropbear-$(DROPBEAR_VER)"

# ============================================================
#  4. cJSON
# ============================================================
CJSON_SRC   := $(BUILD_DIR)/cJSON-$(CJSON_VER)
CJSON_BUILD := $(BUILD_DIR)/cJSON-$(CJSON_VER)-build

cjson: $(STAGING_LIB)/libcjson.a

$(STAGING_LIB)/libcjson.a:
	$(call download,$(CJSON_URL))
	@if [ ! -d $(CJSON_SRC) ]; then tar -xzf $(DOWNLOAD_DIR)/v$(CJSON_VER).tar.gz -C $(BUILD_DIR); fi
	@mkdir -p $(CJSON_BUILD)
	@echo "  CFG cJSON-$(CJSON_VER)"
	cd $(CJSON_BUILD) && cmake $(CJSON_SRC) \
		-DCMAKE_TOOLCHAIN_FILE=$(CURDIR)/scripts/hisiv300.cmake \
		-DCMAKE_INSTALL_PREFIX=$(STAGING_DIR) \
		-DCMAKE_BUILD_TYPE=MinSizeRel \
		-DENABLE_CJSON_TEST=OFF \
		-DENABLE_CJSON_UTILS=OFF \
		-DBUILD_SHARED_LIBS=OFF \
		-DBUILD_STATIC_LIBS=ON
	@echo "  BUILD cJSON-$(CJSON_VER)"
	$(MAKE) -C $(CJSON_BUILD) -j$(shell nproc)
	$(MAKE) -C $(CJSON_BUILD) install
	@echo "  OK cJSON-$(CJSON_VER)"

# ============================================================
#  5. Mosquitto
# ============================================================
MOSQUITTO_SRC   := $(BUILD_DIR)/mosquitto-$(MOSQUITTO_VER)
MOSQUITTO_BUILD := $(BUILD_DIR)/mosquitto-$(MOSQUITTO_VER)-build

mosquitto: openssl cjson $(STAGING_LIB)/libmosquitto.so.1

$(STAGING_LIB)/libmosquitto.so.1:
	$(call download,$(MOSQUITTO_URL))
	@if [ ! -d $(MOSQUITTO_SRC) ]; then tar -xzf $(DOWNLOAD_DIR)/v$(MOSQUITTO_VER).tar.gz -C $(BUILD_DIR); fi
	@mkdir -p $(MOSQUITTO_BUILD)
	@echo "  CFG mosquitto-$(MOSQUITTO_VER)"
	cd $(MOSQUITTO_BUILD) && cmake $(MOSQUITTO_SRC) \
		-DCMAKE_TOOLCHAIN_FILE=$(CURDIR)/scripts/hisiv300.cmake \
		-DCMAKE_INSTALL_PREFIX=$(STAGING_DIR) \
		-DCMAKE_BUILD_TYPE=MinSizeRel \
		-DOPENSSL_ROOT_DIR=$(STAGING_DIR) \
		-DOPENSSL_CRYPTO_LIBRARY=$(STAGING_LIB)/libcrypto.so \
		-DOPENSSL_SSL_LIBRARY=$(STAGING_LIB)/libssl.so \
		-DOPENSSL_INCLUDE_DIR=$(STAGING_INC) \
		-DCJSON_INCLUDE_DIR=$(STAGING_INC) \
		-DCJSON_LIBRARY=$(STAGING_LIB)/libcjson.a \
		-DWITH_BROKER=OFF \
		-DWITH_APPS=ON \
		-DWITH_PLUGINS=OFF \
		-DWITH_TLS=ON \
		-DWITH_TLS_PSK=OFF \
		-DWITH_THREADING=ON \
		-DWITH_DOCS=OFF \
		-DWITH_TESTING=OFF \
		-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=OFF \
		-DWITH_STATIC_LIBRARIES=OFF \
		-DWITH_SHARED_LIBRARIES=ON
	@echo "  BUILD mosquitto-$(MOSQUITTO_VER)"
	$(MAKE) -C $(MOSQUITTO_BUILD) -j$(shell nproc)
	$(MAKE) -C $(MOSQUITTO_BUILD) install
	@if [ ! -f $(STAGING_LIB)/libmosquitto.so.1 ]; then ln -sf libmosquitto.so.$(MOSQUITTO_VER) $(STAGING_LIB)/libmosquitto.so.1; fi
	@echo "  OK mosquitto-$(MOSQUITTO_VER)"

# ============================================================
#  6. Pure-FTPd
# ============================================================
PUREFTPD_SRC := $(BUILD_DIR)/pure-ftpd-$(PUREFTPD_VER)

pureftpd: openssl $(STAGING_SBIN)/pure-ftpd

$(STAGING_SBIN)/pure-ftpd:
	$(call download,$(PUREFTPD_URL))
	@if [ ! -d $(PUREFTPD_SRC) ]; then tar -xzf $(DOWNLOAD_DIR)/pure-ftpd-$(PUREFTPD_VER).tar.gz -C $(BUILD_DIR); fi
	@echo "  CFG pure-ftpd-$(PUREFTPD_VER)"
	cd $(PUREFTPD_SRC) && CC="$(CC)" AR="$(AR)" RANLIB="$(RANLIB)" CFLAGS="$(COMMON_CFLAGS) -I$(STAGING_INC)" LDFLAGS="$(COMMON_LDFLAGS)" ./configure --host=$(HOST_TRIPLE) --prefix=$(STAGING_DIR) --sysconfdir=/tmp/sd/yi-hack-v5/etc --without-ldap --without-mysql --without-pgsql --without-pam --without-extauth --with-tls --with-openssl=$(STAGING_DIR) --without-bonjour --without-inetd --with-privsep --without-capabilities
	@echo "  BUILD pure-ftpd-$(PUREFTPD_VER)"
	$(MAKE) -C $(PUREFTPD_SRC) -j$(shell nproc)
	$(MAKE) -C $(PUREFTPD_SRC) install
	@echo "  OK pure-ftpd-$(PUREFTPD_VER)"

# ============================================================
#  7. libfuse3
# ============================================================
LIBFUSE_SRC   := $(BUILD_DIR)/fuse-$(LIBFUSE_VER)
LIBFUSE_BUILD := $(BUILD_DIR)/fuse-$(LIBFUSE_VER)-build

libfuse: $(STAGING_LIB)/libfuse3.so.3

$(STAGING_LIB)/libfuse3.so.3:
	$(call download,$(LIBFUSE_URL))
	@if [ ! -d $(LIBFUSE_SRC) ]; then tar -xzf $(DOWNLOAD_DIR)/fuse-$(LIBFUSE_VER).tar.gz -C $(BUILD_DIR); fi
	@mkdir -p $(LIBFUSE_BUILD)
	@echo "  CFG libfuse-$(LIBFUSE_VER)"
	cd $(LIBFUSE_BUILD) && PKG_CONFIG_PATH="$(PKG_CONFIG_PATH)" CC="$(CC)" CFLAGS="$(COMMON_CFLAGS)" LDFLAGS="$(COMMON_LDFLAGS)" meson setup $(LIBFUSE_SRC) --cross-file $(CURDIR)/scripts/hisiv300-meson.txt --prefix=$(STAGING_DIR) --buildtype=minsize -Ddefault_library=shared -Dexamples=false -Dtests=false -Duseroot=false -Dutils=false
	@echo "  BUILD libfuse-$(LIBFUSE_VER)"
	ninja -C $(LIBFUSE_BUILD)
	ninja -C $(LIBFUSE_BUILD) install
	@echo "  OK libfuse-$(LIBFUSE_VER)"

# ============================================================
#  Strip and package
# ============================================================
strip-all:
	@echo "  STRIP binaries"
	@find $(STAGING_BIN) $(STAGING_SBIN) -type f -exec $(STRIP) --strip-unneeded {} \; 2>/dev/null || true
	@find $(STAGING_LIB) -name "*.so*" -type f -exec $(STRIP) --strip-unneeded {} \; 2>/dev/null || true

package:
	@echo "  PKG  firmware.tgz"
	@mkdir -p $(OUT_DIR)/bin $(OUT_DIR)/sbin $(OUT_DIR)/lib
	@cp -a $(STAGING_BIN)/. $(OUT_DIR)/bin/ 2>/dev/null || true
	@cp -a $(STAGING_SBIN)/. $(OUT_DIR)/sbin/ 2>/dev/null || true
	@cp -a $(STAGING_LIB)/. $(OUT_DIR)/lib/ 2>/dev/null || true
	@cd $(OUT_DIR) && tar -czf $(CURDIR)/firmware.tgz .
	@echo "  OUT  firmware.tgz"

clean:
	rm -rf $(BUILD_DIR) $(STAGING_DIR) $(OUT_DIR)

distclean: clean
	rm -rf $(DOWNLOAD_DIR)
