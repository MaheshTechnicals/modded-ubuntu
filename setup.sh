#!/bin/bash

R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
B="$(printf '\033[1;34m')"
C="$(printf '\033[1;36m')"
W="$(printf '\033[1;37m')"

CURR_DIR=$(realpath "$(dirname "$BASH_SOURCE")")

# proot-distro v5.x uses a new OCI-based container path
UBUNTU_DIR="$PREFIX/var/lib/proot-distro/containers/ubuntu/rootfs"

# Fallback: also support legacy path (older proot-distro versions)
UBUNTU_DIR_LEGACY="$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"

banner() {
	clear
	cat <<- EOF
${C}    _  _ ___  _  _ _  _ ___ _  _    _  _ ____ ___
${Y}   |  | |__] |  | |\ |  |  |  |    |\/| |  | |  \\
${G}   |__| |__] |__| | \|  |  |__|    |  | |__| |__/
${W}
	EOF
	echo -e "${G}💻 Ubuntu Setup Script by Mahesh Technicals\n${W}"
}

# Returns the actual rootfs path regardless of proot-distro version
get_ubuntu_dir() {
	if [[ -d "$UBUNTU_DIR" ]]; then
		echo "$UBUNTU_DIR"
	elif [[ -d "$UBUNTU_DIR_LEGACY" ]]; then
		echo "$UBUNTU_DIR_LEGACY"
	else
		echo ""
	fi
}

package() {
	banner
	echo -e "${R} [${W}-${R}]${C} Checking required packages...${W}"

	[ ! -d '/data/data/com.termux/files/home/storage' ] && \
		echo -e "${R} [${W}-${R}]${C} Setting up Storage..${W}" && \
		termux-setup-storage

	if [[ $(command -v pulseaudio) && $(command -v proot-distro) ]]; then
		echo -e "\n${R} [${W}-${R}]${G} Packages already installed.${W}"
	else
		yes | pkg upgrade
		packs=(pulseaudio proot-distro)
		for x in "${packs[@]}"; do
			type -p "$x" &>/dev/null || {
				echo -e "\n${R} [${W}-${R}]${G} Installing package : ${Y}$x${C}${W}"
				yes | pkg install "$x"
			}
		done
	fi
}

distro() {
	echo -e "\n${R} [${W}-${R}]${C} Checking for Distro...${W}"
	termux-reload-settings

	local ddir
	ddir=$(get_ubuntu_dir)

	if [[ -n "$ddir" ]]; then
		echo -e "\n${R} [${W}-${R}]${G} Distro already installed.${W}"
		return 0
	fi

	# Install Ubuntu
	proot-distro install ubuntu
	termux-reload-settings

	# Re-check after install
	ddir=$(get_ubuntu_dir)
	if [[ -n "$ddir" ]]; then
		echo -e "\n${R} [${W}-${R}]${G} Installed Successfully !!${W}"
	else
		echo -e "\n${R} [${W}-${R}]${R} Error Installing Distro !\n${W}"
		exit 1
	fi
}

sound() {
	echo -e "\n${R} [${W}-${R}]${C} Fixing Sound Problem...${W}"
	[ ! -e "$HOME/.sound" ] && touch "$HOME/.sound"
	grep -qxF "pacmd load-module module-aaudio-sink" "$HOME/.sound" || \
		echo "pacmd load-module module-aaudio-sink" >> "$HOME/.sound"
	grep -qxF "pulseaudio --start --exit-idle-time=-1" "$HOME/.sound" || \
		echo "pulseaudio --start --exit-idle-time=-1" >> "$HOME/.sound"
	grep -qxF "pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" "$HOME/.sound" || \
		echo "pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" >> "$HOME/.sound"
}

downloader() {
	path="$1"
	[ -e "$path" ] && rm -rf "$path"
	echo "Downloading $(basename $1)..."
	curl --progress-bar --insecure --fail \
		 --retry-connrefused --retry 3 --retry-delay 2 \
		 --location --output "${path}" "$2"
	echo
}

setup_vnc() {
	local ddir
	ddir=$(get_ubuntu_dir)

	if [[ -d "$CURR_DIR/distro" ]] && [[ -e "$CURR_DIR/distro/vncstart" ]]; then
		cp -f "$CURR_DIR/distro/vncstart" "$ddir/usr/local/bin/vncstart"
	else
		downloader "$CURR_DIR/vncstart" "https://raw.githubusercontent.com/MaheshTechnicals/modded-ubuntu/refs/heads/mt/distro/vncstart"
		mv -f "$CURR_DIR/vncstart" "$ddir/usr/local/bin/vncstart"
	fi

	if [[ -d "$CURR_DIR/distro" ]] && [[ -e "$CURR_DIR/distro/vncstop" ]]; then
		cp -f "$CURR_DIR/distro/vncstop" "$ddir/usr/local/bin/vncstop"
	else
		downloader "$CURR_DIR/vncstop" "https://raw.githubusercontent.com/MaheshTechnicals/modded-ubuntu/refs/heads/mt/distro/vncstop"
		mv -f "$CURR_DIR/vncstop" "$ddir/usr/local/bin/vncstop"
	fi

	chmod +x "$ddir/usr/local/bin/vncstart"
	chmod +x "$ddir/usr/local/bin/vncstop"
}

permission() {
	banner
	echo -e "${R} [${W}-${R}]${C} Setting up Environment...${W}"

	local ddir
	ddir=$(get_ubuntu_dir)

	if [[ -z "$ddir" ]]; then
		echo -e "\n${R} [${W}-${R}]${R} Cannot find Ubuntu rootfs! Please re-run the script.${W}"
		exit 1
	fi

	# Copy or download user.sh into Ubuntu rootfs
	if [[ -d "$CURR_DIR/distro" ]] && [[ -e "$CURR_DIR/distro/user.sh" ]]; then
		cp -f "$CURR_DIR/distro/user.sh" "$ddir/root/user.sh"
	else
		downloader "$CURR_DIR/user.sh" "https://raw.githubusercontent.com/MaheshTechnicals/modded-ubuntu/refs/heads/mt/distro/user.sh"
		mv -f "$CURR_DIR/user.sh" "$ddir/root/user.sh"
	fi
	chmod +x "$ddir/root/user.sh"

	setup_vnc

	# Set timezone inside Ubuntu rootfs
	echo "$(getprop persist.sys.timezone)" > "$ddir/etc/timezone"

	# Create the 'ubuntu' shortcut command in Termux
	echo "clear; proot-distro login ubuntu" > "$PREFIX/bin/ubuntu"
	chmod +x "$PREFIX/bin/ubuntu"
	termux-reload-settings

	if [[ -e "$PREFIX/bin/ubuntu" ]]; then
		banner
		cat <<- EOF
			${R} [${W}-${R}]${G} Ubuntu (CLI) is now Installed on your Termux
			${R} [${W}-${R}]${G} Restart your Termux to Prevent Some Issues.
			${R} [${W}-${R}]${G} Type ${C}ubuntu${G} to run Ubuntu CLI.
			${R} [${W}-${R}]${G} If you Want to Use UBUNTU in GUI MODE then ,
			${R} [${W}-${R}]${G} Run ${C}ubuntu${G} first & then type ${C}bash user.sh${W}
		EOF
		{ echo; sleep 2; exit 0; }
	else
		echo -e "\n${R} [${W}-${R}]${R} Error creating ubuntu shortcut !${W}"
		exit 1
	fi
}

package
distro
sound
permission
