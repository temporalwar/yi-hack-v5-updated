# yi-hack-v5-updated

A security-hardened fork of [alienatedsec/yi-hack-v5](https://github.com/alienatedsec/yi-hack-v5) for the *Yi Home 1080p* camera (Hi3518ev200 chipset). This fork focuses on two things: fixing critical shell-level bugs found in the original firmware scripts, and replacing end-of-life or severely outdated bundled binaries with modern, patched versions.

Releases are built automatically via GitHub Actions and published as ready-to-deploy tarballs.

## Download

[→ Latest Releases](https://github.com/Temporalwar/yi-hack-v5-updated/releases)  
Download `yi-hack-v5-updated-packages.tgz` from the latest release assets.

---

## What's Fixed

### Shell & CGI Bug Fixes
Thirteen bugs found and fixed in the original firmware scripts:

| File | Bug | Fix |
| :--- | :--- | :--- |
| `script/clean_records.sh` | `continue` used outside a loop — script never cleaned records | Changed to `;;` |
| `script/system.sh` | Cron entries used `>` (overwrite) — if both `CRONTAB` and `FREE_SPACE` were set, the second entry silently overwrote the first | Changed both to `>>` |
| `script/system.sh` | No code to restore camera on/off state from `camera.conf` on boot — camera stuck permanently off after any restart if toggled off via web UI | Added boot-time restore block using `ipc_cmd -t on/off` with 15s delay for dispatch / rmm init |
| `script/system.sh` | `onvif_simple_server` binary located in `www/onvif/` but called bare by `system.sh` — ONVIF never started on fresh installs because the binary was not on PATH | Added auto-copy to `bin/` before the ONVIF block runs |
| `script/wd_rtsp.sh` | `$RTSP_PORT` used in `check_rtsp` socket check instead of `$RRTSP_PORT` — locked-process detection never worked, RTSP stream never recovered from a locked state | Fixed to `$RRTSP_PORT` |
| `script/mqtt_advertise/startup.sh` | All 5 cron entries used `>` (overwrite) — only the last one survived | Changed all to `>>` |
| `www/cgi-bin/camera_settings.sh` | `CONF_FILE` defined but never written to — toggling camera on/off, LED, IR, sensitivity, rotation etc. via web UI was never persisted to `camera.conf`, so all settings reset on reboot | Added `sed -i` write to `camera.conf` for every setting |
| `www/cgi-bin/camera_settings.sh` | `motion_detection` and `ai_human_detection` had no CGI handlers — these settings could not be toggled from the web UI despite being ONVIF event sources | Added handlers using `ipc_cmd -O` and `ipc_cmd -a` |
| `www/cgi-bin/eventsdirdel.sh` | `DIR = "none"` (spaces) — variable never set, path traversal guard broken | Fixed to `DIR="none"` |
| `www/cgi-bin/eventsfiledel.sh` | Same `FILE = "none"` bug as above | Fixed to `FILE="none"` |
| `script/mqtt_advertise/mqtt_adv_homeassistant.sh` | `CONF_SYSTEM_FILE` undefined — all `get_system_config` calls silently failed | Added missing variable |
| `script/mqtt_advertise/mqtt_adv_homeassistant.sh` | `MQTT_ADV_TELEMETRY_QOS` read from `RETAIN` key — QOS always wrong | Fixed key name |
| `script/check_conf.sh` | `ONVIF_WSDD` default was `yes`, `system.conf` ships it as `no` — enabled on first boot without user consent | Aligned default to `no` |
| `script/mqtt_advertise/check_conf.sh` | `grep $PAR` without `^` anchor — partial key matches prevented config entries being added | Fixed to `grep ^$PAR=` |

### Default Config Fixes

| File | Bug | Fix |
| :--- | :--- | :--- |
| `etc/system.conf` | `CAMERA_ENABLED` key missing from default template — startup scripts had no persistent camera state to read | Added `CAMERA_ENABLED=yes` |
| `etc/camera.conf` | Several keys missing from template (`MOTION_DETECTION`, `AI_HUMAN_DETECTION`, `AI_VEHICLE_DETECTION`, `AI_ANIMAL_DETECTION`, `FACE_DETECTION`, `MOTION_TRACKING`, `CRUISE`) — web UI could write keys that `system.sh` could never restore | Added all missing keys with safe defaults |

---

## Updated Packages

All bundled binaries replaced with current, patched versions cross-compiled for `arm-hisiv300-linux` (ARMv5te, uClibc 0.9.33.2):

| Package | Original | Updated | Key reason |
| :--- | :--- | :--- | :--- |
| **OpenSSL** | 1.1.x (*EOL*) | **3.3.7** | End-of-life Sep 2023; 3.3.7 fixes CVE-2026-31790, CVE-2026-28387, CVE-2026-28388, CVE-2026-28389, CVE-2026-28390 |
| **curl** | 7.86.0-DEV | **8.20.0** | ~3 years of critical upstream security patches; development snapshot replaced |
| **dropbear** | 2018.76 | **2026.91** | Fixes CVE-2025-14282, CVE-2026-35385, plus 8 years of accumulated privilege dropping and protocol fixes |
| **mosquitto** | 1.5.8 | **2.1.2** | Major version bump, hardened network packet handling, memory leak fixes |
| **pure-ftpd** | 1.0.47 | **1.0.54** | Fixes Out-of-bounds read vulnerability in the MLSD command processing |
| **libfuse3** | 3.4.2 | **3.18.2** | 14 minor versions of cumulative bug fixes and performance stabilization |
| **cJSON** | — | **1.7.18** | New core dependency required to support modern Mosquitto 2.x builds |

---

## Deploy to Camera

1. Follow the standard `yi-hack-v5` installation instructions using the base files from upstream releases.
2. Download `yi-hack-v5-updated-packages.tgz` from the [Latest Releases](https://github.com/Temporalwar/yi-hack-v5-updated/releases).
3. Extract the downloaded package directly over your existing `yi-hack-v5` SD card folder. This will safely overwrite old scripts and seamlessly update your binary environments:
   ```bash
   tar -xzf yi-hack-v5-updated-packages.tgz -C /path/to/sdcard/
