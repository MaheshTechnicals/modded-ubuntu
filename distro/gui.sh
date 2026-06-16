#!/bin/bash

# ─────────────────────────────────────────────
# LOGGING INITIALIZATION
# ─────────────────────────────────────────────
LOG_FILE="/var/log/ubuntu_setup.log"

touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/ubuntu_setup.log"
echo "=== Setup Log Started At $(date) ===" >"$LOG_FILE"

log_msg() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >>"$LOG_FILE"
}

run_silent() {
    local task_name="$1"
    shift
    log_msg "STARTING: $task_name"
    echo -e "${C}Running: ${Y}$task_name...${W}"

    if "$@" >>"$LOG_FILE" 2>&1; then
        log_msg "SUCCESS: $task_name"
        echo -e "${G}✓ $task_name completed successfully.${W}"
    else
        log_msg "ERROR: $task_name failed with exit code $?"
        echo -e "${R}✗ ERROR in: $task_name (Check $LOG_FILE for details)${W}"
        sleep 2
    fi
}

# ─────────────────────────────────────────────
# VARIABLES & STYLES
# ─────────────────────────────────────────────
R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
W="$(printf '\033[1;37m')"
C="$(printf '\033[1;36m')"
arch=$(uname -m)

TERMUX_BIN="${PREFIX:-/data/data/com.termux/files/usr}/bin"

username=$(getent group sudo | awk -F ':' '{print $4}' | cut -d ',' -f1)
if [[ -z "$username" ]]; then
    username=$(ls /home 2>/dev/null | head -n1)
fi

# ─────────────────────────────────────────────
# HELPER: downloader
# ─────────────────────────────────────────────
downloader() {
    local dl_path="$1"
    local dl_url="$2"
    local filename
    filename="$(basename "$dl_path")"
    [[ -e "$dl_path" ]] && rm -rf "$dl_path"
    log_msg "Downloading $dl_url → $dl_path"

    echo -e ""
    echo -e "${C}  â†“ Downloading: ${Y}${filename}${W}"
    echo -e "${C}  â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€${W}"

    curl --progress-bar --insecure --fail \
        --retry-connrefused --retry 3 --retry-delay 2 \
        --location --output "$dl_path" "$dl_url" 2>&1
    local curl_exit=$?

    echo ""

    if [[ $curl_exit -eq 0 ]]; then
        echo -e "${G}  âœ“ Done: ${filename}${W}"
        log_msg "SUCCESS: Downloaded ${filename}"
    else
        echo -e "${R}  âœ— Failed: ${filename} (Check $LOG_FILE)${W}"
        log_msg "ERROR: Failed to download $dl_url (exit $curl_exit)"
    fi
    echo -e "${C}  â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€${W}"
    echo -e ""
}

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -ne " ${R}Run this program as root!\n\n${W}"
        log_msg "CRITICAL: Script stopped. Script was not run as root user."
        exit 1
    fi
}

fix_machineid() {
    echo -e "${C}Checking D-Bus machine-id...${W}"
    if [ ! -s /etc/machine-id ]; then
        echo -e "${Y}Machine-id missing or empty. Generating new one...${W}"
        rm -f /var/lib/dbus/machine-id /etc/machine-id
        dbus-uuidgen --ensure=/etc/machine-id >>"$LOG_FILE" 2>&1
        dbus-uuidgen --ensure >>"$LOG_FILE" 2>&1
        ln -sf /etc/machine-id /var/lib/dbus/machine-id
        echo -e "${G}Machine-id successfully created.${W}"
        log_msg "Machine-id was missing; new one generated successfully."
    else
        echo -e "${G}Machine-id already exists.${W}"
        log_msg "Machine-id verification skipped: file already valid."
    fi
}

banner() {
    clear
    echo -e "${C}    _  _ ___  _  _ _  _ ___ _  _    _  _ ____ ___"
    echo -e "${Y}   |  | |__] |  | |\ |  |  |  |    |\/| |  | |  \\"
    echo -e "${G}   |__| |__] |__| | \|  |  |__|    |  | |__| |__/"
    echo -e "${G}ðŸ’» Ubuntu GUI Setup Script by Mahesh Technicals\n${W}"
}

note() {
    banner
    echo -e " ${G} [-] Successfully Installed !\n${W}"
    echo -e " ${Y} [*] You can check all execution logs at: $LOG_FILE\n${W}"
    sleep 1
    cat <<- EOF
		 ${G}[-] Type ${C}vncstart${G} to run Vncserver.
		 ${G}[-] Type ${C}vncstop${G} to stop Vncserver.

		 ${Y}[!] Before first use, set a VNC password: ${C}vncpasswd${W}

		 ${C}Install VNC VIEWER Apk on your Device.

		 ${C}Open VNC VIEWER & Click on + Button.

		 ${C}Enter the Address localhost:1 & Name anything you like.

		 ${C}Set the Picture Quality to High for better Quality.

		 ${C}Click on Connect & Input the Password.

		 ${C}Enjoy :D${W}
	EOF

    echo -e "\n${C}â•”â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•—${W}"
    echo -e "${C}â•‘        ðŸš€  CUSTOM SHORTCUTS REFERENCE CHEATSHEET             â•‘${W}"
    echo -e "${C}â• â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•£${W}"
    echo -e "${C}â•‘  ${Y}SHORT       ${C}â•‘  ${G}FULL CMD     ${C}â•‘  ${W}DESCRIPTION                    ${C}â•‘${W}"
    echo -e "${C}â• â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•£${W}"

    echo -e "${C}â•‘  ${Y}vs          ${C}â•‘  ${G}vncstart     ${C}â•‘  ${W}Start VNC server               ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}vx          ${C}â•‘  ${G}vncstop      ${C}â•‘  ${W}Stop VNC server                ${C}â•‘${W}"
    echo -e "${C}â• â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•£${W}"

    echo -e "${C}â•‘  ${Y}sv          ${C}â•‘  ${G}start-venv   ${C}â•‘  ${W}Create + activate .venv here   ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}sv <name>   ${C}â•‘  ${G}start-venv   ${C}â•‘  ${W}Create + activate custom venv  ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}sx          ${C}â•‘  ${G}stop-venv    ${C}â•‘  ${W}Deactivate current venv        ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}vinfo       ${C}â•‘  ${G}venv-info    ${C}â•‘  ${W}Show active venv details       ${C}â•‘${W}"
    echo -e "${C}â• â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•£${W}"

    echo -e "${C}â•‘  ${Y}..          ${C}â•‘  ${G}cd ..        ${C}â•‘  ${W}Go up one directory            ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}...         ${C}â•‘  ${G}cd ../..     ${C}â•‘  ${W}Go up two directories          ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}l           ${C}â•‘  ${G}ls           ${C}â•‘  ${W}List files                     ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}ll          ${C}â•‘  ${G}ls -alF      ${C}â•‘  ${W}List files (detailed)          ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}la          ${C}â•‘  ${G}ls -A        ${C}â•‘  ${W}List all + hidden files        ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}cl          ${C}â•‘  ${G}clear        ${C}â•‘  ${W}Clear terminal                 ${C}â•‘${W}"
    echo -e "${C}â• â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•£${W}"

    echo -e "${C}â•‘  ${Y}gs          ${C}â•‘  ${G}git status   ${C}â•‘  ${W}Show git status                ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}ga          ${C}â•‘  ${G}git add .    ${C}â•‘  ${W}Stage all changes              ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}gc \"msg\"    ${C}â•‘  ${G}git commit   ${C}â•‘  ${W}Commit with message            ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}gp          ${C}â•‘  ${G}git push     ${C}â•‘  ${W}Push to remote                 ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}gl          ${C}â•‘  ${G}git log      ${C}â•‘  ${W}Pretty graph log               ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}gd          ${C}â•‘  ${G}git diff     ${C}â•‘  ${W}Show uncommitted changes       ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}gb          ${C}â•‘  ${G}git branch   ${C}â•‘  ${W}List branches                  ${C}â•‘${W}"
    echo -e "${C}â• â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•£${W}"

    echo -e "${C}â•‘  ${Y}update      ${C}â•‘  ${G}apt update + ${C}â•‘  ${W}Update & upgrade system        ${C}â•‘${W}"
    echo -e "${C}â•‘              ${C}â•‘  ${G}upgrade      ${C}â•‘                                  ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}install     ${C}â•‘  ${G}apt install  ${C}â•‘  ${W}Install a package              ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}remove      ${C}â•‘  ${G}apt remove   ${C}â•‘  ${W}Remove a package               ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}purge       ${C}â•‘  ${G}apt purge    ${C}â•‘  ${W}Purge a package + configs      ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}autoremove  ${C}â•‘  ${G}apt          ${C}â•‘  ${W}Remove unused packages         ${C}â•‘${W}"
    echo -e "${C}â•‘              ${C}â•‘  ${G}autoremove   ${C}â•‘                                  ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}search      ${C}â•‘  ${G}apt-cache    ${C}â•‘  ${W}Search for a package           ${C}â•‘${W}"
    echo -e "${C}â•‘              ${C}â•‘  ${G}search       ${C}â•‘                                  ${C}â•‘${W}"
    echo -e "${C}â• â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•£${W}"

    echo -e "${C}â•‘  ${Y}myip        ${C}â•‘  ${G}curl ifconf  ${C}â•‘  ${W}Show public IP address         ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}ports       ${C}â•‘  ${G}ss -tulpn    ${C}â•‘  ${W}Show open ports                ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}meminfo     ${C}â•‘  ${G}free -h      ${C}â•‘  ${W}Show RAM usage                 ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}diskinfo    ${C}â•‘  ${G}df -h        ${C}â•‘  ${W}Show disk usage                ${C}â•‘${W}"
    echo -e "${C}â• â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•£${W}"

    echo -e "${C}â•‘  ${Y}zshconfig   ${C}â•‘  ${G}nano ~/.zshrc${C}â•‘  ${W}Edit Zsh config                ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}reload      ${C}â•‘  ${G}source       ${C}â•‘  ${W}Reload .zshrc live             ${C}â•‘${W}"
    echo -e "${C}â•‘              ${C}â•‘  ${G}~/.zshrc     ${C}â•‘                                  ${C}â•‘${W}"

    echo -e "${C}â•šâ•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•©â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•©â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�${W}"
    echo -e " ${Y}Tip: ${W}Type any short alias — full command runs automatically!${W}\n"

    log_msg "=== Setup Completed Successfully ==="
}

package() {
    banner
    echo -e "${R} [${W}-${R}]${C} Checking required packages...${W}"

    run_silent "Updating apt repositories" apt-get update -y
    run_silent "Installing udisks2 package" apt-get install udisks2 -y

    rm -f /var/lib/dpkg/info/udisks2.postinst
    echo "" >/var/lib/dpkg/info/udisks2.postinst

    run_silent "Configuring DPKG" dpkg --configure -a
    run_silent "Holding udisks2 package changes" apt-mark hold udisks2

    packs=(sudo gnupg2 curl nano git xz-utils at-spi2-core xfce4 xfce4-goodies xfce4-terminal librsvg2-common menu inetutils-tools dialog exo-utils tigervnc-standalone-server tigervnc-common tigervnc-tools dbus-x11 fonts-beng fonts-beng-extra gtk2-engines-murrine gtk2-engines-pixbuf apt-transport-https gh)

    for hulu in "${packs[@]}"; do
        if ! dpkg -s "$hulu" &>/dev/null; then
            run_silent "Installing: $hulu" apt-get install "$hulu" -y --no-install-recommends
        else
            echo -e "${G}✓ $hulu already installed${W}"
        fi
    done

    run_silent "System repository update" apt-get update -y
    run_silent "System core package upgrade" apt-get upgrade -y
}

install_apt() {
    for pkg in "$@"; do
        if dpkg -s "$pkg" &>/dev/null; then
            echo -e "${Y}${pkg} is already Installed!${W}"
            log_msg "Apt Installer: $pkg is already installed."
        else
            run_silent "Installing: $pkg" apt-get install -y "${pkg}"
        fi
    done
}

install_vscode() {
    if [[ $(command -v code) ]]; then
        echo -e "${Y}VSCode is already Installed!${W}"
        return
    fi
    echo -e "${C}Running: ${Y}Installing VSCode...${W}"
    log_msg "STARTING: Installing VSCode"
    run_silent "Installing binutils (VSCode requirement)" apt-get install -y binutils
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
    run_silent "Updating repos for VSCode" apt-get update -y
    run_silent "Installing VSCode" apt-get install code -y
    echo -e "${C}Patching VSCode desktop entry...${W}"
    curl -fsSL https://raw.githubusercontent.com/MaheshTechnicals/modded-ubuntu/refs/heads/mt/patches/code.desktop > /usr/share/applications/code.desktop
    log_msg "VSCode installation completed."
    echo -e "${G}✓ VSCode installation finished.${W}"
}

install_cursor() {
    if [[ $(command -v cursor) ]]; then
        echo -e "${Y}Cursor is already Installed!${W}"
        return
    fi
    echo -e "${C}Running: ${Y}Installing Cursor AI Editor...${W}"
    log_msg "STARTING: Installing Cursor"
    downloader "/tmp/cursor.sh" "https://raw.githubusercontent.com/MaheshTechnicals/cursor-free-vip-termux/refs/heads/main/cursor.sh"
    chmod +x /tmp/cursor.sh
    run_silent "Installing expect" apt-get install -y expect

    log_msg "Launching Cursor installer via expect"
    expect << 'EOF'
set timeout -1
spawn sudo bash /tmp/cursor.sh -i
expect "Do you want to return to the main menu? (y/n):"
send "\r"
expect eof
EOF
    log_msg "Cursor installation completed."
    echo -e "${G}✓ Cursor installation finished.${W}"
}

install_firefox() {
    if [[ $(command -v firefox) ]]; then
        echo -e "${Y}Firefox is already Installed!${W}"
        return
    fi
    echo -e "${C}Running: ${Y}Installing Firefox...${W}"
    log_msg "STARTING: Installing Firefox"
    downloader "/tmp/firefox.sh" "https://raw.githubusercontent.com/MaheshTechnicals/modded-ubuntu/refs/heads/mt/distro/firefox.sh"
    chmod +x /tmp/firefox.sh
    echo -e "${C}Running Firefox installer (this may take a while)...${W}"
    bash /tmp/firefox.sh
    log_msg "Firefox installation completed."
    echo -e "${G}✓ Firefox installation finished.${W}"
}

set_default_browser() {
    echo -e "\n${R} [${W}-${R}]${C} Setting Firefox as default browser...${W}"
    log_msg "Setting Firefox as system default browser"

    if command -v xdg-settings >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
        xdg-settings set default-web-browser firefox.desktop >>"$LOG_FILE" 2>&1 &&
            log_msg "xdg-settings: Firefox set as default."
    fi

    if command -v update-alternatives >/dev/null 2>&1; then
        local ff_path
        ff_path=$(command -v firefox 2>/dev/null)
        if [[ -n "$ff_path" ]]; then
            update-alternatives --set x-www-browser "$ff_path" >>"$LOG_FILE" 2>&1 &&
                log_msg "update-alternatives: Firefox set as default."
        else
            log_msg "WARNING: update-alternatives skipped — firefox not found in PATH yet."
        fi
    fi

    cat >/etc/profile.d/default_browser.sh <<'EOF'
export BROWSER=firefox
EOF
    chmod 644 /etc/profile.d/default_browser.sh

    for homedir in /root "/home/$username"; do
        [ -d "$homedir" ] || continue
        mkdir -p "$homedir/.config/xfce4"
        mkdir -p "$homedir/.config"

        cat >"$homedir/.config/mimeapps.list" <<'EOF'
[Default Applications]
text/html=firefox.desktop
x-scheme-handler/http=firefox.desktop
x-scheme-handler/https=firefox.desktop
x-scheme-handler/about=firefox.desktop
x-scheme-handler/unknown=firefox.desktop
EOF
        log_msg "Set mimeapps.list for $homedir"

        if [ -f "$homedir/.config/xfce4/helpers.rc" ]; then
            if grep -q "^WebBrowser=" "$homedir/.config/xfce4/helpers.rc"; then
                sed -i 's/^WebBrowser=.*/WebBrowser=firefox/' "$homedir/.config/xfce4/helpers.rc"
            else
                echo "WebBrowser=firefox" >>"$homedir/.config/xfce4/helpers.rc"
            fi
        else
            echo "WebBrowser=firefox" >"$homedir/.config/xfce4/helpers.rc"
        fi
        log_msg "Set XFCE helpers.rc WebBrowser=firefox for $homedir"
    done
    echo -e "${G}✓ Firefox set as default browser.${W}"
}

install_languages() {
    banner
    cat <<- EOF
		${Y} ---${G} Select Coding Languages ${Y}---

		${C} [${W}1${C}] Node.js
		${C} [${W}2${C}] Python
		${C} [${W}3${C}] All (Node.js + Python)
		${C} [${W}4${C}] Skip! (Default)

	EOF
    read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" LANG_OPTION
    banner
    sleep 1

    install_node_latest() {
        run_silent "Updating repos for Node.js" apt-get update -y
        run_silent "Installing Node.js, NPM and ca-certificates" apt-get install -y nodejs npm ca-certificates

        echo -e "${C}Installing n (Node version manager)...${W}"
        npm install -g n 2>&1 | tee -a "$LOG_FILE"

        echo -e "${C}Switching to latest Node.js release (this may take a while)...${W}"
        if ! N_OPTS="--insecure" n latest 2>&1 | tee -a "$LOG_FILE"; then
            echo -e "${Y}[!] n latest failed — falling back to LTS release...${W}"
            log_msg "WARNING: n latest failed; retrying with n lts"
            N_OPTS="--insecure" n lts 2>&1 | tee -a "$LOG_FILE"
        fi

        echo -e "${C}Upgrading npm to latest...${W}"
        npm install -g npm@latest 2>&1 | tee -a "$LOG_FILE"
        echo -e "${G}✓ Node.js setup complete. Version: $(node -v 2>/dev/null)${W}"
        log_msg "Node.js installed. Version: $(node -v 2>/dev/null)"
    }

    install_python_latest() {
        run_silent "Updating repos for Python" apt-get update -y
        run_silent "Installing Python3, pip and venv" apt-get install -y python3 python3-pip python3-venv
        echo -e "${G}✓ Python setup complete. Version: $(python3 --version 2>/dev/null)${W}"
        log_msg "Python installed. Version: $(python3 --version 2>/dev/null)"
    }

    if [[ ${LANG_OPTION} == 1 ]]; then
        install_node_latest
    elif [[ ${LANG_OPTION} == 2 ]]; then
        install_python_latest
    elif [[ ${LANG_OPTION} == 3 ]]; then
        install_node_latest
        install_python_latest
    else
        echo -e "${Y} [!] Skipping Language Installation\n"
        log_msg "User skipped language installation."
        sleep 1
        return
    fi

    hash -r
    source /etc/profile
}

install_softwares() {
    banner

    echo -e "${R} [${W}-${R}]${C} Installing Browser...${W}"
    install_firefox
    set_default_browser

    [[ "$arch" != 'armhf' && "$arch" != *'armv7'* ]] && {
        banner
        cat <<- EOF
			${Y} ---${G} Select IDE ${Y}---

			${C} [${W}1${C}] Cursor AI Editor (Recommended)
			${C} [${W}2${C}] Visual Studio Code
			${C} [${W}3${C}] All (Cursor + VSCode)
			${C} [${W}4${C}] Skip! (Default)

		EOF
        read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" IDE_OPTION
        banner

        if [[ ${IDE_OPTION} == 1 ]]; then
            install_cursor
        elif [[ ${IDE_OPTION} == 2 ]]; then
            install_vscode
        elif [[ ${IDE_OPTION} == 3 ]]; then
            install_cursor
            install_vscode
        else
            echo -e "${Y} [!] Skipping IDE Installation\n"
            log_msg "User skipped IDE installation."
            sleep 1
        fi
    }

    banner
    cat <<- EOF
		${Y} ---${G} Media Player ${Y}---

		${C} [${W}1${C}] MPV Media Player (Recommended)
		${C} [${W}2${C}] VLC Media Player
		${C} [${W}3${C}] All (MPV + VLC)
		${C} [${W}4${C}] Skip! (Default)

	EOF
    read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" PLAYER_OPTION
    banner
    sleep 1

    if [[ ${PLAYER_OPTION} == 1 ]]; then
        install_apt "mpv"
    elif [[ ${PLAYER_OPTION} == 2 ]]; then
        install_apt "vlc"
    elif [[ ${PLAYER_OPTION} == 3 ]]; then
        install_apt "mpv" "vlc"
    else
        echo -e "${Y} [!] Skipping Media Player Installation\n"
        log_msg "User skipped media player installation."
        sleep 1
    fi

    install_languages
}

sound_fix() {
    if [[ -f "$TERMUX_BIN/ubuntu" ]]; then
        if ! grep -q "bash ~/.sound" "$TERMUX_BIN/ubuntu" 2>/dev/null; then
            echo "$(echo "bash ~/.sound" | cat - "$TERMUX_BIN/ubuntu")" >"$TERMUX_BIN/ubuntu"
            chmod +x "$TERMUX_BIN/ubuntu"
            log_msg "Sound fix applied to Ubuntu launcher."
        fi
    else
        log_msg "WARNING: $TERMUX_BIN/ubuntu not accessible inside proot — sound fix skipped. Already applied from Termux side."
        echo -e "${Y}[!] Sound fix will activate on next login from Termux side.${W}"
    fi
    grep -qxF 'export DISPLAY=":1"' /etc/profile || echo 'export DISPLAY=":1"' >>/etc/profile
    grep -qxF 'export PULSE_SERVER=127.0.0.1' /etc/profile || echo 'export PULSE_SERVER=127.0.0.1' >>/etc/profile
    source /etc/profile
    echo -e "${Y}[!] DISPLAY and PULSE_SERVER will be active on your next login.${W}"
}

rem_theme() {
    theme=(Bright Daloa Emacs Moheli Retro Smoke)
    for rmi in "${theme[@]}"; do
        if [ -d "/usr/share/themes/$rmi" ]; then
            rm -rf "/usr/share/themes/$rmi"
            log_msg "Removed theme: $rmi"
        fi
    done
}

rem_icon() {
    icons=(LoginIcons)
    for rmf in "${icons[@]}"; do
        if [ -d "/usr/share/icons/$rmf" ]; then
            rm -rf "/usr/share/icons/$rmf"
            log_msg "Removed icon set: $rmf"
        fi
    done
}

add_alias_l() {
    cat >/etc/profile.d/alias_l.sh <<'EOF'
alias l='ls'
EOF
    chmod 644 /etc/profile.d/alias_l.sh
    if [ -f /etc/bash.bashrc ]; then
        grep -qxF "alias l='ls'" /etc/bash.bashrc || echo "alias l='ls'" >>/etc/bash.bashrc
    fi
    log_msg "Alias l=ls set."
}

add_alias_cl() {
    cat >/etc/profile.d/alias_cl.sh <<'EOF'
alias cl='clear'
EOF
    chmod 644 /etc/profile.d/alias_cl.sh
    if [ -f /etc/bash.bashrc ]; then
        grep -qxF "alias cl='clear'" /etc/bash.bashrc || echo "alias cl='clear'" >>/etc/bash.bashrc
    fi
    log_msg "Alias cl=clear set."
}

# ─────────────────────────────────────────────
# ZSH SETUP
# ─────────────────────────────────────────────
setup_zsh() {
    banner
    echo -e "${C}[*] Setting up Zsh (fast mode, no Oh My Zsh)...${W}"
    log_msg "STARTING: Zsh fast setup"

    export DEBIAN_FRONTEND=noninteractive

    run_silent "Installing zsh + plugins" \
        apt-get install -y zsh zsh-autosuggestions zsh-syntax-highlighting git curl nano

    command -v zsh &>/dev/null || { echo -e "${R}✗ Zsh install failed${W}"; return 1; }

    _remove_omz() {
        local home_dir="$1"
        if [ -d "$home_dir/.oh-my-zsh" ]; then
            echo -e "${Y}[*] Removing Oh My Zsh (slow on proot)...${W}"
            rm -rf "$home_dir/.oh-my-zsh"
            log_msg "Removed Oh My Zsh from $home_dir"
            echo -e "${G}✓ Oh My Zsh removed${W}"
        fi
    }

    _write_zshrc() {
        local zshrc="$1"
        local owner="$2"

        [ -f "$zshrc" ] && cp "$zshrc" "${zshrc}.bak"

        cat > "$zshrc" << 'ZSHRC'
# ─────────────────────────────────────────────────────────────────
#  .zshrc — Modded-Ubuntu by Mahesh Technicals
#  Optimized for proot/Android — target < 200ms startup
# ─────────────────────────────────────────────────────────────────

# == PROMPT (git branch via built-in vcs_info, zero deps) =========
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
setopt PROMPT_SUBST
PROMPT='%F{cyan}%n%f%F{white}@%f%F{green}%m%f %F{yellow}%~%f%F{magenta}${vcs_info_msg_0_}%f %F{cyan}âžœ%f  '

# == COMPLETION (cached — rebuilds only once per day) =============
autoload -Uz compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi
skip_global_compinit=1
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# == HISTORY ======================================================
HISTFILE=~/.zsh_history
HISTSIZE=2000
SAVEHIST=2000
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY

# == OPTIONS ======================================================
setopt AUTO_CD CORRECT NO_BEEP

# == PLUGINS — lazy loaded after first prompt =====================
# Plugins source AFTER prompt appears = shell feels instant.
# Autosuggestions + syntax highlight available from second keystroke.
_load_plugins() {
    [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
        source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
        source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
    ZSH_AUTOSUGGEST_USE_ASYNC=true
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    precmd_functions=("${(@)precmd_functions:#_load_plugins}")
}
precmd_functions+=(_load_plugins)

# == KEY BINDINGS =================================================
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[[3~' delete-char

# == ALIASES ======================================================
alias l='ls --color=auto'
alias cl='clear'
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias ls='ls --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias vs='vncstart'
alias vx='vncstop'
alias update='sudo apt-get update && sudo apt-get upgrade -y'
alias install='sudo apt-get install -y'
alias remove='sudo apt-get remove -y'
alias purge='sudo apt-get purge -y'
alias autoremove='sudo apt-get autoremove -y'
alias search='apt-cache search'
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
alias gd='git diff'
alias gb='git branch'
alias myip='curl -s ifconfig.me && echo'
alias ports='ss -tulpn'
alias meminfo='free -h'
alias diskinfo='df -h'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias zshconfig='nano ~/.zshrc'
alias reload='source ~/.zshrc && echo "âœ“ .zshrc reloaded"'

# == PYTHON VENV SHORTCUTS ========================================
# start-venv / sv : create .venv in current dir (if needed) + activate
# stop-venv  / sx : deactivate current venv
# venv-info       : show active venv path and python version
# NOTE: These MUST be functions (not aliases) — `source` cannot run via alias.

start-venv() {
    local venv_dir="${1:-.venv}"
    if [[ ! -d "$venv_dir" ]]; then
        echo "ðŸ�� Creating virtual environment at ./$venv_dir ..."
        python3 -m venv "$venv_dir" || { echo "âœ— Failed. Is python3-venv installed?"; return 1; }
        echo "âœ“ Virtual environment created."
    fi
    echo "ðŸ”Œ Activating ./$venv_dir ..."
    source "$venv_dir/bin/activate"
    echo "âœ“ Venv active â†’ $(python3 --version) | $(which python3)"
}

stop-venv() {
    if [[ -z "$VIRTUAL_ENV" ]]; then
        echo "âš  No virtual environment is currently active."
        return 1
    fi
    echo "ðŸ”Œ Deactivating venv: $VIRTUAL_ENV"
    deactivate
    echo "âœ“ Venv deactivated."
}

venv-info() {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "ðŸ�� Active venv : $VIRTUAL_ENV"
        echo "   Python      : $(python3 --version)"
        echo "   Pip         : $(pip --version 2>/dev/null || echo 'not found')"
    else
        echo "âš  No virtual environment is currently active."
    fi
}

alias sv='start-venv'
alias sx='stop-venv'
alias vinfo='venv-info'
ZSHRC

        [[ "$owner" != "root" ]] && chown "$owner:$owner" "$zshrc"

        if [[ "$owner" == "root" ]]; then
            zsh -c "autoload -Uz compinit && compinit" >>"$LOG_FILE" 2>&1 || true
        else
            sudo -u "$owner" zsh -c "autoload -Uz compinit && compinit" >>"$LOG_FILE" 2>&1 || true
        fi
        log_msg "SUCCESS: .zshrc written for $owner"
    }

    _set_zsh_default() {
        local target_user="$1"
        local zsh_path
        zsh_path=$(which zsh)
        if usermod -s "$zsh_path" "$target_user" >>"$LOG_FILE" 2>&1; then
            echo -e "${G}✓ Default shell -> Zsh ($target_user)${W}"
        else
            sed -i "s|^\($target_user:.*:\)/.*$|\1$zsh_path|" /etc/passwd
            echo -e "${Y}[!] Set via /etc/passwd for $target_user${W}"
        fi
        log_msg "Default shell set to zsh for $target_user"
    }

    _remove_omz "/root"
    _write_zshrc "/root/.zshrc" "root"
    _set_zsh_default "root"

    if [[ -n "$username" ]] && [[ "$username" != "root" ]]; then
        _remove_omz "/home/$username"
        _write_zshrc "/home/$username/.zshrc" "$username"
        _set_zsh_default "$username"
    fi

    cat >/etc/profile.d/mahesh_shortcuts.sh <<'EOF'
alias l='ls --color=auto'
alias cl='clear'
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias ..='cd ..'
alias vs='vncstart'
alias vx='vncstop'
alias update='sudo apt-get update && sudo apt-get upgrade -y'
alias install='sudo apt-get install -y'

start-venv() {
    local venv_dir="${1:-.venv}"
    if [ ! -d "$venv_dir" ]; then
        echo "ðŸ�� Creating virtual environment at ./$venv_dir ..."
        python3 -m venv "$venv_dir" || { echo "âœ— Failed. Is python3-venv installed?"; return 1; }
        echo "âœ“ Virtual environment created."
    fi
    echo "ðŸ”Œ Activating ./$venv_dir ..."
    . "$venv_dir/bin/activate"
    echo "âœ“ Venv active â†’ $(python3 --version) | $(which python3)"
}

stop-venv() {
    if [ -z "$VIRTUAL_ENV" ]; then
        echo "âš  No virtual environment is currently active."
        return 1
    fi
    echo "ðŸ”Œ Deactivating venv: $VIRTUAL_ENV"
    deactivate
    echo "âœ“ Venv deactivated."
}

venv-info() {
    if [ -n "$VIRTUAL_ENV" ]; then
        echo "ðŸ�� Active venv : $VIRTUAL_ENV"
        echo "   Python      : $(python3 --version)"
        echo "   Pip         : $(pip --version 2>/dev/null || echo 'not found')"
    else
        echo "âš  No virtual environment is currently active."
    fi
}

alias sv='start-venv'
alias sx='stop-venv'
alias vinfo='venv-info'
EOF
    chmod 644 /etc/profile.d/mahesh_shortcuts.sh

    echo -e "${G}✓ Zsh fast setup complete.${W}"
    log_msg "SUCCESS: Zsh fast setup finished"
}

# ─────────────────────────────────────────────
# modded-ubuntu — system-wide help command
# ─────────────────────────────────────────────
install_modded_ubuntu() {
    local bin_path="/usr/local/bin/modded-ubuntu"

    cat > "$bin_path" << 'HELPSCRIPT'
#!/bin/bash
# modded-ubuntu -h  →  Show all custom shortcuts
# Created by Mahesh Technicals — Modded Ubuntu Setup

R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
W="$(printf '\033[1;37m')"
C="$(printf '\033[1;36m')"
M="$(printf '\033[1;35m')"

show_help() {
    clear
    echo -e "${C}    _  _ ___  _  _ _  _ ___ _  _    _  _ ____ ___"
    echo -e "${Y}   |  | |__] |  | |\ |  |  |  |    |\/| |  | |  \\"
    echo -e "${G}   |__| |__] |__| | \|  |  |__|    |  | |__| |__/"
    echo -e "${G}ðŸ’» Modded Ubuntu Setup by Mahesh Technicals\n${W}"

    echo -e "${C}â•”â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•—${W}"
    echo -e "${C}â•‘        ðŸš€  CUSTOM SHORTCUTS REFERENCE CHEATSHEET             â•‘${W}"
    echo -e "${C}â• â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•£${W}"
    echo -e "${C}â•‘  ${Y}SHORT       ${C}â•‘  ${G}FULL CMD     ${C}â•‘  ${W}DESCRIPTION                    ${C}â•‘${W}"
    echo -e "${C}â• â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•£${W}"

    echo -e "${C}â•‘  ${M}â”€â”€ VNC â”€â”€    ${C}â•‘              â•‘                                  â•‘${W}"
    echo -e "${C}â•‘  ${Y}vs          ${C}â•‘  ${G}vncstart     ${C}â•‘  ${W}Start VNC server               ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}vx          ${C}â•‘  ${G}vncstop      ${C}â•‘  ${W}Stop VNC server                ${C}â•‘${W}"
    echo -e "${C}â• â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•£${W}"

    echo -e "${C}â•‘  ${M}â”€â”€ Python Venv â”€â”€           â•‘                                  â•‘${W}"
    echo -e "${C}â•‘  ${Y}sv          ${C}â•‘  ${G}start-venv   ${C}â•‘  ${W}Create + activate .venv here   ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}sv <name>   ${C}â•‘  ${G}start-venv   ${C}â•‘  ${W}Create + activate custom venv  ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}sx          ${C}â•‘  ${G}stop-venv    ${C}â•‘  ${W}Deactivate current venv        ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}vinfo       ${C}â•‘  ${G}venv-info    ${C}â•‘  ${W}Show active venv details       ${C}â•‘${W}"
    echo -e "${C}â• â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•£${W}"

    echo -e "${C}â•‘  ${M}â”€â”€ Navigation â”€â”€            â•‘                                  â•‘${W}"
    echo -e "${C}â•‘  ${Y}..          ${C}â•‘  ${G}cd ..        ${C}â•‘  ${W}Go up one directory            ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}...         ${C}â•‘  ${G}cd ../..     ${C}â•‘  ${W}Go up two directories          ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}l           ${C}â•‘  ${G}ls           ${C}â•‘  ${W}List files                     ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}ll          ${C}â•‘  ${G}ls -alF      ${C}â•‘  ${W}List files (detailed)          ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}la          ${C}â•‘  ${G}ls -A        ${C}â•‘  ${W}List all + hidden files        ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}cl          ${C}â•‘  ${G}clear        ${C}â•‘  ${W}Clear terminal                 ${C}â•‘${W}"
    echo -e "${C}â• â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•£${W}"

    echo -e "${C}â•‘  ${M}â”€â”€ Git â”€â”€    â•‘              â•‘                                  â•‘${W}"
    echo -e "${C}â•‘  ${Y}gs          ${C}â•‘  ${G}git status   ${C}â•‘  ${W}Show git status                ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}ga          ${C}â•‘  ${G}git add .    ${C}â•‘  ${W}Stage all changes              ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}gc \"msg\"    ${C}â•‘  ${G}git commit   ${C}â•‘  ${W}Commit with message            ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}gp          ${C}â•‘  ${G}git push     ${C}â•‘  ${W}Push to remote                 ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}gl          ${C}â•‘  ${G}git log      ${C}â•‘  ${W}Pretty graph log               ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}gd          ${C}â•‘  ${G}git diff     ${C}â•‘  ${W}Show uncommitted changes       ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}gb          ${C}â•‘  ${G}git branch   ${C}â•‘  ${W}List branches                  ${C}â•‘${W}"
    echo -e "${C}â• â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•£${W}"

    echo -e "${C}â•‘  ${M}â”€â”€ APT Package Manager â”€â”€   â•‘                                  â•‘${W}"
    echo -e "${C}â•‘  ${Y}update      ${C}â•‘  ${G}apt update+  ${C}â•‘  ${W}Update & upgrade system        ${C}â•‘${W}"
    echo -e "${C}â•‘              ${C}â•‘  ${G}upgrade      ${C}â•‘                                  ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}install     ${C}â•‘  ${G}apt install  ${C}â•‘  ${W}Install a package              ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}remove      ${C}â•‘  ${G}apt remove   ${C}â•‘  ${W}Remove a package               ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}purge       ${C}â•‘  ${G}apt purge    ${C}â•‘  ${W}Purge package + configs        ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}autoremove  ${C}â•‘  ${G}apt          ${C}â•‘  ${W}Remove unused packages         ${C}â•‘${W}"
    echo -e "${C}â•‘              ${C}â•‘  ${G}autoremove   ${C}â•‘                                  ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}search      ${C}â•‘  ${G}apt-cache    ${C}â•‘  ${W}Search for a package           ${C}â•‘${W}"
    echo -e "${C}â•‘              ${C}â•‘  ${G}search       ${C}â•‘                                  ${C}â•‘${W}"
    echo -e "${C}â• â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•£${W}"

    echo -e "${C}â•‘  ${M}â”€â”€ System Info â”€â”€           â•‘                                  â•‘${W}"
    echo -e "${C}â•‘  ${Y}myip        ${C}â•‘  ${G}curl ifconf  ${C}â•‘  ${W}Show public IP address         ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}ports       ${C}â•‘  ${G}ss -tulpn    ${C}â•‘  ${W}Show open ports                ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}meminfo     ${C}â•‘  ${G}free -h      ${C}â•‘  ${W}Show RAM usage                 ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}diskinfo    ${C}â•‘  ${G}df -h        ${C}â•‘  ${W}Show disk usage                ${C}â•‘${W}"
    echo -e "${C}â• â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•¦â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•£${W}"

    echo -e "${C}â•‘  ${M}â”€â”€ Zsh Config â”€â”€            â•‘                                  â•‘${W}"
    echo -e "${C}â•‘  ${Y}zshconfig   ${C}â•‘  ${G}nano ~/.zshrc${C}â•‘  ${W}Edit Zsh config                ${C}â•‘${W}"
    echo -e "${C}â•‘  ${Y}reload      ${C}â•‘  ${G}source       ${C}â•‘  ${W}Reload .zshrc live             ${C}â•‘${W}"
    echo -e "${C}â•‘              ${C}â•‘  ${G}~/.zshrc     ${C}â•‘                                  ${C}â•‘${W}"
    echo -e "${C}â•šâ•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•©â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•©â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�â•�${W}"

    echo -e "\n ${Y}Usage:${W}"
    echo -e "   ${C}modded-ubuntu -h${W}   →  Show this shortcuts table"
    echo -e "   ${C}modded-ubuntu -v${W}   →  Show script version info\n"
    echo -e " ${Y}Tip: ${W}Type any short alias — full command runs automatically!${W}\n"
}

show_version() {
    echo -e "${G}modded-ubuntu${W} — Modded Ubuntu Setup Helper"
    echo -e "Version  : ${Y}1.0${W}"
    echo -e "Author   : ${C}Mahesh Technicals${W}"
    echo -e "Usage    : ${W}modded-ubuntu -h${W}"
}

case "${1:-}" in
    -h|--help)  show_help ;;
    -v|--version) show_version ;;
    *)
        echo -e "${Y}Usage: modded-ubuntu -h${W}   (show shortcuts table)"
        echo -e "       ${Y}modded-ubuntu -v${W}   (show version)"
        ;;
esac
HELPSCRIPT

    chmod +x "$bin_path"
    echo -e "${G}✓ modded-ubuntu installed → run: modded-ubuntu -h${W}"
    log_msg "SUCCESS: modded-ubuntu helper installed at $bin_path"
}

# ─────────────────────────────────────────────
# APPLY XFCE SETTINGS
# Writes xfconf XML files so themes, icons, and
# wallpaper take effect on next VNC/XFCE start.
# ─────────────────────────────────────────────
apply_xfce_settings() {
    echo -e "${R} [${W}-${R}]${C} Applying XFCE theme, icons & wallpaper...${W}"
    log_msg "STARTING: apply_xfce_settings"

    local theme_name=""
    local icon_name=""
    local wallpaper=""

    theme_name=$(find /usr/share/themes -mindepth 1 -maxdepth 1 -type d ! -name 'Bright' ! -name 'Daloa' ! -name 'Emacs' ! -name 'Moheli' ! -name 'Retro' ! -name 'Smoke' 2>/dev/null | head -1 | xargs basename 2>/dev/null)
    if [[ -d "/usr/share/icons/Flat-Remix-Blue-Dark" ]]; then
        icon_name="Flat-Remix-Blue-Dark"
    else
        icon_name=$(find /usr/share/icons -mindepth 1 -maxdepth 1 -type d ! -name 'LoginIcons' ! -name 'default' ! -name 'hicolor' 2>/dev/null | head -1 | xargs basename 2>/dev/null)
    fi
    wallpaper=$(find /usr/share/backgrounds/xfce -maxdepth 1 -type f \( -name '*.jpg' -o -name '*.png' -o -name '*.jpeg' \) 2>/dev/null | head -1)

    log_msg "Detected theme=$theme_name icon=$icon_name wallpaper=$wallpaper"

    write_xfconf_xml() {
        local target_home="$1"
        local target_user="$2"
        local xfconf_dir="$target_home/.config/xfce4/xfconf/xfce-perchannel-xml"
        mkdir -p "$xfconf_dir"

        if [[ -n "$theme_name" ]]; then
            cat > "$xfconf_dir/xsettings.xml" << XSETTINGS
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="$theme_name"/>
    <property name="IconThemeName" type="string" value="${icon_name:-Adwaita}"/>
  </property>
</channel>
XSETTINGS
            log_msg "Wrote xsettings.xml for $target_user (theme=$theme_name, icons=${icon_name:-Adwaita})"
        fi

        if [[ -n "$wallpaper" ]]; then
            cat > "$xfconf_dir/xfce4-desktop.xml" << XFDESKTOP
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="last-image" type="string" value="$wallpaper"/>
          <property name="image-style" type="int" value="5"/>
        </property>
      </property>
    </property>
  </property>
</channel>
XFDESKTOP
            log_msg "Wrote xfce4-desktop.xml for $target_user (wallpaper=$wallpaper)"
        else
            log_msg "WARNING: No wallpaper found in /usr/share/backgrounds/xfce/"
        fi

        if [[ -n "$theme_name" ]]; then
            cat > "$xfconf_dir/xfwm4.xml" << XFWM4
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="$theme_name"/>
  </property>
</channel>
XFWM4
            log_msg "Wrote xfwm4.xml for $target_user (wm-theme=$theme_name)"
        fi

        [[ "$target_user" != "root" ]] && chown -R "$target_user:$target_user" "$target_home/.config"
    }

    write_xfconf_xml "/root" "root"
    if [[ -n "$username" ]] && [[ "$username" != "root" ]] && [[ -d "/home/$username" ]]; then
        write_xfconf_xml "/home/$username" "$username"
    fi

    echo -e "${G}✓ XFCE settings applied (theme, icons, wallpaper).${W}"
    log_msg "SUCCESS: apply_xfce_settings finished"
}

config() {
    banner
    sound_fix

    add_alias_l
    add_alias_cl
    setup_zsh
    install_modded_ubuntu

    run_silent "Upgrading base packages" apt-get upgrade -y
    run_silent "Installing UI theme toolkits" apt-get install -y gtk2-engines-murrine gtk2-engines-pixbuf sassc optipng inkscape libglib2.0-dev-bin

    mv -vf /usr/share/backgrounds/xfce/xfce-verticals.png /usr/share/backgrounds/xfce/xfce-verticals-old.png >>"$LOG_FILE" 2>&1 || true

    temp_folder=$(mktemp -d -p "$HOME")
    banner
    sleep 1
    cd "$temp_folder" || exit 1

    echo -e "${R} [${W}-${R}]${C} Downloading Required Files..\n${W}"
    downloader "icons.tar.gz"           "https://github.com/MaheshTechnicals/modded-ubuntu/releases/download/config/icons.tar.gz"
    downloader "wallpaper.tar.gz"       "https://github.com/MaheshTechnicals/modded-ubuntu/releases/download/config/wallpaper.tar.gz"
    downloader "gtk-themes.tar.gz"      "https://github.com/MaheshTechnicals/modded-ubuntu/releases/download/config/gtk-themes.tar.gz"
    downloader "ubuntu-settings.tar.gz" "https://github.com/MaheshTechnicals/modded-ubuntu/releases/download/config/ubuntu-settings.tar.gz"

    echo -e "${R} [${W}-${R}]${C} Unpacking Files..\n${W}"
    log_msg "Extracting config assets to system directories."

    mkdir -p "/usr/local/share/fonts/"
    mkdir -p "/usr/share/icons/"
    mkdir -p "/usr/share/backgrounds/xfce/"
    mkdir -p "/usr/share/themes/"

    tar -xvzf icons.tar.gz           -C "/usr/share/icons/"            >>"$LOG_FILE" 2>&1
    tar -xvzf wallpaper.tar.gz       -C "/usr/share/backgrounds/xfce/" >>"$LOG_FILE" 2>&1
    tar -xvzf gtk-themes.tar.gz      -C "/usr/share/themes/"           >>"$LOG_FILE" 2>&1

    if [[ -n "$username" ]] && [[ -d "/home/$username" ]]; then
        tar -xvzf ubuntu-settings.tar.gz -C "/home/$username/" >>"$LOG_FILE" 2>&1
        chown -R "$username:$username" "/home/$username/" >>"$LOG_FILE" 2>&1
        echo -e "${G}✓ ubuntu-settings extracted and ownership fixed for $username.${W}"
        log_msg "SUCCESS: ubuntu-settings.tar.gz extracted to /home/$username/ with correct ownership."
    else
        echo -e "${Y}[!] Skipping ubuntu-settings.tar.gz — no valid user home directory.${W}"
        log_msg "WARNING: ubuntu-settings.tar.gz skipped — username empty or /home/$username missing."
    fi

    cd "$HOME" || true
    rm -fr "$temp_folder"

    echo -e "${R} [${W}-${R}]${C} Purging Unnecessary Files..${W}"
    rem_theme
    rem_icon

    apply_xfce_settings

    echo -e "${R} [${W}-${R}]${C} Rebuilding Font Cache..\n${W}"
    run_silent "Rebuilding font cache" fc-cache -fv

    echo -e "${R} [${W}-${R}]${C} Upgrading the System..\n${W}"
    run_silent "Final system update" apt-get update -y
    run_silent "Final system upgrade" apt-get upgrade -y
    run_silent "Cleaning package cache" apt-get clean
    run_silent "Removing orphan packages" apt-get autoremove -y
}

# ─────────────────────────────────────────────
# Main Execution Flow
# ─────────────────────────────────────────────
check_root
fix_machineid
package
install_softwares
config
note
