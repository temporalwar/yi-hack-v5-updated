# yi-hack-v5-updated

A security-hardened fork of [alienatedsec/yi-hack-v5](https://github.com/alienatedsec/yi-hack-v5) for the *Yi Home 1080p* camera (Hi3518ev200 chipset). This fork focuses on two things: fixing critical shell-level bugs found in the original firmware scripts, and replacing end-of-life or severely outdated bundled binaries with modern, patched versions.

Releases are built automatically via GitHub Actions and published as ready-to-deploy tarballs.

---

## ✨ Key Features

* **RTSP Server:** Stream high-quality video locally directly to an NVR, Home Assistant, Agent DVR, or VLC.
* **SSH Server:** Get root command-line access to the camera's underlying Linux OS.
* **Web Interface:** Manage camera settings, monitor the stream, view logs, and manage the system from a clean web UI.
* **FTP/TFTP Server:** Easily access, manage, and download recorded videos saved to the local MicroSD card.
* **Cloud Bypass:** Run the camera entirely locally without needing to connect to the official app or external servers.

---

## Download

**[→ Latest Releases](https://github.com/Temporalwar/yi-hack-v5-updated/releases)**

Download `yi-hack-v5-updated-packages.tgz` from the latest release assets.

---

## 🚀 What's New in v1.2.0

* **ONVIF Server Crash Loop Fix (Critical):** Wrapped `onvif_simple_server` in `setsid` to safely detach it from the controlling terminal, preventing segfaults and exit code 1 errors when backgrounded from `init`.
* **ONVIF Event Pipeline Fix:** Corrected boot ordering so `ipc2file`, `onvif_notify_server`, and `wsd_simple_server` all start before `onvif_simple_server` blocks. Motion events now work reliably on boot.
* **Full ONVIF Event Suite:** Fixed `events=3` → `events=6` so all 6 detection events are registered: Motion, People, Vehicles, Animals, Baby Crying, and General Sound.
* **RTSP Network Buffer Tuning:** Injected `sysctl` commands to increase network buffers (`rmem_max`, `wmem_max`), resulting in smoother, stutter-free high-resolution RTSP streams.
* **Dynamic Multi-WiFi Support:** Added `WIFI_MULTI=yes` functionality to bypass single-network restrictions and read a custom `wpa_supplicant.conf` from the SD card.
* **Persistent Camera State Memory:** Camera now intelligently restores its software on/off state after a reboot by reading `camera.conf` at boot.
* **cloudAPI Always Updated:** Replaced fragile version-comparison logic with a direct `cp -f` so `cloudAPI` and `cloudAPI_fake` are always pushed to flash on boot.
* **MQTT Conditional Start:** MQTT daemon now only starts if explicitly enabled in config, saving memory and CPU for users who don't use smart home integrations.
* **Crontab Overwrite Bug Fix:** Corrected `>` → `>>` in `system.sh` to stop cron jobs silently wiping out existing scheduled tasks.
* **Package Updates:** Mosquitto upgraded to 2.1.2 with overhauled CMake build flags and GTest patch; libfuse upgraded to 3.18.1; OpenSSL upgraded to 3.3.7.
* **All AI Detection On By Default:** `camera.conf` now ships with all AI detection features enabled (`MOTION_DETECTION`, `AI_HUMAN_DETECTION`, `AI_VEHICLE_DETECTION`, `AI_ANIMAL_DETECTION`, `FACE_DETECTION`, `MOTION_TRACKING`, `CRUISE`).

---

## 🛡️ Updated Packages

All bundled binaries replaced with current, patched versions cross-compiled for `arm-hisiv300-linux` (ARMv5te, uClibc 0.9.33.2):

| Package | Original | Updated | Key reason |
| :--- | :--- | :--- | :--- |
| **OpenSSL** | 1.1.x (*EOL*) | **3.3.7** | End-of-life Sep 2023; fixes CVE-2025-9230, CVE-2025-9231, CVE-2025-15467, CVE-2025-69421, CVE-2026-28387, CVE-2026-28388, CVE-2026-28389, CVE-2026-28390, CVE-2026-31790 |
| **curl** | 7.86.0-DEV | **8.20.0** | ~3 years of critical upstream security patches; development snapshot replaced |
| **dropbear** | 2018.76 | **2025.89** | Fixes CVE-2025-14282 (privilege escalation via unix stream forwarding); 7 years of accumulated security fixes |
| **mosquitto** | 1.5.8 | **2.1.2** | Major version bump, hardened network packet handling, memory leak fixes |
| **pure-ftpd** | 1.0.47 | **1.0.54** | Multiple hardening fixes across PureDB, IP access checker, PAM, and quota handling |
| **libfuse3** | 3.4.2 | **3.18.1** | 14 minor versions of cumulative bug fixes and performance stabilization |
| **cJSON** | — | **1.7.18** | New core dependency required to support modern Mosquitto 2.x builds |

---

## 🐛 What's Fixed

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
| `etc/camera.conf` | Several keys missing from template (`MOTION_DETECTION`, `AI_HUMAN_DETECTION`, `AI_VEHICLE_DETECTION`, `AI_ANIMAL_DETECTION`, `FACE_DETECTION`, `MOTION_TRACKING`, `CRUISE`) — web UI could write keys that `system.sh` could never restore | Added all missing keys set to `yes` |

---

## 💾 Deploy to Camera

1. Follow the standard `yi-hack-v5` installation instructions using the base files from upstream releases to format and set up your MicroSD card (FAT32).
2. Download `yi-hack-v5-updated-packages.tgz` from the [Latest Releases](https://github.com/Temporalwar/yi-hack-v5-updated/releases).
3. Extract the downloaded package directly over your existing `yi-hack-v5` SD card folder:
   ```bash
   tar -xzf yi-hack-v5-updated-packages.tgz -C /path/to/sdcard/
   ```
4. Insert the MicroSD card into your camera and power it on. The yellow light will blink during the flashing process. Do not disconnect power until the camera fully reboots and the light stabilizes.
5. After boot, harden your config file permissions:
   ```bash
   chmod 600 /tmp/sd/yi-hack-v5/etc/system.conf
   chmod 600 /tmp/sd/yi-hack-v5/etc/mqttv4.conf
   chmod 600 /tmp/sd/yi-hack-v5/etc/camera.conf
   ```

---

## 🛠️ Build It Yourself

Builds run automatically on every push via GitHub Actions. To build locally you need the `arm-hisiv300-linux` toolchain.

### Option A — Docker (recommended)

```bash
docker build -t yi-hack-builder .
docker run --rm -v "$PWD/output:/build/output" yi-hack-builder
```

### Option B — Native Linux build

```bash
# Install toolchain
mkdir -p /opt/hisi-linux/x86-arm && cd /opt/hisi-linux/x86-arm
curl -fL https://github.com/OpenIPC/toolchains/releases/download/v1/arm-hisiv300-linux.tar.bz2 \
     -o arm-hisiv300-linux.tar.bz2
tar -xjf arm-hisiv300-linux.tar.bz2 && rm arm-hisiv300-linux.tar.bz2

# Install host build tools
sudo apt update && sudo apt install build-essential ninja-build wget bzip2
pip3 install meson==0.51.1

# Build
chmod +x build.sh && ./build.sh
```

---

## UniFi Protect Integration

ONVIF and WS-Discovery are functional. Auto-discovery will not work if your camera is on a different VLAN or subnet than your UniFi controller — WS-Discovery uses multicast which does not cross subnet boundaries.

To add the camera manually in UniFi Protect:
- **IP:** your camera's IP address (check your router's DHCP table)
- **Port:** `8080`
- **Username:** `admin`

---

## Credits

Based on the work of [alienatedsec](https://github.com/alienatedsec/yi-hack-v5) and [roleoroleo](https://github.com/roleoroleo).
