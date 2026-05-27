# Yi-Hack-V5 Updated (Hardened Security Build)

This repository provides a modernized and secure build for `yi-hack-v5` firmware, specifically targeted for the `Hi3518ev200` chipset. This project focuses on vulnerability patching, logic error correction, and overall system hardening.

## Security Improvements
This build replaces legacy binaries with modern, patched versions to mitigate high-severity CVEs:

* **SSH/SSHd:** Dropbear 2025.89 (Patched CVE-2025-14282)
* **TLS/Crypto:** OpenSSL 3.3.2 (Mitigated DoS/Buffer over-read vulnerabilities)
* **MQTT:** Mosquitto 2.1.0 (Hardened packet handling)
* **Filesystem:** libfuse 3.18.2 (Patched CVE-2026-33150)
* **Connectivity:** Curl 8.20.0 (General security consolidation)

## Critical Bug Fixes
The shell environment has been stabilized and secured:

* **Logic & Stability:** Fixed shell loop errors in `clean_records.sh` and corrected cron redirection (using `>>` instead of `>`) in `startup.sh`.
* **Path Traversal Security:** Fixed whitespace errors in CGI variable assignments (`DIR="none"`), restoring path traversal protection.
* **Configuration Hardening:** Secured `grep` anchoring in configuration checks and aligned default service values (`ONVIF_WSDD=no`).
* **Home Assistant Integration:** Resolved missing configuration variables (`CONF_SYSTEM_FILE`), corrected telemetry QOS keys, and fixed JSON syntax for sensor templates.

## Downloads
The compiled, ready-to-use firmware binaries are provided via GitHub Releases. These binaries include all hardened components packaged for direct deployment.

**[Download the latest hardened firmware (firmware.tgz)](https://github.com/Temporalwar/yi-hack-v5-updated/releases/latest)**

## Deployment Instructions
1. Download the `firmware.tgz` file from the [Releases page](https://github.com/Temporalwar/yi-hack-v5-updated/releases/latest).
2. Extract the contents directly to the root of your camera's SD card.
3. Insert the SD card into the camera and power it on.
4. Once booted, SSH into the camera and harden your configuration files:
```bash
   chmod 600 /tmp/sd/yi-hack-v5/etc/system.conf
   chmod 600 /tmp/sd/yi-hack-v5/etc/mqttv4.conf
