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

## Build Requirements
* Use the provided Docker environment for consistent library compilation.
* Run `make clean && make` to generate fresh binaries.
* **Post-Deployment:** Manually harden device config files using `chmod 600 /etc/system.conf`.

---
*Maintained by: System Hackers Inc.*
