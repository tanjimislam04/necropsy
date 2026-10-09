# Necropsy Forensics Platform

<p align="center">
  <img src="unix/necropsy.png" alt="Necropsy Logo" width="180" height="180"/>
</p>

<p align="center">
  <b>Next-Generation Open-Source Digital Forensics Analysis Platform</b><br>
  <i>Modern UI • 1-Command Automated Setup • Native .E01 & Raw Support • Pure Forensic Integrity</i>
</p>

<p align="center">
  <a href="#quick-start--installation"><img src="https://img.shields.io/badge/Platform-Linux%20%7C%20Windows%20%7C%20macOS-blue" alt="Platform Support"></a>
  <a href="#features"><img src="https://img.shields.io/badge/JavaFX-Zero--Configuration-brightgreen" alt="Zero Config JavaFX"></a>
  <a href="LICENSE-2.0.txt"><img src="https://img.shields.io/badge/License-Apache%202.0-orange" alt="License"></a>
</p>

---

## ⚡ The Pain Point Necropsy Solves

Digital forensics examiners, students, and CTF investigators have long faced severe frustration when attempting to install Autopsy:
- ❌ **The JavaFX Nightmare**: Missing `jfxrt.jar` / `javafx.scene.paint.Color` errors that crashed case creation on OpenJDK.
- ❌ **Manual SleuthKit Dependency Chains**: Hunting for matching `.deb` packages or compiling JNI libraries from source.
- ❌ **Complex Multi-Step Scripts**: Editing configuration files, setting `JAVA_HOME`, and debugging reflective access errors.

**Necropsy provides a true 1-Command, Zero-Headache installation for every major operating system.**

---

## 🚀 Quick Start & Installation

### 🐧 Linux (Ubuntu, Debian, Kali, Fedora, Arch)
Run a single command in your terminal:
```bash
./install.sh
```
*Or directly via curl:*
```bash
curl -sSL https://raw.githubusercontent.com/tanjimislam04/necropsy/main/install.sh | bash
```

**What the Linux installer does automatically:**
1. Installs system forensic packages (`testdisk`/`photorec`, `ewf-tools`, `sleuthkit`) via your native package manager (`apt`, `dnf`, or `pacman`).
2. Detects existing JavaFX runtimes or **automatically provisions a lightweight, isolated BellSoft Liberica Full JRE** directly into `.necropsy/jre` without requiring root or modifying system Java.
3. Automatically writes and validates `etc/necropsy.conf`.
4. Adds the global terminal shortcut `necropsy` (`~/.local/bin/necropsy`).
5. Installs the desktop application menu entry with the Necropsy icon.

---

### 🍏 macOS (Intel & Apple Silicon M1/M2/M3/M4)
Run:
```bash
./install_macos.sh
```

**What the macOS installer does automatically:**
1. Verifies Homebrew and installs `sleuthkit`, `libewf`, and `testdisk`.
2. Automatically provisions the native macOS Liberica Full JRE (universal ARM64 or x86_64).
3. Configures JNA bindings and gatekeeper execution rights.
4. Generates terminal and desktop application shortcuts.

---

### 🪟 Windows (10 / 11 / Server)
1. Double-click **`install.bat`** (or run `powershell -ExecutionPolicy Bypass -File install.ps1`).
2. The installer will:
   - Detect system architecture.
   - Automatically bundle portable Liberica Full JRE into `jre\` if not present.
   - Configure high-DPI scaling flags (crisp fonts on 4K/retina displays).
   - Create Desktop and Start Menu shortcuts with the official Necropsy icon.

---

## 🩺 Built-In Diagnostics Doctor

Check your environment and verify all subsystems anytime in 2 seconds:

```bash
./install.sh --doctor
```
*(On Windows: `powershell -File install.ps1 -Doctor`)*

**Sample Doctor Output:**
```text
=== Necropsy Dependency & Health Diagnostics ===

  [✓] Operating System: Linux (x86_64)
  [✓] Java Runtime: /usr/lib/jvm/jdk-17.0.20.1-full
  [✓] JavaFX Support: Available (OpenJFX integrated)
  [✓] Sleuth Kit Tools: /usr/local/bin/tsk_loaddb
  [✓] PhotoRec (Carving): /usr/bin/photorec
  [✓] Expert Witness (.E01): /usr/bin/ewfinfo
  [✓] Necropsy Branding & Logos: Verified (Assets deployed)
  [✓] Desktop Application Menu: Installed (~/.local/share/applications/necropsy.desktop)

Diagnostic Result: All systems ready for Necropsy!
```

---

## 🖥️ Launching Necropsy

Once installed, you can start Necropsy anytime by:
1. Typing **`necropsy`** in any terminal.
2. Clicking **Necropsy** in your Desktop Application Launcher / Start Menu.
3. Running `./bin/necropsy`.

---

## 📦 Core Capabilities

- **Native Expert Witness (.E01)**: First-class split `.E01` / `.E02` and raw disk image streaming without decompressing huge files to disk.
- **Forensic Integrity Guarantee**: Strict cryptographic hashing (MD5, SHA-1, SHA-256) with immutable read-only evidence access.
- **Full Artifact Extraction**:
  - Web browser history, cache, cookies, and downloads (Chrome, Firefox, Edge).
  - Windows Registry hive analysis (`SYSTEM`, `SOFTWARE`, `SAM`, `NTUSER.DAT`).
  - Carving unallocated sectors via integrated PhotoRec.
  - Keyword and regex in-content searching.
- **Reporting**: Automated HTML, Excel, and Case-UCO forensic reporting branded for Necropsy.

---

## 📄 License

Necropsy is released under the **Apache 2.0 License**. See [LICENSE-2.0.txt](LICENSE-2.0.txt) for details.
