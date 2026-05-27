Here is the merged text. I cleaned up the duplicated sentence from the first snippet and integrated its instructions logically into the "Deploy to camera" section of the main document so the steps flow naturally.

---

# yi-hack-v5-updated

A security-hardened fork of [alienatedsec/yi-hack-v5](https://github.com/alienatedsec/yi-hack-v5) for the **Yi Home 1080p** camera (`Hi3518ev200` chipset). This fork focuses on two things: fixing shell-level bugs in the original firmware scripts, and replacing critically outdated bundled binaries with modern, patched versions.

Releases are built automatically via GitHub Actions and published as ready-to-deploy tarballs.

---

## Download

**[→ Latest release](https://github.com/Temporalwar/yi-hack-v5-updated/releases/latest)**

Download `yi-hack-v5-updated-packages.tgz` from the release assets.

---

## What's fixed

### Shell & CGI bug fixes

Seven bugs found and fixed in the original firmware scripts:

| File | Bug | Fix |
| --- | --- | --- |
| `script/clean_records.sh` | `continue` used outside a loop — script never cleaned records | Changed to `;;` |
| `script/mqtt_advertise/startup.sh` | All 5 cron entries used `>` (overwrite) — only the last one survived | Changed all to `>>` |
| `www/cgi-bin/eventsdirdel.sh` | `DIR = "none"` (spaces) — variable never set, path traversal guard broken | Fixed to `DIR="none"` |
| `www/cgi-bin/eventsfiledel.sh` | Same `FILE = "none"` bug as above | Fixed to `FILE="none"` |
| `script/mqtt_advertise/mqtt_adv_homeassistant.sh` | `CONF_SYSTEM_FILE` undefined — all `get_system_config` calls silently failed | Added missing variable |
| `script/mqtt_advertise/mqtt_adv_homeassistant.sh` | `MQTT_ADV_TELEMETRY_QOS` read from `RETAIN` key — QOS always wrong | Fixed key name |
| `script/check_conf.sh` | `ONVIF_WSDD` default was `yes`, `system.conf` ships it as `no` — enabled on first boot without user consent | Aligned default to `no` |
| `script/mqtt_advertise/check_conf.sh` | `grep $PAR` without `^` anchor — partial key matches prevented config entries being added | Fixed to `grep ^$PAR=` |

### Updated packages

All bundled binaries replaced with current, patched versions cross-compiled for `arm-hisiv300-linux` (`ARMv5te`, `uClibc 0.9.33.2`):

| Package | Original | Updated | Key reason |
| --- | --- | --- | --- |
| OpenSSL | 1.1.x (**EOL**) | **3.3.2** | End-of-life Sep 2023, no further CVE patches |
| curl | 7.86.0-DEV | **8.20.0** | ~3 years of security fixes, dev snapshot replaced |
| dropbear | 2018.76 | **2025.89** | CVE-2025-14282 + 7 years of accumulated patches |
| mosquitto | 1.5.8 | **2.1.0** | Major version bump, hardened packet handling |
| pure-ftpd | 1.0.47 | **1.0.52** | 5 patch releases |
| libfuse3 | 3.4.2 | **3.18.1** | 14 minor versions of fixes |
| cJSON | — | **1.7.18** | New dependency required by mosquitto 2.x |

---

## Deploy to camera

1. Follow the standard yi-hack-v5 installation using the files from upstream releases.
2. Download `yi-hack-v5-updated-packages.tgz` from the [latest release](https://github.com/Temporalwar/yi-hack-v5-updated/releases/latest).
3. Extract the downloaded package over your existing yi-hack-v5 SD card folder. This will replace the scripts on the SD card with the ones from this fork (specifically the `yi-hack-v5/script/` and `yi-hack-v5/etc/` directories, alongside the updated binaries):

```bash
tar -xzf yi-hack-v5-updated-packages.tgz -C /path/to/sdcard/

```

4. Insert the SD card and reboot the camera.
5. After boot, harden your config file permissions:

```bash
chmod 600 /tmp/sd/yi-hack-v5/etc/system.conf
chmod 600 /tmp/sd/yi-hack-v5/etc/mqttv4.conf

```

---

## Build it yourself

Builds run automatically on every push via GitHub Actions (see `.github/workflows/build.yml`). To build locally you need the `arm-hisiv300-linux` toolchain.

### Option A — Docker (recommended, no toolchain install needed)

```bash
docker build -t yi-hack-builder .
docker run --rm -v "$PWD/output:/build/output" yi-hack-builder

```

### Option B — Native Linux build

**Step 1 — Install the toolchain**

```bash
mkdir -p /opt/hisi-linux/x86-arm && cd /opt/hisi-linux/x86-arm
curl -fL https://github.com/OpenIPC/toolchains/releases/download/v1/arm-hisiv300-linux.tar.bz2 \
     -o arm-hisiv300-linux.tar.bz2
tar -xjf arm-hisiv300-linux.tar.bz2 && rm arm-hisiv300-linux.tar.bz2

```

**Step 2 — Install host build tools**

```bash
sudo apt update && sudo apt install build-essential cmake ninja-build wget bzip2
pip3 install meson==1.3.2

```

**Step 3 — Build**

```bash
chmod +x build.sh && ./build.sh

```

Output: `yi-hack-v5-updated-packages.tgz` in the project root. Build takes ~15–20 minutes.

---

## Compatibility notes

* **OpenSSL 3.x on uClibc**: `no-async` flag required — uClibc 0.9.33.2 lacks `getcontext`/`makecontext`
* **dropbear 2025.89**: `DROPBEAR_SVR_DROP_PRIVS` disabled via `localoptions.h` — `setresgid()` unavailable in uClibc. CVE-2025-14282 is still mitigated as yi-hack-v5 does not use unix stream forwarding
* **libfuse3**: Built without `utils` and `useroot` to avoid host-only `mount.fuse3` dependency
* **curl**: Built as a static binary — only the `curl` binary is needed by the firmware scripts

---

## Credits

Based on the work of [alienatedsec](https://github.com/alienatedsec/yi-hack-v5) and [roleoroleo](https://github.com/roleoroleo).
