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

Eleven bugs found and fixed in the original firmware scripts:

| File | Bug | Fix |
| --- | --- | --- |
| `script/clean_records.sh` | `continue` used outside a loop — script never cleaned records | Changed to `;;` |
| `script/system.sh` | Cron entries used `>` (overwrite) — if both `CRONTAB` and `FREE_SPACE` were set, the second entry silently overwrote the first | Changed both to `>>` |
| `script/system.sh` | No code to restore camera on/off state from `camera.conf` on boot — camera stuck permanently off after any restart if toggled off via web UI | Added boot-time restore block using `ipc_cmd -t on/off` with 15s delay for `dispatch`/`rmm` init |
| `script/mqtt_advertise/startup.sh` | All 5 cron entries used `>` (overwrite) — only the last one survived | Changed all to `>>` |
| `www/cgi-bin/camera_settings.sh` | `CONF_FILE` defined but never written to — toggling camera on/off, LED, IR, sensitivity, rotation etc. via web UI was never persisted to `camera.conf`, so all settings reset on reboot | Added `sed -i` write to `camera.conf` for every setting |
| `www/cgi-bin/eventsdirdel.sh` | `DIR = "none"` (spaces) — variable never set, path traversal guard broken | Fixed to `DIR="none"` |
| `www/cgi-bin/eventsfiledel.sh` | Same `FILE = "none"` bug as above | Fixed to `FILE="none"` |
| `script/mqtt_advertise/mqtt_adv_homeassistant.sh` | `CONF_SYSTEM_FILE` undefined — all `get_system_config` calls silently failed | Added missing variable |
| `script/mqtt_advertise/mqtt_adv_homeassistant.sh` | `MQTT_ADV_TELEMETRY_QOS` read from `RETAIN` key — QOS always wrong | Fixed key name |
| `script/check_conf.sh` | `ONVIF_WSDD` default was `yes`, `system.conf` ships it as `no` — enabled on first boot without user consent | Aligned default to `no` |
| `script/mqtt_advertise/check_conf.sh` | `grep $PAR` without `^` anchor — partial key matches prevented config entries being added | Fixed to `grep ^$PAR=` |

### Default config fixes

| File | Bug | Fix |
| --- | --- | --- |
| `etc/system.conf` | `CAMERA_ENABLED` key missing from default template — startup scripts had no persistent camera state to read | Added `CAMERA_ENABLED=yes` |
| `etc/camera.conf` | Several keys missing from template (`MOTION_DETECTION`, `AI_HUMAN_DETECTION`, `AI_VEHICLE_DETECTION`, `AI_ANIMAL_DETECTION`, `FACE_DETECTION`, `MOTION_TRACKING`, `CRUISE`) — web UI could write keys that `system.sh` could never restore | Added all missing keys with safe defaults |

### Updated packages

All bundled binaries replaced with current, patched versions cross-compiled for `arm-hisiv300-linux` (`ARMv5te`, `uClibc 0.9.33.2`):

| Package | Original | Updated | Key reason |
| --- | --- | --- | --- |
| OpenSSL | 1.1.x (**EOL**) | **3.3.7** | End-of-life Sep 2023; 3.3.7 fixes CVE-2026-31790, CVE-2026-28387, CVE-2026-28388, CVE-2026-28389, CVE-2026-28390 |
| curl | 7.86.0-DEV | **8.20.0** | ~3 years of security fixes, dev snapshot replaced |
| dropbear | 2018.76 | **2026.91** | CVE-2025-14282, CVE-2026-35385, privilege dropping fixes, 8 years of accumulated patches |
| mosquitto | 1.5.8 | **2.1.2** | Major version bump, hardened packet handling, bugfix releases |
| pure-ftpd | 1.0.47 | **1.0.54** | Out-of-bounds read fix in MLSD command, 7 patch releases |
| libfuse3 | 3.4.2 | **3.18.2** | 14 minor versions of fixes |
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
chmod 600 /tmp/sd/yi-hack-v5/etc/camera.conf
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
* **dropbear 2026.91**: `DROPBEAR_SVR_DROP_PRIVS` disabled via `localoptions.h` — `setresgid()` unavailable in uClibc. CVE-2025-14282 and CVE-2026-35385 are still mitigated as yi-hack-v5 does not use unix stream forwarding
* **libfuse3**: Built without `utils` and `useroot` to avoid host-only `mount.fuse3` dependency
* **curl**: Built as a static binary — only the `curl` binary is needed by the firmware scripts
* **camera on/off restore**: The `ipc_cmd -t on/off` call at boot is delayed 15 seconds to allow `dispatch` and `rmm` to fully initialise before accepting commands. Do not reduce this delay on constrained hardware.

---

## Credits

Based on the work of [alienatedsec](https://github.com/alienatedsec/yi-hack-v5) and [roleoroleo](https://github.com/roleoroleo).
