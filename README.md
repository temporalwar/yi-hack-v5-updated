# yi-hack-v5 Package Update Build System

Cross-compiles updated versions of all security-sensitive binaries for the
**Yi Home 1080p** camera running yi-hack-v5 on the **Hi3518ev200** SoC.

## What gets built

| Package    | Old version  | New version | Key reason                          |
|------------|-------------|-------------|-------------------------------------|
| OpenSSL    | 1.1.x (EOL) | 3.3.2       | EOL since Sep 2023, many CVEs       |
| curl       | 7.86.0-DEV  | 8.20.0      | ~3 years of security fixes          |
| dropbear   | 2018.76     | 2025.89     | CVE-2025-14282 + 7 years of patches |
| mosquitto  | 1.5.8       | 2.1.0       | Major version, security fixes       |
| pure-ftpd  | 1.0.47      | 1.0.52      | 5 patch releases                    |
| libfuse3   | 3.4.2       | 3.18.1      | 14 minor versions                   |

## Requirements

- **Linux x86_64 host** (Ubuntu 22.04 LTS recommended)
- **arm-hisiv300-linux toolchain** (GCC 4.8.3/Linaro, uClibc 0.9.33.2)
- `make`, `cmake`, `meson`, `ninja`, `wget`

## Step 1 — Install the toolchain

```bash
mkdir -p /opt/hisi-linux/x86-arm
cd /opt/hisi-linux/x86-arm
curl -fL https://github.com/OpenIPC/toolchains/releases/download/v1/arm-hisiv300-linux.tar.bz2 \
     -o arm-hisiv300-linux.tar.bz2
tar -xjf arm-hisiv300-linux.tar.bz2
rm arm-hisiv300-linux.tar.bz2
```

Verify it works:
```bash
/opt/hisi-linux/x86-arm/arm-hisiv300-linux/target/bin/arm-hisiv300-linux-uclibcgnueabi-gcc --version
# arm-hisiv300-linux-uclibcgnueabi-gcc (Hisilicon_v300) 4.8.3 ...
```

## Step 2 — Install host build tools

```bash
sudo apt update
sudo apt install build-essential cmake ninja-build wget bzip2
pip3 install meson==1.3.2
```

## Step 3 — Build everything

```bash
chmod +x build.sh
./build.sh          # builds all packages
```

Or build individually (OpenSSL must be first):
```bash
./build.sh openssl
./build.sh curl
./build.sh dropbear
./build.sh mosquitto
./build.sh pureftpd
./build.sh libfuse
```

The full build takes roughly **10–20 minutes** on a modern machine.

## Step 4 — Deploy to camera

The build produces `yi-hack-v5-updated-packages.tgz` in the project root.
Extract it over your existing firmware package:

```bash
# Merge into the existing yi_home_1080p_0_4_1_fixed.tgz
mkdir -p /tmp/merge/yi_home_1080p
tar -xzf yi_home_1080p_0_4_1_fixed.tgz -C /tmp/merge
tar -xzf yi-hack-v5-updated-packages.tgz -C /tmp/merge/yi_home_1080p
tar -czf yi_home_1080p_0_4_1_updated.tgz -C /tmp/merge yi_home_1080p/
```

Then flash `yi_home_1080p_0_4_1_updated.tgz` to the SD card as normal.

## Alternative: Docker

If you prefer a fully isolated build:

```bash
docker build -t yi-hack-builder .
docker run --rm -v "$PWD/output:/build/output" yi-hack-builder
```

The Docker image downloads and installs the toolchain automatically.

## Notes on uClibc compatibility

- **OpenSSL 3.x**: Tested against uClibc 0.9.33.2. The `no-async` flag is
  required (uClibc lacks `getcontext`/`makecontext`).
- **dropbear 2025.89**: `DROPBEAR_SVR_DROP_PRIVS` is disabled via
  `localoptions.h` because `setresgid()` is unavailable in uClibc 0.9.33.2.
  CVE-2025-14282 is mitigated separately — unix stream forwarding is not used
  by yi-hack-v5, so this is safe.
- **libfuse3**: Built without `utils` and `useroot` options to avoid
  `mount.fuse3` dependency on host-only tools.
- **curl**: Built as a static binary (no shared libcurl) to keep deployment
  simple — only the `curl` binary itself is needed by the scripts.
