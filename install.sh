#!/usr/bin/env bash

set -euo pipefail

# Kali Linux Setup Script

username="$(id -un)"
arch="$(uname -m)"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
install_dir="/opt/azure_pentesting"

sudo -v
sudo mkdir -p "$install_dir"
sudo chown "$username:$username" "$install_dir"

echo "Updating system and installing Kali packages..."
sudo dpkg --add-architecture i386
sudo apt update
sudo apt full-upgrade -y

# Keep this list Kali-repo friendly and deduplicated.
packages=(
  curl wget unzip ca-certificates apt-transport-https gnupg lsb-release software-properties-common
  zsh tmux vim git build-essential gdb ruby-full
  python3 python3-pip pipx python3-venv python3-setuptools python3-dev python3-requests python3-colorama cargo openjdk-25-jdk
  binutils gobuster seclists dirsearch rofi feh flameshot lxappearance xclip
  libxcb-shape0-dev libxcb-keysyms1-dev libpango1.0-dev libxcb-util0-dev libxcb1-dev libxcb-icccm4-dev
  libyajl-dev libev-dev libxcb-xkb-dev libxcb-cursor-dev libxkbcommon-dev libxcb-xinerama0-dev
  libxkbcommon-x11-dev libstartup-notification0-dev libxcb-randr0-dev libxcb-xrm0 libxcb-xrm-dev
  autoconf meson libxcb-render-util0-dev libxcb-xfixes0-dev
  papirus-icon-theme arc-theme hashcat evil-winrm neo4j
  docker.io docker-compose
)
sudo apt install -y "${packages[@]}"
sudo apt autoremove -y
sudo apt autoclean -y

# Remove BurpSuite
sudo apt purge burpsuite -y

# Go Language Setup
echo "Setting up Go language..."
case "$arch" in
  x86_64) go_arch="amd64" ;;
  arm64|aarch64) go_arch="arm64" ;;
  *)
    echo "Unsupported architecture for Go: $arch"
    exit 1
    ;;
esac
go_version="$(curl -fsSL https://go.dev/VERSION?m=text)"
go_version="${go_version%%[$'\r\n']*}"
go_tarball="${go_version}.linux-${go_arch}.tar.gz"
echo "Installing ${go_version} for ${go_arch}..."
wget -q "https://go.dev/dl/${go_tarball}" -O "${go_tarball}"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "${go_tarball}"
rm -f "${go_tarball}"
mkdir -p "$HOME/go"

# Install GEF (GDB Enhanced Features)
bash -c "$(curl -fsSL https://gef.blah.cat/sh)"


# Create config directories and copy configs
echo "Copying repository configuration files..."
mkdir -p "$HOME/.config/rofi"
cp "$script_dir/.config/rofi/config" "$HOME/.config/rofi/config"
cp "$script_dir/dots/.fehbg" "$HOME/.fehbg"
cp "$script_dir/dots/.tmux.conf" "$HOME/.tmux.conf"
cp "$script_dir/dots/.zshrc" "$HOME/.zshrc"

mkdir -p "$HOME/.wallpaper"
cp "$script_dir/wallpaper.jpeg" "$HOME/.wallpaper/wallpaper.jpeg"


# Install Espanso — Debian X11 .deb (recommended on Debian-based distros)
# https://espanso.org/docs/install/linux/#deb-x11
echo "Installing Espanso..."
if [[ "$go_arch" == "amd64" ]]; then
  espanso_deb="espanso-debian-x11-amd64.deb"
  wget -q "https://github.com/espanso/espanso/releases/latest/download/${espanso_deb}" -O "/tmp/${espanso_deb}"
  sudo apt install -y "/tmp/${espanso_deb}"
  rm -f "/tmp/${espanso_deb}"
  mkdir -p "$HOME/.config/espanso/match"
  cp "$script_dir/dots/base.yml" "$HOME/.config/espanso/match/base.yml"
  espanso service register || true
  espanso start || true
else
  echo "Skipping Espanso: official X11 .deb is amd64-only (espanso-debian-x11-amd64.deb). See espanso.org docs for other arches."
fi

# Install Oh My Zsh if not already installed.
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
cp "$script_dir/dots/.zshrc" "$HOME/.zshrc"

# Install PowerShell and Python tooling repos
echo "Cloning Azure tooling repositories..."
git clone --depth=1 https://github.com/Gerenios/AADInternals "$install_dir/AADInternals" || true
git clone --depth=1 https://github.com/dafthack/GraphRunner "$install_dir/GraphRunner" || true
git clone --depth=1 https://github.com/f-bader/TokenTacticsV2 "$install_dir/TokenTacticsV2" || true
git clone --depth=1 https://github.com/dafthack/MFASweep "$install_dir/MFASweep" || true
git clone --depth=1 https://github.com/yuyudhn/AzSubEnum "$install_dir/AzSubEnum" || true
git clone --depth=1 https://github.com/joswr1ght/basicblobfinder "$install_dir/basicblobfinder" || true
git clone --depth=1 https://github.com/gremwell/o365enum "$install_dir/o365enum" || true
git clone --depth=1 https://github.com/0xZDH/o365spray "$install_dir/o365spray" || true
git clone --depth=1 https://github.com/0xZDH/Omnispray "$install_dir/Omnispray" || true
git clone --depth=1 https://github.com/dievus/Oh365UserFinder "$install_dir/Oh365UserFinder" || true
mkdir -p "$install_dir/exfil_exchange_mail"
wget -q https://raw.githubusercontent.com/rootsecdev/Azure-Red-Team/master/Tokens/exfil_exchange_mail.py -O "$install_dir/exfil_exchange_mail/exfil_exchange_mail.py"

# Install pipx tools (each app gets its own venv; avoids touching system site-packages)
python3 -m pipx ensurepath
pipx install --force azure-cli
pipx install --force pwntools
pipx install --force graphspy
pipx install --force "git+https://github.com/dirkjanm/ROADtools" --include-deps
# requests/colorama come from apt (python3-requests, python3-colorama) — do not use pip install --user on Kali

echo "Adding user to docker group..."
# Configure Docker under user context
sudo usermod -aG docker "$username"

# Set a randomized hostname (DESKTOP-XXXXXXXX)
# NOTE: Do not use `tr ... | head -c 9` with `set -o pipefail`: head exits first and tr gets SIGPIPE (exit 141), which aborts the script.
chars='ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
random_suffix=''
for _ in {1..8}; do
  i=$((RANDOM % ${#chars}))
  random_suffix+="${chars:i:1}"
done
new_hostname="DESKTOP-${random_suffix}"
echo "Setting hostname to ${new_hostname}..."
# /etc/hosts must list the hostname before hostnamectl, or sudo will warn "unable to resolve host".
if sudo grep -qE '^127\.0\.1\.1[[:space:]]+' /etc/hosts; then
  sudo sed -i -E "s/^127\\.0\\.1\\.1[[:space:]].*/127.0.1.1\t${new_hostname}/" /etc/hosts
else
  echo -e "127.0.1.1\t${new_hostname}" | sudo tee -a /etc/hosts > /dev/null
fi
sudo hostnamectl set-hostname "$new_hostname"

# AzureHound: SpecterOps ships AzureHound_v*_linux_{amd64,arm64}.zip (old azurehound-linux-amd64.zip no longer exists).
echo "Setting up AzureHound..."
azure_url="$(curl -fsSL https://api.github.com/repos/SpecterOps/AzureHound/releases/latest | python3 -c "
import json, sys
j = json.load(sys.stdin)
a = sys.argv[1]
for x in j.get(\"assets\", []):
    n = x[\"name\"]
    if n.endswith(\"_linux_%s.zip\" % a) and not n.endswith(\".sha256\"):
        print(x[\"browser_download_url\"])
        sys.exit(0)
sys.exit(1)
" "$go_arch")"
wget -q "$azure_url" -O azurehound.zip
set +e
unzip -o azurehound.zip
uz=$?
set -e
[[ "$uz" -eq 0 || "$uz" -eq 1 ]] || exit "$uz"
mkdir -p "$install_dir/azure_hound"
chmod +x azurehound 2>/dev/null || true
mv -f azurehound "$install_dir/azure_hound/"
rm -f azurehound.zip

echo "Installing BloodHound CLI..."
wget -q "https://github.com/SpecterOps/bloodhound-cli/releases/latest/download/bloodhound-cli-linux-${go_arch}.tar.gz" -O bloodhound-cli.tar.gz
tar -xzf bloodhound-cli.tar.gz
chmod +x bloodhound-cli
sudo mv -f bloodhound-cli /usr/local/bin/bloodhound-cli
rm -f bloodhound-cli.tar.gz

clear
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${BLUE}AzureHound:${NC} ${GREEN}$install_dir/azure_hound/azurehound${NC}"
echo -e "${BLUE}bloodhound-cli:${NC} ${GREEN}/usr/local/bin/bloodhound-cli${NC}"
echo "Kali setup complete. Reboot is recommended so groups/PATH changes fully apply."
