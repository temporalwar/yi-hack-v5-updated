FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

# ── Host build tools ───────────────────────────────────────────────────────
# Ubuntu 18.04 matches the upstream yi-hack-v5 build environment exactly.
# 32-bit libs required: toolchain binaries are i686 ELFs.
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
    build-essential autoconf automake libtool pkg-config \
    curl wget ca-certificates git \
    bzip2 xz-utils unzip file \
    libssl-dev zlib1g-dev \
    python3 python3-pip python3-setuptools \
    libc6:i386 libncurses5:i386 libstdc++6:i386 zlib1g:i386 \
    && rm -rf /var/lib/apt/lists/*

# ── Upgrade CMake ──────────────────────────────────────────────────────────
# Ubuntu 18.04 ships CMake 3.10.2 — mosquitto 2.1.x requires 3.18+
# Install CMake 3.25.3 directly from Kitware
RUN wget -q https://github.com/Kitware/CMake/releases/download/v3.25.3/cmake-3.25.3-linux-x86_64.sh \
    -O /tmp/cmake.sh && \
    chmod +x /tmp/cmake.sh && \
    /tmp/cmake.sh --skip-license --prefix=/usr/local && \
    rm /tmp/cmake.sh && \
    cmake --version

# ── Fix Python 3.6 pip environment requirements ───────────────────────────
# Install an older version of setuptools and wheel so meson can build from source
RUN pip3 install 'setuptools<58.0.0' wheel

# ── Pin exact meson/ninja versions from upstream wiki ─────────────────────
# upstream specifies meson==0.51.1 and ninja==1.9.0 explicitly
RUN pip3 install 'meson==0.51.1' 'ninja==1.9.0'

# ── Install ninja binary (meson needs it on PATH) ─────────────────────────
RUN pip3 show ninja && \
    ln -sf $(python3 -c "import ninja; import os; print(os.path.dirname(ninja.__file__))")/data/bin/ninja /usr/local/bin/ninja || \
    (apt-get update && apt-get install -y ninja-build && rm -rf /var/lib/apt/lists/*)

# ── Download and extract toolchain ────────────────────────────────────────
# Confirmed from diagnostic: binaries at bin/, NOT target/bin/
# Full prefix: arm-hisiv300-linux-uclibcgnueabi-
RUN mkdir -p /opt/hisi-linux/x86-arm && \
    curl -fL "https://github.com/OpenIPC/toolchains/releases/download/v1/arm-hisiv300-linux.tar.bz2" \
    -o /tmp/tc.tar.bz2 && \
    tar -xjf /tmp/tc.tar.bz2 -C /opt/hisi-linux/x86-arm/ && \
    rm /tmp/tc.tar.bz2

ENV TC_BIN=/opt/hisi-linux/x86-arm/arm-hisiv300-linux/bin
ENV PATH="${TC_BIN}:${PATH}"

# ── Verify toolchain ───────────────────────────────────────────────────────
RUN echo "=== Toolchain ===" && \
    ${TC_BIN}/arm-hisiv300-linux-uclibcgnueabi-gcc --version && \
    echo "=== CMake ===" && \
    cmake --version && \
    echo "=== Meson ===" && \
    meson --version && \
    echo "=== Ninja ===" && \
    ninja --version && \
    echo "=== All OK ==="

WORKDIR /build

COPY Makefile .
COPY scripts/ scripts/
COPY patches/ patches/

CMD ["make", "all"]
