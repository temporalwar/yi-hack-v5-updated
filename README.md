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
To maintain transparency and system integrity, we have resolved the following 7 critical logic bugs:

1. **Missing Configuration Variable:** Defined `CONF_SYSTEM_FILE` in `mqtt_adv_homeassistant.sh` to prevent script crashes when fetching system settings.
2. **MQTT Telemetry QOS Fix:** Corrected a copy-paste error where `MQTT_ADV_TELEMETRY_QOS` was incorrectly fetching from the `RETAIN` configuration key.
3. **JSON Syntax Error:** Fixed a broken quote in the Home Assistant "Uptime" sensor template, ensuring valid JSON output.
4. **Cron Persistence Fix:** Updated `startup.sh` to use `>>` (append) instead of `>` (overwrite) when writing to `/etc/crontabs/root`, preventing multiple MQTT features from nullifying each other.
5. **ONVIF WSDD Default:** Changed the default `ONVIF_WSDD` value in `check_conf.sh` from "yes" to "no" to prevent unauthorized service discovery.
6. **Grep Anchoring:** Updated `check_conf.sh` to use `^$PAR=` grep anchoring, preventing false positive configuration matches.
7. **CGI Path Traversal Protection:** Corrected variable assignment syntax (removed stray spaces, e.g., `DIR="none"`) in CGI scripts to ensure path traversal security checks function as intended.

## Downloads
**[Download the latest hardened firmware (firmware.tgz)](https://github.com/Temporalwar/yi-hack-v5-updated/releases/latest)**

## Deployment & Build
1. **Deployment:** Extract `firmware.tgz` to the root of your SD card. After booting, run `chmod 600 /tmp/sd/yi-hack-v5/etc/system.conf` to secure credentials.
2. **Build:** Use the provided Docker environment: `make clean && make`.

---
*Maintained by: System Hackers Inc.*
