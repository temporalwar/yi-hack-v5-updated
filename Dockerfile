FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TOOLCHAIN_DIR=/opt/hisi-linux/x86-arm/arm-hisiv300-linux
ENV CROSS=/opt/hisi-linux/x86-arm/arm-hisiv300-linux/target/bin/arm-hisiv300-linux-uclibcgnueabi-
ENV PATH="${TOOLCHAIN_DIR}/target/bin:${PATH}"
ENV SYSROOT=${TOOLCHAIN_DIR}/target/arm-hisiv300-linux-uclibcgnueabi/sysroot

# ── Build host dependencies ────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl wget ca-certificates git \
    autoconf automake libtool pkg-config \
    cmake ninja-build python3 python3-pip \
    bzip2 xz-utils unzip \
    libssl-dev zlib1g-dev \
    && pip3 install meson==1.3.2 \
    && rm -rf /var/lib/apt/lists/*

# ── Toolchain ──────────────────────────────────────────────────────────────
# Download arm-hisiv300-linux toolchain from OpenIPC (bare .tar.bz2, no wrapper)
RUN mkdir -p ${TOOLCHAIN_DIR} && \
    curl -fL "https://github.com/OpenIPC/toolchains/releases/download/v1/arm-hisiv300-linux.tar.bz2" \
         -o /tmp/tc.tar.bz2 && \
    tar -xjf /tmp/tc.tar.bz2 -C /opt/hisi-linux/x86-arm/ && \
    rm /tmp/tc.tar.bz2

# Symlink so the toolchain's internal absolute paths resolve correctly
RUN mkdir -p /opt/hisi-linux/x86-arm && \
    if [ -d "/opt/hisi-linux/x86-arm/arm-hisiv300-linux" ]; then \
        echo "Toolchain extracted successfully"; \
        ls ${TOOLCHAIN_DIR}/target/bin/ | grep gcc | head -3; \
    fi

WORKDIR /build
COPY Makefile .
COPY scripts/ scripts/
COPY patches/ patches/

CMD ["make", "all"]
