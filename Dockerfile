FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ── Host build tools + 32-bit libs for HiSilicon toolchain ────────────────
# The arm-hisiv300-linux binaries are 32-bit i686 ELFs — need i386 multilib.
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl wget ca-certificates git \
    autoconf automake libtool pkg-config \
    cmake ninja-build python3 python3-pip \
    bzip2 xz-utils unzip file \
    libssl-dev zlib1g-dev \
    libc6:i386 libncurses5:i386 libstdc++6:i386 zlib1g:i386 \
    && pip3 install meson==1.3.2 \
    && rm -rf /var/lib/apt/lists/*

# ── Download and extract toolchain ────────────────────────────────────────
# Confirmed structure: binaries are at bin/ (NOT target/bin/)
# Full prefix: arm-hisiv300-linux-uclibcgnueabi-
# Sysroot: target/usr + target/lib (armv5te_arm9_soft variant)
RUN mkdir -p /opt/hisi-linux/x86-arm && \
    curl -fL "https://github.com/OpenIPC/toolchains/releases/download/v1/arm-hisiv300-linux.tar.bz2" \
         -o /tmp/tc.tar.bz2 && \
    tar -xjf /tmp/tc.tar.bz2 -C /opt/hisi-linux/x86-arm/ && \
    rm /tmp/tc.tar.bz2

# ── Verify toolchain works ─────────────────────────────────────────────────
ENV TC_BIN=/opt/hisi-linux/x86-arm/arm-hisiv300-linux/bin
ENV SYSROOT=/opt/hisi-linux/x86-arm/arm-hisiv300-linux/target/armv5te_arm9_soft
ENV PATH="${TC_BIN}:${PATH}"

RUN echo "=== Toolchain check ===" && \
    ${TC_BIN}/arm-hisiv300-linux-uclibcgnueabi-gcc --version && \
    echo "=== Toolchain OK ==="

WORKDIR /build
COPY Makefile .
COPY scripts/ scripts/
COPY patches/ patches/

CMD ["make", "all"]
