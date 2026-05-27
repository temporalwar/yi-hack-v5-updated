# Yi-Hack-V5 Updated (Hardened Security Build)

This repository provides a modernized and secure build for `yi-hack-v5` firmware, specifically targeted for the `Hi3518ev200` chipset. This project focuses on vulnerability patching, logic error correction, and overall system hardening.

## Security Improvements
This build replaces legacy binaries with modern, patched versions to mitigate high-severity CVEs:
* **SSH/SSHd:** Dropbear 2025.89 (Patched CVE-2025-14282)
* **TLS/Crypto:** OpenSSL 3.3.2 (Mitigated DoS/Buffer over-read vulnerabilities)
* **MQTT:** Mosquitto 2.1.0 (Hardened packet handling)
* **Filesystem:** libfuse 3.18.2 (Patched CVE-2026-33150)
* **Connectivity:** Curl 8.20.0 (General security consolidation)

## Detailed Bug Fix Log
We have resolved the following 7 critical logic bugs to stabilize the environment:
1. **Missing Config Variable:** Defined `CONF_SYSTEM_FILE` in `mqtt_adv_homeassistant.sh`.
2. **MQTT Telemetry QOS Fix:** Corrected `MQTT_ADV_TELEMETRY_QOS` key mapping.
3. **JSON Syntax:** Fixed broken quote in the Home Assistant "Uptime" template.
4. **Cron Persistence:** Changed `>` to `>>` in `startup.sh` to prevent overwriting.
5. **ONVIF WSDD Default:** Aligned to "no" in `check_conf.sh` for security.
6. **Grep Anchoring:** Updated to `^$PAR=` in `check_conf.sh` to prevent false positives.
7. **CGI Path Traversal:** Fixed syntax in CGI scripts (`DIR="none"`) to ensure security guards work.

## Build System
This project uses a containerized build environment to ensure library compatibility.
1. **Prerequisites:** Ensure Docker is installed on your machine.
2. **Build:** Run `make clean && make` in the root directory.
3. **Output:** The compiled firmware binaries will be placed in the `/staging` directory.

## Downloads
Official, pre-compiled firmware packages are published via GitHub Releases.
**[Download the latest hardened firmware (firmware.tgz)](https://github.com/Temporalwar/yi-hack-v5-updated/releases/latest)**

---
*Maintained by: System Hackers Inc.*
