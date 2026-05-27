FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ── Host build tools + 32-bit libs for HiSilicon toolchain ────────────────
# The arm-hisiv300-linux binaries are 32-bit i686 ELFs. Without i386 multilib
# support, Linux returns "not found" even when the file exists on disk.
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
RUN mkdir -p /opt/hisi-linux/x86-arm && \
    curl -fL "https://github.com/OpenIPC/toolchains/releases/download/v1/arm-hisiv300-linux.tar.bz2" \
         -o /tmp/tc.tar.bz2 && \
    tar -xjf /tmp/tc.tar.bz2 -C /opt/hisi-linux/x86-arm/ && \
    rm /tmp/tc.tar.bz2

# ── Dynamically find the gcc binary and verify the toolchain works ─────────
# Uses find instead of hardcoding the path — handles target/bin/ or bin/
# variations in how the tarball extracts.
RUN TOOLCHAIN_BIN=$(find /opt/hisi-linux -type f -name "arm-hisiv300-linux-gcc" -exec dirname {} \; | head -1) && \
    echo "=== Toolchain found at: $TOOLCHAIN_BIN ===" && \
    ls "$TOOLCHAIN_BIN/" | grep -E "gcc|g\+\+|ar$" && \
    "$TOOLCHAIN_BIN/arm-hisiv300-linux-gcc" --version && \
    echo "=== Toolchain OK ===" && \
    echo "export TC_BIN=$TOOLCHAIN_BIN" > /etc/toolchain.env

# ── Set PATH using the discovered bin directory ────────────────────────────
RUN . /etc/toolchain.env && \
    echo "export PATH=$TC_BIN:\$PATH" >> /etc/environment && \
    echo "$TC_BIN" >> /etc/ld.so.conf && ldconfig

ENV PATH="/opt/hisi-linux/x86-arm/arm-hisiv300-linux/target/bin:/opt/hisi-linux/x86-arm/arm-hisiv300-linux/bin:${PATH}"

WORKDIR /build
COPY Makefile .
COPY scripts/ scripts/
COPY patches/ patches/

# ── Entrypoint: set TC_BIN dynamically then run make ──────────────────────
CMD ["/bin/sh", "-c", \
    "TC_BIN=$(find /opt/hisi-linux -type f -name 'arm-hisiv300-linux-gcc' -exec dirname {} \\; | head -1) && \
     export PATH=$TC_BIN:$PATH && \
     echo \"Using toolchain at: $TC_BIN\" && \
     make all TOOLCHAIN_BIN=$TC_BIN"]
