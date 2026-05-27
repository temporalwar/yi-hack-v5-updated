FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ── Host build tools + 32-bit libs ────────────────────────────────────────
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

# ── Download toolchain and show EXACTLY where it extracts ─────────────────
RUN mkdir -p /opt/hisi-linux/x86-arm && \
    curl -fL "https://github.com/OpenIPC/toolchains/releases/download/v1/arm-hisiv300-linux.tar.bz2" \
         -o /tmp/tc.tar.bz2 && \
    echo "=== First 30 paths inside tarball ===" && \
    tar -tjf /tmp/tc.tar.bz2 | head -30 && \
    echo "=== Extracting ===" && \
    tar -xjf /tmp/tc.tar.bz2 -C /opt/hisi-linux/x86-arm/ && \
    rm /tmp/tc.tar.bz2 && \
    echo "=== Finding gcc ===" && \
    find /opt/hisi-linux -name "*gcc*" 2>/dev/null | head -10 && \
    echo "=== Full tree (4 levels) ===" && \
    find /opt/hisi-linux -maxdepth 4 -type d | sort

WORKDIR /build
COPY Makefile .
COPY scripts/ scripts/
COPY patches/ patches/

CMD ["echo", "Diagnostic build complete - check logs above"]
