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
  python3 python3-pip pipx python3-venv python3-setuptools python3-dev cargo default-jdk
  binutils gobuster seclists dirsearch rofi feh flameshot lxappearance xclip
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
go=$(curl https://go.dev/dl/ -s 2>/dev/null | grep linux | grep amd64 | head -n 1 | awk -F \" '{print $4}')
wget https://go.dev$go
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf $(echo $go | awk -F "/" '{print $3}')
rm -rf $(echo $go | awk -F "/" '{print $3}')
mkdir -p ~/go

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


# Install Espanso
echo "Installing Espanso..."
curl -s https://api.github.com/repos/espanso/espanso/releases/latest \
  | grep -E "browser_download_url.*Espanso-X11.AppImage" \
  | cut -d : -f 2,3 \
  | tr -d '"' \
  | grep -v sha256 \
  | wget -qi - -O espanso
chmod +x espanso
sudo mv espanso /usr/local/bin/espanso
mkdir -p "$HOME/.config/espanso/match"
cp "$script_dir/dots/base.yml" "$HOME/.config/espanso/match/base.yml"
espanso service register || true
espanso start || true

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

# Install pipx tools
python3 -m pipx ensurepath
pipx install --force azure-cli
pipx install --force pwntools
pipx install --force graphspy
pipx install --force "git+https://github.com/dirkjanm/ROADtools" --include-deps
python3 -m pip install --user --upgrade requests colorama

# Configure Docker under user context
sudo usermod -aG docker "$username"

# Set a randomized hostname (DESKTOP-XXXXXXXX)
random_suffix="$(tr -dc 'A-Z0-9' < /dev/urandom | head -c 8)"
new_hostname="DESKTOP-${random_suffix}"
echo "Setting hostname to ${new_hostname}..."
sudo hostnamectl set-hostname "$new_hostname"
# Keep /etc/hosts in sync to avoid: "sudo: unable to resolve host ..."
if sudo grep -qE '^127\.0\.1\.1[[:space:]]+' /etc/hosts; then
  sudo sed -i -E "s/^127\\.0\\.1\\.1[[:space:]].*/127.0.1.1\t${new_hostname}/" /etc/hosts
else
  echo -e "127.0.1.1\t${new_hostname}" | sudo tee -a /etc/hosts > /dev/null
fi

# AzureHound setup
echo "Setting up AzureHound..."
case "$arch" in
  x86_64) file_name="azurehound-linux-amd64.zip" ;;
  arm64|aarch64) file_name="azurehound-linux-arm64.zip" ;;
  *)
    echo "Unsupported architecture: $arch"
    exit 1
    ;;
esac
wget -q "https://github.com/BloodHoundAD/AzureHound/releases/latest/download/${file_name}" -O azurehound.zip
unzip -o azurehound.zip
mkdir -p "$install_dir/azure_hound"
mv -f ./azurehound "$install_dir/azure_hound/" || true
rm -f azurehound.zip

# BloodHound CLI setup
echo "Installing BloodHound CLI..."
case "$arch" in
  x86_64) bh_cli_asset="bloodhound-cli-linux-amd64.tar.gz" ;;
  arm64|aarch64) bh_cli_asset="bloodhound-cli-linux-arm64.tar.gz" ;;
  *)
    echo "Unsupported architecture for BloodHound CLI: $arch"
    exit 1
    ;;
esac
wget -q "https://github.com/SpecterOps/bloodhound-cli/releases/latest/download/${bh_cli_asset}" -O bloodhound-cli.tar.gz
tar -xzf bloodhound-cli.tar.gz
chmod +x bloodhound-cli
sudo mv -f bloodhound-cli /usr/local/bin/bloodhound-cli
rm -f bloodhound-cli.tar.gz


clear
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${BLUE}BloodHound CE compose file: ${GREEN}$install_dir/BloodhoundCE/docker-compose.yml${NC}"
echo -e "${YELLOW}Launch with:${NC} ${GREEN}cd $install_dir/BloodhoundCE && docker compose up -d${NC}"
echo -e "${YELLOW}Login UI:${NC} ${GREEN}http://localhost:8080/ui/login${NC}"
echo -e "${YELLOW}If needed, retrieve initial password from logs with:${NC}"
echo -e "${GREEN}docker logs bloodhoundce-bloodhound-1 2>&1 | grep \"Initial Password Set To:\"${NC}"
echo "Kali setup complete. Reboot is recommended so groups/PATH changes fully apply."
