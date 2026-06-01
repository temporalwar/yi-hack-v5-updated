# yi-hack-v5-updated

A security-hardened fork of [alienatedsec/yi-hack-v5](https://github.com/alienatedsec/yi-hack-v5) for the *Yi Home 1080p* camera (Hi3518ev200 chipset). This fork focuses on two things: fixing shell-level bugs in the original firmware scripts, and replacing end-of-life or outdated bundled binaries with newer, patched versions that still cross-compile cleanly for the camera's ARMv5te / uClibc target.

Releases are built automatically via GitHub Actions and published as ready-to-deploy tarballs.

---

## Key Features

* **RTSP Server** — stream video locally to an NVR, Home Assistant, Agent DVR, or VLC.
* **SSH Server** — root command-line access to the camera's Linux OS (Dropbear).
* **Web Interface** — manage settings, view the stream and logs from a browser.
* **FTP Server** — access and download recordings from the MicroSD card.
* **Cloud Bypass** — run the camera fully locally, no official app or external servers.
* **ONVIF / WS-Discovery** — integrate with ONVIF-compatible NVRs and UniFi Protect.

---

## Download

**[→ Latest Releases](https://github.com/Temporalwar/yi-hack-v5-updated/releases)**

Download **`yi-hack-v5-updated.tar.gz`** from the `latest` release assets. This rolling release is rebuilt and republished automatically on every push to `master`.

---

## Updated Packages

All bundled binaries are cross-compiled for `arm-hisiv300-linux` (ARMv5te, uClibc). Versions are chosen as the **newest release that builds reliably** for this toolchain.

| Package | Updated to | Why this version |
| :--- | :--- | :--- |
| **OpenSSL** | **3.3.7** | Replaces EOL 1.1.x. Patches CVE-2025-9230, CVE-2025-9231 (fixed in 3.3.5), CVE-2025-15467, CVE-2025-69421 (3.3.6), and CVE-2026-28387, CVE-2026-28388, CVE-2026-28389, CVE-2026-28390, CVE-2026-31790 (3.3.7). |
| **curl** | **8.20.0** | Replaces an old development snapshot; current stable with years of upstream security fixes. |
| **dropbear** | **2025.89** | Replaces the 2018-era build. Patches CVE-2025-14282 — in multi-user mode the SSH server performed socket forwardings as root before dropping to the logged-in user (fixed in 2025.88). |
| **cJSON** | **1.7.18** | Lightweight JSON library used by the firmware tooling. |
| **mosquitto** | **1.6.15** | Pinned to the **pure-C 1.6.x line**. Mosquitto 2.x failed to link against uClibc and has a heavier footprint; 1.6.15 links cleanly with `WITH_MEMORY_TRACKING=no` and keeps memory use low on the camera. |
| **pure-ftpd** | **1.0.54** | Current stable; multiple hardening fixes over the original bundled build. |
| **libfuse3** | **3.16.2** | Highest libfuse that builds with the Meson 0.51.x-era toolchain in the build image; libfuse 3.18.x requires a newer Meson than this cross-environment supports. |

> CVE references verified against the MITRE CVE database; each listed CVE is fixed in the pinned version or earlier. The project originally targeted Mosquitto 2.x and a newer libfuse, but those versions do not cross-compile cleanly for ARMv5te/uClibc with the current toolchain — the pinned versions above are the modern, working compromise.

---
## What's Fixed

Shell and CGI bug fixes carried in this fork (see the [v1.1.0 release notes](https://github.com/Temporalwar/yi-hack-v5-updated/releases/tag/v1.1.0) for the full changelog):

* **Cron overwrite bugs** — several scripts used `>` (overwrite) instead of `>>` when writing crontab entries, so only the last entry survived. Fixed in `system.sh` and `mqtt_advertise/startup.sh`.
* **RTSP watchdog** — `wd_rtsp.sh` used the wrong port variable, so locked-stream recovery never triggered. Fixed.
* **ONVIF startup** — corrected boot ordering and binary placement so ONVIF and WS-Discovery start reliably on fresh installs; `onvif_simple_server` is detached with `setsid` to stop crash loops.
* **Web UI persistence** — `camera_settings.sh` now writes toggles (LED, IR, sensitivity, rotation, etc.) back to `camera.conf`, and adds missing handlers for motion and AI-human detection.
* **CGI guards** — fixed broken variable assignments (`DIR = "none"` → `DIR="none"`) in the event-deletion scripts.
* **MQTT Home Assistant** — fixed an undefined config variable, a wrong QOS key, and a `grep` anchoring bug that broke config matching.
* **`check_conf.sh`** — aligned the `ONVIF_WSDD` default to `no` to match `system.conf`.

### Default config templates

`etc/camera.conf` ships with the AI/detection keys present and enabled (`MOTION_DETECTION`, `AI_HUMAN_DETECTION`, `AI_VEHICLE_DETECTION`, `AI_ANIMAL_DETECTION`, `FACE_DETECTION`, `MOTION_TRACKING`, `CRUISE`).

---

## Deploy to Camera

1. Set up your MicroSD card (FAT32) with the base `yi-hack-v5` files per the upstream installation instructions.
2. Download **`yi-hack-v5-updated.tar.gz`** from the [Latest Releases](https://github.com/Temporalwar/yi-hack-v5-updated/releases).
3. Extract it over your existing `yi-hack-v5` SD-card folder:
   ```bash
   tar -xzf yi-hack-v5-updated.tar.gz -C /path/to/sdcard/
   ```
4. Insert the card and power on the camera. Do not remove power until it fully reboots.
5. (Recommended) Harden permissions on your config files after first boot:
   ```bash
   chmod 600 /tmp/sd/yi-hack-v5/etc/system.conf
   chmod 600 /tmp/sd/yi-hack-v5/etc/camera.conf
   ```

---

## Build It Yourself

Builds run automatically on every push via GitHub Actions. The published artifact is `yi-hack-v5-updated.tar.gz`. To build locally you need the `arm-hisiv300-linux` toolchain.

### Docker (recommended)

```bash
docker build -t yi-hack-builder .
docker run --rm -v "$PWD/output:/build/output" yi-hack-builder
```

The cross-compiled binaries land in `./output/`.

---

## UniFi Protect Integration

ONVIF and WS-Discovery are functional. WS-Discovery uses multicast, which does not cross subnet boundaries — if the camera is on a different subnet, add it manually in UniFi Protect using its IP address, port `8080`, username `admin`.

---

## Credits

Based on the work of [alienatedsec/yi-hack-v5](https://github.com/alienatedsec/yi-hack-v5) and the wider yi-hack community.
