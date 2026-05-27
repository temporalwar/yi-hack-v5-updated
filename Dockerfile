FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TOOLCHAIN_DIR=/opt/hisi-linux/x86-arm/arm-hisiv300-linux

# ── Build host dependencies + 32-bit libs for HiSilicon toolchain ──────────
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl wget ca-certificates git \
    autoconf automake libtool pkg-config \
    cmake ninja-build python3 python3-pip \
    bzip2 xz-utils unzip file tree \
    libssl-dev zlib1g-dev \
    libc6:i386 libstdc++6:i386 zlib1g:i386 \
    && pip3 install meson==1.3.2 \
    && rm -rf /var/lib/apt/lists/*

# ── Toolchain — extract and inspect actual structure ───────────────────────
RUN mkdir -p /opt/hisi-linux/x86-arm && \
    curl -fL "https://github.com/OpenIPC/toolchains/releases/download/v1/arm-hisiv300-linux.tar.bz2" \
         -o /tmp/tc.tar.bz2 && \
    tar -xjf /tmp/tc.tar.bz2 -C /opt/hisi-linux/x86-arm/ && \
    rm /tmp/tc.tar.bz2 && \
    echo "=== Extracted structure ===" && \
    find /opt/hisi-linux -maxdepth 6 -name "*gcc*" 2>/dev/null && \
    echo "=== Top level ===" && \
    ls /opt/hisi-linux/x86-arm/ && \
    echo "=== Contents of toolchain dir ===" && \
    ls /opt/hisi-linux/x86-arm/arm-hisiv300-linux/ 2>/dev/null || \
    (echo "=== arm-hisiv300-linux not found, listing all ===" && \
     find /opt/hisi-linux -maxdepth 4 -type d | head -30)

WORKDIR /build
COPY Makefile .
COPY scripts/ scripts/
COPY patches/ patches/

CMD ["make", "all"]
