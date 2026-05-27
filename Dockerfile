FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TOOLCHAIN_DIR=/opt/hisi-linux/x86-arm/arm-hisiv300-linux
ENV TC_BIN=${TOOLCHAIN_DIR}/target/bin
ENV PATH="${TC_BIN}:${PATH}"

# ── Build host dependencies + 32-bit libs for HiSilicon toolchain ──────────
# The arm-hisiv300-linux toolchain binaries are 32-bit ELFs built for i686.
# On a 64-bit Ubuntu host they need lib32 / multilib support to execute.
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl wget ca-certificates git \
    autoconf automake libtool pkg-config \
    cmake ninja-build python3 python3-pip \
    bzip2 xz-utils unzip file \
    libssl-dev zlib1g-dev \
    libc6:i386 libstdc++6:i386 zlib1g:i386 \
    && pip3 install meson==1.3.2 \
    && rm -rf /var/lib/apt/lists/*

# ── Toolchain ──────────────────────────────────────────────────────────────
RUN mkdir -p /opt/hisi-linux/x86-arm && \
    curl -fL "https://github.com/OpenIPC/toolchains/releases/download/v1/arm-hisiv300-linux.tar.bz2" \
         -o /tmp/tc.tar.bz2 && \
    tar -xjf /tmp/tc.tar.bz2 -C /opt/hisi-linux/x86-arm/ && \
    rm /tmp/tc.tar.bz2

# ── Verify toolchain works before proceeding ───────────────────────────────
RUN echo "=== Toolchain check ===" && \
    ls ${TC_BIN}/ | grep gcc && \
    file ${TC_BIN}/arm-hisiv300-linux-gcc && \
    ${TC_BIN}/arm-hisiv300-linux-gcc --version && \
    echo "=== Toolchain OK ==="

WORKDIR /build
COPY Makefile .
COPY scripts/ scripts/
COPY patches/ patches/

CMD ["make", "all"]
