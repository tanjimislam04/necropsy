#!/usr/bin/env bash
# ==============================================================================
# Necropsy Forensics Platform — Universal 1-Command Installer
# Supported Platforms: Linux (Debian, Ubuntu, Kali, Fedora, Arch, openSUSE) & macOS
# ==============================================================================

set -e

APP_NAME="necropsy"
APP_DISPLAY_NAME="Necropsy"
VERSION="4.23.0"
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIBERICA_VERSION="17.0.12"
LIBERICA_BUILD="10"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

print_banner() {
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
  _   _                                           
 | \ | | ___  ___ _ __ ___  _ __  ___ _   _       
 |  \| |/ _ \/ __| '__/ _ \| '_ \/ __| | | |      
 | |\  |  __/ (__| | | (_) | |_) \__ \ |_| |      
 |_| \_|\___|\___|_|  \___/| .__/|___/\__, |      
                           |_|        |___/       
  Next-Generation Digital Forensics Analysis Platform
EOF
    echo -e "${NC}"
    echo -e "${BOLD}Universal Automated Installer for Linux & macOS${NC}"
    echo -e "Target Directory: ${BLUE}${INSTALL_DIR}${NC}\n"
}

# Doctor mode
run_doctor() {
    echo -e "\n${BOLD}${CYAN}=== Necropsy Dependency & Health Diagnostics ===${NC}\n"
    local all_good=true

    # 1. OS & Architecture
    local os="$(uname -s)"
    local arch="$(uname -m)"
    echo -e "  [✓] Operating System: ${GREEN}${os} (${arch})${NC}"

    # 2. Check Java & JavaFX
    local detected_java=""
    if [ -f "${INSTALL_DIR}/etc/necropsy.conf" ]; then
        detected_java=$(grep -E '^\s*jdkhome=' "${INSTALL_DIR}/etc/necropsy.conf" | head -n 1 | cut -d '=' -f 2 | tr -d '"')
    fi
    if [ -z "${detected_java}" ] && [ -d "${INSTALL_DIR}/.necropsy/jre" ]; then
        detected_java="${INSTALL_DIR}/.necropsy/jre"
    fi
    if [ -z "${detected_java}" ] && [ -n "${JAVA_HOME}" ]; then
        detected_java="${JAVA_HOME}"
    fi

    if [ -n "${detected_java}" ] && [ -x "${detected_java}/bin/java" ]; then
        local j_ver=$("${detected_java}/bin/java" -version 2>&1 | head -n 1)
        echo -e "  [✓] Java Runtime: ${GREEN}${detected_java}${NC} (${j_ver})"
        
        # Test JavaFX
        if "${detected_java}/bin/java" --add-modules javafx.controls -version >/dev/null 2>&1 || [ -f "${detected_java}/lib/jfxrt.jar" ] || [ -f "${detected_java}/jre/lib/ext/jfxrt.jar" ]; then
            echo -e "  [✓] JavaFX Support: ${GREEN}Available (OpenJFX integrated)${NC}"
        else
            echo -e "  [!] JavaFX Support: ${YELLOW}Missing in this JRE. (Necropsy will auto-bundle Liberica Full JRE)${NC}"
            all_good=false
        fi
    else
        echo -e "  [✗] Java Runtime: ${RED}Not configured or not found${NC}"
        all_good=false
    fi

    # 3. Check The Sleuth Kit
    if command -v tsk_loaddb >/dev/null 2>&1; then
        local tsk_path=$(command -v tsk_loaddb)
        echo -e "  [✓] Sleuth Kit Tools: ${GREEN}${tsk_path}${NC}"
    else
        echo -e "  [!] Sleuth Kit Tools: ${YELLOW}Not found in PATH (will be installed or embedded)${NC}"
    fi

    # 4. Check PhotoRec
    if command -v photorec >/dev/null 2>&1; then
        echo -e "  [✓] PhotoRec (Carving): ${GREEN}$(command -v photorec)${NC}"
    else
        echo -e "  [!] PhotoRec: ${YELLOW}testdisk package not installed${NC}"
    fi

    # 5. Check libewf
    if command -v ewfinfo >/dev/null 2>&1; then
        echo -e "  [✓] Expert Witness (.E01): ${GREEN}$(command -v ewfinfo)${NC}"
    else
        echo -e "  [!] Expert Witness Tools: ${YELLOW}ewf-tools not installed${NC}"
    fi

    # 6. Check Branding Assets
    if [ -f "${INSTALL_DIR}/icons/icon.ico" ] && [ -f "${INSTALL_DIR}/Core/src/org/sleuthkit/autopsy/casemodule/welcome_logo.png" ]; then
        echo -e "  [✓] Necropsy Branding & Logos: ${GREEN}Verified (Assets deployed)${NC}"
    else
        echo -e "  [!] Necropsy Branding Assets: ${YELLOW}Incomplete${NC}"
    fi

    # 7. Check Desktop Shortcut
    if [ -f "${HOME}/.local/share/applications/necropsy.desktop" ]; then
        echo -e "  [✓] Desktop Application Menu: ${GREEN}Installed (~/.local/share/applications/necropsy.desktop)${NC}"
    else
        echo -e "  [i] Desktop Application Menu: ${CYAN}Not created yet (run ./install.sh to create)${NC}"
    fi

    echo -e "\n-----------------------------------------------------"
    if [ "$all_good" = true ]; then
        echo -e "${GREEN}${BOLD}Diagnostic Result: All systems ready for Necropsy!${NC}\n"
    else
        echo -e "${YELLOW}${BOLD}Diagnostic Result: Run './install.sh' to automatically fix missing prerequisites.${NC}\n"
    fi
}

# Auto-detect best Java 17/21 with JavaFX
find_best_java() {
    local candidates=(
        "/usr/lib/jvm/jdk-17.0.20.1-full"
        "/usr/lib/jvm/jdk-21.0.12.1-full"
        "${INSTALL_DIR}/.necropsy/jre"
        "${INSTALL_DIR}/jre"
    )

    # Glob search for bellsoft or full JDKs
    for d in /usr/lib/jvm/*full* /usr/lib/jvm/*fx* /usr/lib/jvm/bellsoft* /Library/Java/JavaVirtualMachines/*full*/Contents/Home; do
        if [ -d "$d" ]; then
            candidates+=("$d")
        fi
    done

    if [ -n "$JAVA_HOME" ]; then
        candidates=("$JAVA_HOME" "${candidates[@]}")
    fi

    for j in "${candidates[@]}"; do
        if [ -x "${j}/bin/java" ]; then
            # Verify if this java has JavaFX
            if "${j}/bin/java" --add-modules javafx.controls -version >/dev/null 2>&1 || [ -f "${j}/lib/jfxrt.jar" ] || [ -f "${j}/jre/lib/ext/jfxrt.jar" ]; then
                echo "$j"
                return 0
            fi
        fi
    done

    echo ""
}

# Install missing OS packages
install_os_packages() {
    local os="$(uname -s)"
    echo -e "\n${BOLD}${BLUE}Checking and installing system forensic packages...${NC}"

    if [ "$os" = "Linux" ]; then
        if command -v apt-get >/dev/null 2>&1; then
            echo -e "Detected ${CYAN}Debian / Ubuntu / Kali${NC} package manager (apt)..."
            local pkgs=""
            command -v photorec >/dev/null 2>&1 || pkgs="$pkgs testdisk"
            command -v ewfinfo >/dev/null 2>&1 || pkgs="$pkgs ewf-tools"
            command -v tsk_loaddb >/dev/null 2>&1 || pkgs="$pkgs sleuthkit libtsk-dev"
            command -v curl >/dev/null 2>&1 || pkgs="$pkgs curl"
            command -v tar >/dev/null 2>&1 || pkgs="$pkgs tar"

            if [ -n "$pkgs" ]; then
                echo -e "Installing required packages: ${YELLOW}$pkgs${NC}..."
                if [ "$EUID" -eq 0 ]; then
                    apt-get update -qq && apt-get install -y -qq $pkgs
                elif command -v sudo >/dev/null 2>&1; then
                    sudo apt-get update -qq && sudo apt-get install -y -qq $pkgs
                else
                    echo -e "${YELLOW}Warning: sudo not available, skipping system package installation.${NC}"
                fi
            else
                echo -e "${GREEN}All required system packages are already installed!${NC}"
            fi
        elif command -v dnf >/dev/null 2>&1; then
            echo -e "Detected ${CYAN}Fedora / RHEL${NC} package manager (dnf)..."
            local pkgs=""
            command -v photorec >/dev/null 2>&1 || pkgs="$pkgs testdisk"
            command -v ewfinfo >/dev/null 2>&1 || pkgs="$pkgs libewf-tools"
            command -v tsk_loaddb >/dev/null 2>&1 || pkgs="$pkgs sleuthkit"
            if [ -n "$pkgs" ]; then
                sudo dnf install -y -q $pkgs || true
            fi
        elif command -v pacman >/dev/null 2>&1; then
            echo -e "Detected ${CYAN}Arch Linux${NC} package manager (pacman)..."
            local pkgs=""
            command -v photorec >/dev/null 2>&1 || pkgs="$pkgs testdisk"
            command -v tsk_loaddb >/dev/null 2>&1 || pkgs="$pkgs sleuthkit"
            if [ -n "$pkgs" ]; then
                sudo pacman -S --noconfirm --needed $pkgs || true
            fi
        fi
    elif [ "$os" = "Darwin" ]; then
        if command -v brew >/dev/null 2>&1; then
            echo -e "Detected ${CYAN}macOS Homebrew${NC}..."
            command -v photorec >/dev/null 2>&1 || brew install testdisk || true
            command -v tsk_loaddb >/dev/null 2>&1 || brew install sleuthkit || true
            command -v ewfinfo >/dev/null 2>&1 || brew install libewf || true
        else
            echo -e "${YELLOW}Homebrew not detected. Install Homebrew (https://brew.sh) for automatic tool dependencies.${NC}"
        fi
    fi
}

# Download self-contained Liberica Full JRE if needed
setup_bundled_jre() {
    local target_dir="${INSTALL_DIR}/.necropsy/jre"
    if [ -x "${target_dir}/bin/java" ]; then
        echo -e "${GREEN}Portable Java runtime already provisioned in ${target_dir}.${NC}"
        return 0
    fi

    echo -e "\n${BOLD}${BLUE}Provisioning self-contained JavaFX Runtime (Zero Java Dependency Mode)...${NC}"
    mkdir -p "${INSTALL_DIR}/.necropsy"

    local os="$(uname -s)"
    local arch="$(uname -m)"
    local url=""

    if [ "$os" = "Linux" ]; then
        if [ "$arch" = "x86_64" ]; then
            url="https://download.bell-sw.com/java/17.0.12+10/bellsoft-jre17.0.12+10-linux-amd64-full.tar.gz"
        elif [ "$arch" = "aarch64" ] || [ "$arch" = "arm64" ]; then
            url="https://download.bell-sw.com/java/17.0.12+10/bellsoft-jre17.0.12+10-linux-aarch64-full.tar.gz"
        fi
    elif [ "$os" = "Darwin" ]; then
        if [ "$arch" = "arm64" ]; then
            url="https://download.bell-sw.com/java/17.0.12+10/bellsoft-jre17.0.12+10-macos-aarch64-full.tar.gz"
        else
            url="https://download.bell-sw.com/java/17.0.12+10/bellsoft-jre17.0.12+10-macos-amd64-full.tar.gz"
        fi
    fi

    if [ -n "$url" ]; then
        echo -e "Downloading Liberica Full JRE from ${CYAN}${url}${NC}..."
        local tmp_tar="/tmp/necropsy_jre.tar.gz"
        curl -fsSL --progress-bar "$url" -o "$tmp_tar"
        echo -e "Extracting runtime to ${target_dir}..."
        mkdir -p "${target_dir}"
        tar -xzf "$tmp_tar" -C "${target_dir}" --strip-components=1
        rm -f "$tmp_tar"
        echo -e "${GREEN}Self-contained Java runtime installed successfully!${NC}"
    else
        echo -e "${RED}Unable to auto-download JRE for architecture ${arch}. Please install OpenJDK 17 with JavaFX.${NC}"
        return 1
    fi
}

# Configure necropsy.conf
configure_necropsy_conf() {
    local java_path="$1"
    echo -e "\n${BOLD}${BLUE}Configuring Necropsy runtime settings...${NC}"

    mkdir -p "${INSTALL_DIR}/etc"
    local conf_file="${INSTALL_DIR}/etc/necropsy.conf"
    
    # If conf file doesn't exist, copy from installer template
    if [ ! -f "$conf_file" ] && [ -f "${INSTALL_DIR}/installer_autopsy/etc/necropsy.conf" ]; then
        cp "${INSTALL_DIR}/installer_autopsy/etc/necropsy.conf" "$conf_file"
    elif [ ! -f "$conf_file" ]; then
        cat << 'EOF' > "$conf_file"
default_userdir="${DEFAULT_USERDIR_ROOT}/.necropsy/dev"
default_mac_userdir="${DEFAULT_USERDIR_ROOT}/Library/Application Support/necropsy/dev"
default_cachedir="${DEFAULT_CACHEDIR_ROOT}/dev"
default_options="--branding necropsy -J-Xms24m -J-Xmx4G -J-XX:+UseStringDeduplication -J-Dprism.order=sw -J--add-opens=java.base/java.lang=ALL-UNNAMED -J--add-opens=java.base/java.net=ALL-UNNAMED -J--add-opens=java.desktop/javax.swing=ALL-UNNAMED -J--add-opens=javafx.controls/javafx.scene.control.skin=ALL-UNNAMED -J--add-exports=java.desktop/sun.awt=ALL-UNNAMED -J--add-exports=javafx.controls/com.sun.javafx.scene.control.inputmap=ALL-UNNAMED -J--add-exports=javafx.base/com.sun.javafx.event=ALL-UNNAMED"
EOF
    fi

    # Update or add jdkhome
    if grep -q "^\s*jdkhome=" "$conf_file" 2>/dev/null; then
        sed -i "s|^\s*jdkhome=.*|jdkhome=\"${java_path}\"|" "$conf_file"
    else
        echo "jdkhome=\"${java_path}\"" >> "$conf_file"
    fi

    # Also sync installer_autopsy conf
    if [ -f "${INSTALL_DIR}/installer_autopsy/etc/necropsy.conf" ]; then
        if grep -q "^\s*jdkhome=" "${INSTALL_DIR}/installer_autopsy/etc/necropsy.conf" 2>/dev/null; then
            sed -i "s|^\s*jdkhome=.*|jdkhome=\"${java_path}\"|" "${INSTALL_DIR}/installer_autopsy/etc/necropsy.conf"
        else
            echo "jdkhome=\"${java_path}\"" >> "${INSTALL_DIR}/installer_autopsy/etc/necropsy.conf"
        fi
    fi

    echo -e "${GREEN}Configured jdkhome=\"${java_path}\" in ${conf_file}.${NC}"
}

# Create executable launcher bin/necropsy
create_launcher() {
    mkdir -p "${INSTALL_DIR}/bin"
    local bin_launcher="${INSTALL_DIR}/bin/necropsy"

    cat << 'EOF' > "$bin_launcher"
#!/usr/bin/env bash
# ==============================================================================
# Necropsy Smart Launcher
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONF_FILE="${SCRIPT_DIR}/etc/necropsy.conf"

JDK_HOME=""
if [ -f "$CONF_FILE" ]; then
    JDK_HOME=$(grep -E '^\s*jdkhome=' "$CONF_FILE" | head -n 1 | cut -d '=' -f 2 | tr -d '"')
fi

if [ -z "$JDK_HOME" ] || [ ! -x "${JDK_HOME}/bin/java" ]; then
    if [ -x "${SCRIPT_DIR}/.necropsy/jre/bin/java" ]; then
        JDK_HOME="${SCRIPT_DIR}/.necropsy/jre"
    elif [ -n "$JAVA_HOME" ] && [ -x "${JAVA_HOME}/bin/java" ]; then
        JDK_HOME="${JAVA_HOME}"
    fi
fi

if [ -z "$JDK_HOME" ] || [ ! -x "${JDK_HOME}/bin/java" ]; then
    echo "ERROR: Java runtime not configured for Necropsy."
    echo "Please run: ${SCRIPT_DIR}/install.sh to automatically setup runtime."
    exit 1
fi

# Detect Wayland vs X11 splash screen delay
EXTRA_ARGS=""
if [ -n "$WAYLAND_DISPLAY" ]; then
    EXTRA_ARGS="-J-Dawt.useSystemAAFontSettings=on -J-Dswing.aatext=true"
fi

# Ensure executable permissions on NetBeans harness
chmod +x "${SCRIPT_DIR}/platform/lib/nbexec" 2>/dev/null || true

# Launch application
exec "${SCRIPT_DIR}/platform/lib/nbexec" \
    --branding necropsy \
    --clusters "${SCRIPT_DIR}/necropsy:${SCRIPT_DIR}/platform" \
    --jdkhome "${JDK_HOME}" \
    ${EXTRA_ARGS} \
    "$@"
EOF

    chmod +x "$bin_launcher"
    chmod +x "${INSTALL_DIR}/unix_setup.sh" 2>/dev/null || true
    echo -e "${GREEN}Created smart launcher: ${bin_launcher}${NC}"

    # Global CLI shortcut
    local local_bin="${HOME}/.local/bin"
    mkdir -p "$local_bin"
    ln -sf "$bin_launcher" "${local_bin}/necropsy"
    echo -e "${GREEN}Linked CLI command: ${local_bin}/necropsy${NC}"
}

# Create desktop shortcut
create_desktop_shortcut() {
    local desktop_dir="${HOME}/.local/share/applications"
    mkdir -p "$desktop_dir"
    local desktop_file="${desktop_dir}/necropsy.desktop"
    local icon_path="${INSTALL_DIR}/unix/necropsy.png"

    cat << EOF > "$desktop_file"
[Desktop Entry]
Name=Necropsy
Comment=Next-Generation Digital Forensics Platform
GenericName=Digital Forensics & Incident Response
Exec="${INSTALL_DIR}/bin/necropsy" %F
Icon=${icon_path}
Terminal=false
Type=Application
Categories=Forensics;Security;Development;
Keywords=necropsy;autopsy;forensics;dfir;disk;image;investigation;
StartupWMClass=necropsy
EOF

    chmod +x "$desktop_file"
    echo -e "${GREEN}Created desktop launcher: ${desktop_file}${NC}"

    # Update desktop database if available
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "${desktop_dir}" 2>/dev/null || true
    fi
}

# Main installer flow
main() {
    print_banner

    if [ "$1" = "--doctor" ] || [ "$1" = "-d" ] || [ "$1" = "doctor" ]; then
        run_doctor
        exit 0
    fi

    # 1. Install OS packages
    install_os_packages

    # 2. Detect or setup Java
    echo -e "\n${BOLD}${BLUE}Checking Java runtime environment...${NC}"
    local java_path=$(find_best_java)
    if [ -n "$java_path" ]; then
        echo -e "${GREEN}Found compatible Java runtime with JavaFX: ${java_path}${NC}"
    else
        echo -e "${YELLOW}No compatible Java runtime with JavaFX found.${NC}"
        setup_bundled_jre
        java_path="${INSTALL_DIR}/.necropsy/jre"
    fi

    # 3. Configure necropsy.conf
    configure_necropsy_conf "$java_path"

    # 4. Create launcher
    create_launcher

    # 5. Create desktop application menu entry
    create_desktop_shortcut

    # 6. Run diagnostics
    run_doctor

    echo -e "${GREEN}${BOLD}=====================================================${NC}"
    echo -e "${GREEN}${BOLD}✓ Necropsy is successfully installed and configured!${NC}"
    echo -e "${GREEN}${BOLD}=====================================================${NC}"
    echo -e "You can launch Necropsy anytime by:"
    echo -e "  1. Running: ${CYAN}necropsy${NC} in your terminal (or ${CYAN}${INSTALL_DIR}/bin/necropsy${NC})"
    echo -e "  2. Searching for ${CYAN}'Necropsy'${NC} in your Application Menu / Desktop."
    echo ""
}

main "$@"
