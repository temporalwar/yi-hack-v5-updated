# Yi-Hack-V5 Updated (Modernized Security Stack)

This repository contains a modernized build infrastructure for `yi-hack-v5`, focused on hardening the security stack for embedded IoT camera systems (Hi3518ev200 chipset).

## Security Modernization
This fork addresses critical vulnerabilities and logic flaws found in legacy firmware implementations by updating the core components:

* **SSH/SSHd:** Dropbear 2025.89 (Patched CVE-2025-14282)
* **TLS/Crypto:** OpenSSL 3.3.2 (Patched multiple DoS/Buffer Over-read CVEs)
* **MQTT:** Mosquitto 2.1.0 (Hardened against DoS attacks)
* **Filesystem:** libfuse 3.18.2 (Patched CVE-2026-33150)
* **Connectivity:** Curl 8.20.0 (Consolidated security patches)

## Key Bug Fixes
* **Shell Scripting:** Resolved path traversal risks, cron overwriting bugs, and incorrect shell variable assignments.
* **Home Assistant Integration:** Fixed critical logic errors in MQTT advertisement, including missing `CONF_SYSTEM_FILE` and copy-paste errors in QOS settings.
* **Integrity:** Tightened configuration file access controls and grep anchoring.

## Build Instructions
Ensure you are using the provided Docker environment to ensure library compatibility:

1. Clone the repository:
   ```bash
   git clone [https://github.com/Temporalwar/yi-hack-v5-updated.git](https://github.com/Temporalwar/yi-hack-v5-updated.git)
   cd yi-hack-v5-updated
