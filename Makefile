# ============================================================
#  yi-hack-v5 package update build system
#  Target: arm-hisiv300-linux-uclibcgnueabi (Hi3518ev200 / ARM926EJ-S)
#  Host:   x86_64 Linux
#
#  Confirmed toolchain layout from OpenIPC tarball:
#    Binaries: /opt/hisi-linux/x86-arm/arm-hisiv300-linux/bin/
#    Prefix:   arm-hisiv300-linux-uclibcgnueabi-
#    Sysroot:  .../target/
# ============================================================

# ── Toolchain ─────────────────────────────────────────────────────────────
TOOLCHAIN_DIR ?= /opt/hisi-linux/x86-arm/arm-hisiv300-linux
TC_BIN        := $(TOOLCHAIN_DIR)/bin
CROSS_PREFIX  := arm-hisiv300-linux-uclibcgnueabi-
CROSS         := $(TC_BIN)/$(CROSS_PREFIX)

# FIX: Sysroot pulled up to the base target directory to fix limits.h
SYSROOT       := $(TOOLCHAIN_DIR)/target
export PATH   := $(TC_BIN):$(PATH)

CC      := $(CROSS)gcc
CXX     := $(CROSS)g++
AR      := $(CROSS)ar
RANLIB  := $(CROSS)ranlib
# Use the toolchain stripper — never the host strip (corrupts ARM binaries)
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

# ── Compiler flags (ARM926EJ-S specific) ──────────────────────────────────
# -mfloat-abi=soft   : NO FPU on ARM926EJ-S — mandatory or Illegal instruction
# -msoft-float       : use software floating point library
# -mcpu=arm926ej-s   : exact CPU tuning
# -fno-short-enums   : uClibc ABI requirement
# --sysroot          : isolate from host glibc headers
COMMON_CFLAGS := \
    -Os \
    -mcpu=arm926ej-s \
    -march=armv5te \
    -mfloat-abi=soft \
    -msoft-float \
    -fno-short-enums \
    -ffunction-sections \
    -fdata-sections \
    --sysroot=$(SYSROOT)

# FIX: Added explicit library path for the arm9 soft multilib folder
COMMON_LDFLAGS  := -Wl,--gc-sections -L$(STAGING_LIB) -L$(SYSROOT)/armv5te_arm9_soft/lib --sysroot=$(SYSROOT)
PKG_CONFIG_PATH := $(STAGING_LIB)/pkgconfig

# ── Package versions ───────────────────────────────────────────────────────
OPENSSL_VER   := 3.3.2
CURL_VER      := 8.20.0
DROPBEAR_VER  := 2025.89
CJSON_VER     := 1.7.18
MOSQUITTO_VER := 2.1.0
PUREFTPD_VER  := 1.0.52
LIBFUSE_VER   := 3.18.1

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
.PHONY: all clean distclean dirs \
        openssl curl dropbear cjson mosquitto pureftpd libfuse \
        strip-all package

all: dirs openssl curl dropbear cjson mosquitto pureftpd libfuse strip-all package
	@echo ""
	@echo "========================================================"
	@echo "  Build complete! Artifacts in: $(OUT_DIR)"
	@echo "========================================================"

dirs:
	@mkdir -p $(BUILD_DIR) $(STAGING_DIR) $(STAGING_LIB) $(STAGING_BIN) \
	          $(STAGING_SBIN) $(STAGING_INC) $(OUT_DIR) $(DOWNLOAD_DIR)

define download
	@if [ ! -f $(DOWNLOAD_DIR)/$(notdir $(1)) ]; then \
	    echo "  DL  $(notdir $(1))"; \
	    wget -q --show-progress -P $(DOWNLOAD_DIR) $(1); \
	fi
endef

# ============================================================
#  1. OpenSSL 3.3.2
#  KEY NOTES:
#  - Use linux-armv4 target (no ARMv5 target exists in OpenSSL)
#  - no-asm: ARM926EJ-S lacks instructions used in OpenSSL's ASM
#  - no-async: uClibc lacks getcontext/makecontext
#  - Pass PATH explicitly to all sub-make calls (make depend doesn't inherit)
# ============================================================
OPENSSL_SRC := $(BUILD_DIR)/openssl-$(OPENSSL_VER)

openssl: $(STAGING_LIB)/libssl.so.3

$(STAGING_LIB)/libssl.so.3:
	$(call download,$(OPENSSL_URL))
	@if [ ! -d $(OPENSSL_SRC) ]; then \
	    tar -xzf $(DOWNLOAD_DIR)/openssl-$(OPENSSL_VER).tar.gz -C $(BUILD_DIR); \
	fi
	@echo "  CFG openssl-$(OPENSSL_VER)"
	cd $(OPENSSL_SRC) && \
	    PATH="$(TC_BIN):$$PATH" \
	    CFLAGS="$(COMMON_CFLAGS)" \
	    ./Configure linux-armv4 \
	        --cross-compile-prefix="$(CROSS_PREFIX)" \
	        --prefix=$(STAGING_DIR) \
	        --openssldir=$(STAGING_DIR)/etc/ssl \
	        shared \
	        no-asm \
	        no-hw \
	        no-engine \
	        no-async \
	        no-tests \
	        no-docs \
	        -fPIC \
	        -D_GNU_SOURCE
	@echo "  BUILD openssl-$(OPENSSL_VER)"
	$(MAKE) -C $(OPENSSL_SRC) -j$(shell nproc) PATH="$(TC_BIN):$$PATH"
	@echo "  INSTALL openssl-$(OPENSSL_VER)"
	$(MAKE) -C $(OPENSSL_SRC) install_sw PATH="$(TC_BIN):$$PATH"
	@echo "  OK openssl-$(OPENSSL_VER)"

# ============================================================
#  2. curl 8.20.0
# ============================================================
CURL_SRC := $(BUILD_DIR)/curl-$(CURL_VER)

curl: openssl $(STAGING_BIN)/curl

$(STAGING_BIN)/curl:
	$(call download,$(CURL_URL))
	@if [ ! -d $(CURL_SRC) ]; then \
	    tar -xzf $(DOWNLOAD_DIR)/curl-$(CURL_VER).tar.gz -C $(BUILD_DIR); \
	fi
	@echo "  CFG curl-$(CURL_VER)"
	cd $(CURL_SRC) && \
	    CC="$(CC)" AR="$(AR)" RANLIB="$(RANLIB)" \
	    CFLAGS="$(COMMON_CFLAGS) -I$(STAGING_INC)" \
	    LDFLAGS="$(COMMON_LDFLAGS)" \
	    PKG_CONFIG_PATH="$(PKG_CONFIG_PATH)" \
	    ./configure \
	        --host=$(HOST_TRIPLE) \
	        --prefix=$(STAGING_DIR) \
	        --with-openssl=$(STAGING_DIR) \
	        --disable-shared \
	        --enable-static \
	        --disable-ldap \
	        --disable-manual \
	        --disable-verbose \
	        --without-libpsl \
	        --without-libidn2 \
	        --without-brotli \
	        --without-zstd \
	        --disable-ftp \
	        --disable-file \
	        --disable-dict \
	        --disable-telnet \
	        --disable-tftp \
	        --disable-pop3 \
	        --disable-imap \
	        --disable-smtp \
	        --disable-gopher \
	        --disable-rtsp \
	        --disable-mqtt
	@echo "  BUILD curl-$(CURL_VER)"
	$(MAKE) -C $(CURL_SRC) -j$(shell nproc)
	$(MAKE) -C $(CURL_SRC) install
	@echo "  OK curl-$(CURL_VER)"

# ============================================================
#  3. Dropbear 2025.89
#  - CVE-2025-14282 patched
#  - DROPBEAR_SVR_DROP_PRIVS disabled: setresgid() unavailable in uClibc
#  - Prefix set to SD card path so configs resolve correctly on camera
# ============================================================
DROPBEAR_SRC := $(BUILD_DIR)/dropbear-$(DROPBEAR_VER)

dropbear: openssl $(STAGING_SBIN)/dropbear

$(STAGING_SBIN)/dropbear:
	$(call download,$(DROPBEAR_URL))
	@if [ ! -d $(DROPBEAR_SRC) ]; then \
	    tar -xjf $(DOWNLOAD_DIR)/dropbear-$(DROPBEAR_VER).tar.bz2 -C $(BUILD_DIR); \
	fi
	@if [ -f patches/dropbear-uclibc-compat.patch ]; then \
	    patch -N -p1 -d $(DROPBEAR_SRC) < patches/dropbear-uclibc-compat.patch || true; \
	fi
	@echo "  CFG dropbear-$(DROPBEAR_VER)"
	cd $(DROPBEAR_SRC) && \
	    CC="$(CC)" AR="$(AR)" RANLIB="$(RANLIB)" \
	    CFLAGS="$(COMMON_CFLAGS) -I$(STAGING_INC)" \
	    LDFLAGS="$(COMMON_LDFLAGS)" \
	    ./configure \
	        --host=$(HOST_TRIPLE) \
	        --prefix=$(STAGING_DIR) \
	        --sysconfdir=/tmp/sd/yi-hack-v5/etc \
	        --disable-zlib \
	        --disable-wtmp \
	        --disable-lastlog \
	        --enable-bundled-libtom
	@echo "#define DROPBEAR_SVR_DROP_PRIVS 0" >> $(DROPBEAR_SRC)/localoptions.h
	@echo "  BUILD dropbear-$(DROPBEAR_VER)"
	$(MAKE) -C $(DROPBEAR_SRC) -j$(shell nproc) \
	    PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp"
	$(MAKE) -C $(DROPBEAR_SRC) install \
	    PROGRAMS="dropbear dbclient dropbearkey dropbearconvert scp"
	@echo "  OK dropbear-$(DROPBEAR_VER)"

# ============================================================
#  4. cJSON 1.7.18
#  - mosquitto 2.x requires cJSON
#  - Built as static lib only — only mosquitto uses it, no need for shared
# ============================================================
CJSON_SRC   := $(BUILD_DIR)/cJSON-$(CJSON_VER)
CJSON_BUILD := $(BUILD_DIR)/cJSON-$(CJSON_VER)-build

cjson: $(STAGING_LIB)/libcjson.a

$(STAGING_LIB)/libcjson.a:
	$(call download,$(CJSON_URL))
	@if [ ! -d $(CJSON_SRC) ]; then \
	    tar -xzf $(DOWNLOAD_DIR)/v$(CJSON_VER).tar.gz -C $(BUILD_DIR); \
	fi
	@mkdir -p $(CJSON_BUILD)
	@echo "  CFG cJSON-$(CJSON_VER)"
	cd $(CJSON_BUILD) && \
	    cmake $(CJSON_SRC) \
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
#  5. Mosquitto 2.1.0
#  - WITH_BROKER=OFF: only libmosquitto + pub/sub tools needed
#  - cJSON linked statically — saves space on camera filesystem
#  - sysconfdir points to SD card location
# ============================================================
MOSQUITTO_SRC   := $(BUILD_DIR)/mosquitto-$(MOSQUITTO_VER)
MOSQUITTO_BUILD := $(BUILD_DIR)/mosquitto-$(MOSQUITTO_VER)-build

mosquitto: openssl cjson $(STAGING_LIB)/libmosquitto.so.1

$(STAGING_LIB)/libmosquitto.so.1:
	$(call download,$(MOSQUITTO_URL))
	@if [ ! -d $(MOSQUITTO_SRC) ]; then \
	    tar -xzf $(DOWNLOAD_DIR)/v$(MOSQUITTO_VER).tar.gz -C $(BUILD_DIR); \
	fi
	@mkdir -p $(MOSQUITTO_BUILD)
	@echo "  CFG mosquitto-$(MOSQUITTO_VER)"
	cd $(MOSQUITTO_BUILD) && \
	    cmake $(MOSQUITTO_SRC) \
	        -DCMAKE_TOOLCHAIN_FILE=$(CURDIR)/scripts/hisiv300.cmake \
	        -DCMAKE_INSTALL_PREFIX=$(STAGING_DIR) \
	        -DCMAKE_BUILD_TYPE=MinSizeRel \
	        -DOPENSSL_ROOT_DIR=$(STAGING_DIR) \
	        -DCJSON_INCLUDE_DIRS=$(STAGING_INC) \
	        -DCJSON_LIBRARIES=$(STAGING_LIB)/libcjson.a \
	        -DWITH_BROKER=OFF \
	        -DWITH_APPS=ON \
	        -DWITH_PLUGINS=OFF \
	        -DWITH_TLS=ON \
	        -DWITH_TLS_PSK=OFF \
	        -DWITH_THREADING=ON \
	        -DDOCUMENTATION=OFF \
	        -DWITH_STATIC_LIBRARIES=OFF \
	        -DWITH_SHARED_LIBRARIES=ON
	@echo "  BUILD mosquitto-$(MOSQUITTO_VER)"
	$(MAKE) -C $(MOSQUITTO_BUILD) -j$(shell nproc)
	$(MAKE) -C $(MOSQUITTO_BUILD) install
	@if [ ! -f $(STAGING_LIB)/libmosquitto.so.1 ]; then \
	    ln -sf libmosquitto.so.$(MOSQUITTO_VER) $(STAGING_LIB)/libmosquitto.so.1; \
	fi
	@echo "  OK mosquitto-$(MOSQUITTO_VER)"

# ============================================================
#  6. Pure-FTPd 1.0.52
# ============================================================
PUREFTPD_SRC := $(BUILD_DIR)/pure-ftpd-$(PUREFTPD_VER)

pureftpd: openssl $(STAGING_SBIN)/pure-ftpd

$(STAGING_SBIN)/pure-ftpd:
	$(call download,$(PUREFTPD_URL))
	@if [ ! -d $(PUREFTPD_SRC) ]; then \
	    tar -xzf $(DOWNLOAD_DIR)/pure-ftpd-$(PUREFTPD_VER).tar.gz -C $(BUILD_DIR); \
	fi
	@echo "  CFG pure-ftpd-$(PUREFTPD_VER)"
	cd $(PUREFTPD_SRC) && \
	    CC="$(CC)" AR="$(AR)" RANLIB="$(RANLIB)" \
	    CFLAGS="$(COMMON_CFLAGS) -I$(STAGING_INC)" \
	    LDFLAGS="$(COMMON_LDFLAGS)" \
	    ./configure \
	        --host=$(HOST_TRIPLE) \
	        --prefix=$(STAGING_DIR) \
	        --sysconfdir=/tmp/sd/yi-hack-v5/etc \
	        --without-ldap \
	        --without-mysql \
	        --without-pgsql \
	        --without-pam \
	        --without-extauth \
	        --with-tls \
	        --with-openssl=$(STAGING_DIR) \
	        --without-bonjour \
	        --without-inetd \
	        --with-privsep \
	        --without-capabilities
	@echo "  BUILD pure-ftpd-$(PUREFTPD_VER)"
	$(MAKE) -C $(PUREFTPD_SRC) -j$(shell nproc)
	$(MAKE) -C $(PUREFTPD_SRC) install
	@echo "  OK pure-ftpd-$(PUREFTPD_VER)"

# ============================================================
#  7. libfuse3 3.18.1
# ============================================================
LIBFUSE_SRC   := $(BUILD_DIR)/fuse-$(LIBFUSE_VER)
LIBFUSE_BUILD := $(BUILD_DIR)/fuse-$(LIBFUSE_VER)-build

libfuse: $(STAGING_LIB)/libfuse3.so.3

$(STAGING_LIB)/libfuse3.so.3:
	$(call download,$(LIBFUSE_URL))
	@if [ ! -d $(LIBFUSE_SRC) ]; then \
	    tar -xzf $(DOWNLOAD_DIR)/fuse-$(LIBFUSE_VER).tar.gz -C $(BUILD_DIR); \
	fi
	@echo "  CFG libfuse-$(LIBFUSE_VER)"
	meson setup $(LIBFUSE_BUILD) $(LIBFUSE_SRC) \
	    --cross-file=$(CURDIR)/scripts/hisiv300-meson.ini \
	    --prefix=$(STAGING_DIR) \
	    --buildtype=minsize \
	    -Dexamples=false \
	    -Dtests=false \
	    -Duseroot=false \
	    -Dutils=false \
	    -Dinitscriptdir=''
	@echo "  BUILD libfuse-$(LIBFUSE_VER)"
	ninja -C $(LIBFUSE_BUILD) -j$(shell nproc)
	ninja -C $(LIBFUSE_BUILD) install
	@echo "  OK libfuse-$(LIBFUSE_VER)"

# ── Strip using toolchain stripper (NEVER host strip — corrupts ARM ELFs) ──
strip-all:
	@echo "  STRIP binaries"
	@find $(STAGING_BIN) $(STAGING_SBIN) -type f 2>/dev/null | \
	    while read f; do \
	        file "$$f" | grep -q "ELF.*ARM" && \
	            $(STRIP) --strip-unneeded "$$f" 2>/dev/null || true; \
	    done
	@echo "  STRIP libraries"
	@find $(STAGING_LIB) -name "*.so*" -type f 2>/dev/null | \
	    while read f; do \
	        file "$$f" | grep -q "ELF.*ARM" && \
	            $(STRIP) --strip-unneeded "$$f" 2>/dev/null || true; \
	    done

# ── Assemble SD card overlay tarball ──────────────────────────────────────
package:
	@echo "  PKG  Assembling firmware overlay..."
	@mkdir -p $(OUT_DIR)/yi-hack-v5/{bin,sbin,lib}
	@for b in curl dropbear dbclient dropbearkey dropbearconvert scp \
	          mosquitto_pub mosquitto_sub; do \
	    [ -f $(STAGING_BIN)/$$b ] && \
	        cp -v $(STAGING_BIN)/$$b $(OUT_DIR)/yi-hack-v5/bin/ || true; \
	    done
	@[ -f $(STAGING_SBIN)/pure-ftpd ] && \
	    cp -v $(STAGING_SBIN)/pure-ftpd $(OUT_DIR)/yi-hack-v5/sbin/ || true
	@[ -f $(STAGING_SBIN)/dropbear ] && \
	    cp -v $(STAGING_SBIN)/dropbear $(OUT_DIR)/yi-hack-v5/sbin/ || true
	@for lib in \
	    libssl.so.3 libcrypto.so.3 \
	    libmosquitto.so.1 \
	    libfuse3.so.3 libfuse3.so.3.$(LIBFUSE_VER); do \
	    find $(STAGING_LIB) -name "$$lib" -type f 2>/dev/null | head -1 | \
	        xargs -I{} cp -v {} $(OUT_DIR)/yi-hack-v5/lib/ 2>/dev/null || true; \
	    done
	@printf "Built on %s\n"     "$$(date -u)"       > $(OUT_DIR)/yi-hack-v5/package-versions.txt
	@printf "openssl    %s\n"   "$(OPENSSL_VER)"    >> $(OUT_DIR)/yi-hack-v5/package-versions.txt
	@printf "curl       %s\n"   "$(CURL_VER)"       >> $(OUT_DIR)/yi-hack-v5/package-versions.txt
	@printf "dropbear   %s\n"   "$(DROPBEAR_VER)"   >> $(OUT_DIR)/yi-hack-v5/package-versions.txt
	@printf "cjson      %s\n"   "$(CJSON_VER)"      >> $(OUT_DIR)/yi-hack-v5/package-versions.txt
	@printf "mosquitto  %s\n"   "$(MOSQUITTO_VER)"  >> $(OUT_DIR)/yi-hack-v5/package-versions.txt
	@printf "pure-ftpd  %s\n"   "$(PUREFTPD_VER)"   >> $(OUT_DIR)/yi-hack-v5/package-versions.txt
	@printf "libfuse3   %s\n"   "$(LIBFUSE_VER)"    >> $(OUT_DIR)/yi-hack-v5/package-versions.txt
	@cd $(OUT_DIR) && tar -czf ../yi-hack-v5-updated-packages.tgz yi-hack-v5/
	@echo ""
	@echo "  Tarball: $(CURDIR)/yi-hack-v5-updated-packages.tgz"

# ── Also update hisiv300.cmake and meson.ini with correct paths ────────────
clean:
	rm -rf $(BUILD_DIR) $(STAGING_DIR) $(OUT_DIR)

distclean: clean
	rm -rf $(DOWNLOAD_DIR)