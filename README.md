# Yi-Hack-V5 (Updated)

This project provides a custom firmware "hack" for Yi cameras running on the Hisilicon architecture (specifically `arm-hisiv300-linux`). It allows you to bypass the restrictive cloud ecosystem, take full local control of your hardware, and adds a suite of local-network features.

## 🚀 Recent Updates & Stability Enhancements

**Overhauled the GitHub Actions CI/CD Pipeline & Cross-Compilation Stability**
The build pipeline has been thoroughly modernized and stabilized to ensure seamless cross-compilation of core dependencies (like `libfuse`) for the Hisilicon ARM architecture using modern GitHub Actions runners.

* **Meson Build System Compatibility:** Fixed pipeline crashes occurring on modern host environments (Python 3.12+) by properly isolating cross-compilation environment variables from the native Meson setup phase.
* **Toolchain Environment Isolation:** Stripped native `CC`, `CFLAGS`, and `LDFLAGS` from the `Makefile` environment during setup to resolve `Exec format error` sanity check failures on Intel-based runners.
* **Cross-File Optimization (`hisiv300-meson.txt`):** Restructured the Meson cross-file to properly inject target architecture flags (`-mcpu=arm926ej-s`, `-march=armv5te`, `--sysroot`) via the `[properties]` block for compatibility with Meson 0.51.1. Added a `/bin/true` execution wrapper to safely bypass cross-compiled execution checks.
* **uClibc Header Patching:** Directly injected standard Linux mount flags (`MS_RELATIME`, `MS_STRICTATIME`) into the compiler arguments to support `libfuse` compilation without needing to manually patch the outdated Hisilicon standard library headers.

---

## ✨ Key Features

* **RTSP Server:** Stream high-quality video locally directly to an NVR, Home Assistant, Agent DVR, or VLC.
* **SSH Server:** Get root command-line access to the camera's underlying Linux OS.
* **Web Interface:** Manage camera settings, monitor the stream, view logs, and manage the system from a clean web UI.
* **FTP/TFTP Server:** Easily access, manage, and download recorded videos saved to the local MicroSD card.
* **Cloud Bypass:** Run the camera entirely locally without needing to connect to the official app or external servers.

---

## 💾 Installation Instructions

1. **Format your MicroSD Card:** Ensure your MicroSD card is formatted to `FAT32`.
2. **Download the Release:** Download the latest release `.zip` or `.tar.gz` from the [Releases](../../releases) tab.
3. **Extract:** Extract the contents of the archive directly to the root of your formatted MicroSD card.
4. **Boot:** Insert the MicroSD card into your camera and power it on. The camera will automatically flash the firmware. 
> **Note:** The yellow light will blink during the flashing process. Do not disconnect the power until the camera fully reboots and the light stabilizes.

---

## 🛠️ Building from Source

This project utilizes an automated GitHub Actions pipeline. Every push to the `master` branch triggers the **Build and Release** workflow which automatically provisions the `hisiv300` toolchain, builds all dependencies from scratch, and packages the final artifacts.

If you wish to build manually or modify the toolchain locally:

1. **Prerequisites:** Ensure you have the Hisilicon `arm-hisiv300-linux` toolchain installed and accessible in your path.
2. **Build System:** The project relies on **Meson (specifically v0.51.1)** and `pkg-config`.
3. **Cross-Compilation Quirks:** The target architecture is defined in `scripts/hisiv300-meson.txt`. Due to behavior in Meson 0.51.1, ensure you **do not** export `CC`, `CFLAGS`, or `LDFLAGS` to the host environment when running `meson setup`. The cross-file natively handles target-specific sysroots, wrappers, and architecture flags to prevent host-machine execution errors.
4. **Compile:** Run the build sequence using `make` from the project root.

---

## 🤝 Contributing

Contributions, bug reports, and pull requests are always welcome! If you are submitting a PR that affects the build environment or Makefile, please verify that it cleanly passes the GitHub Actions cross-compilation workflow.
