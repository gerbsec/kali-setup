#!/usr/bin/env bash

# Kali Linux Setup Script

# Get sudo credentials to do privileged installations
username=$(id -u -n 1000)
arch=$(uname -m)
sudo -v

# Preparation tasks 
install_dir=/opt/azure_pentesting
sudo mkdir -p "$install_dir"
sudo chown $username:$username $install_dir

# Update, upgrade, and install general dependencies
echo "Updating and upgrading system, and installing dependencies..."
sudo dpkg --add-architecture i386
sudo apt update && sudo apt dist-upgrade -y
sudo apt install -y curl zsh tmux vim binutils gobuster seclists dirsearch openjdk-17-jdk \
    arandr flameshot arc-theme feh i3blocks i3status i3 i3-wm lxappearance python3-pip rofi unclutter \
    cargo compton papirus-icon-theme imagemagick libxcb-shape0-dev libxcb-keysyms1-dev libpango1.0-dev \
    libxcb-util0-dev libxcb1-dev libxcb-icccm4-dev libyajl-dev libev-dev libxcb-xkb-dev libxcb-cursor-dev \
    libxkbcommon-dev libxcb-xinerama0-dev libxkbcommon-x11-dev libstartup-notification0-dev libxcb-randr0-dev \
    libxcb-xrm0 libxcb-xrm-dev autoconf meson apt-transport-https neo4j libxcb-render-util0-dev libxcb-shape0-dev \
    libxcb-xfixes0-dev xclip hashcat evil-winrm pipx docker.io docker-compose gdb
sudo apt autoremove && sudo apt autoclean -y

# Install Ruby gem packages
sudo gem install evil-winrm

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

# Install Nerd Fonts
mkdir -p ~/.local/share/fonts/
curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest  | grep -E "browser_download_url.*RobotoMono.zip" | cut -d : -f 2,3 | tr -d \" |  wget -qi -
unzip RobotoMono.zip -d ~/.local/share/fonts/
fc-cache -fv

# Clone and build i3-gaps
git clone https://www.github.com/Airblader/i3 i3-gaps
cd i3-gaps && mkdir -p build && cd build && meson ..
ninja
sudo ninja install
cd ../..

# Create config directories and copy configs
echo "Setting up configuration files..."
mkdir -p ~/.config/{i3,compton,rofi}
cp .config/i3/i3blocks.conf ~/.config/i3/i3blocks.conf
cp .config/compton/compton.conf ~/.config/compton/compton.conf
cp .config/rofi/config ~/.config/rofi/config
cp .config/i3/config ~/.config/i3/config
cp ~/kali-setup/dots/.fehbg ~/.fehbg
mkdir -p ~/.wallpaper
cp ~/kali-setup/wallpaper.jpeg ~/.wallpaper/wallpaper.jpeg
cp .config/i3/clipboard_fix.sh ~/.config/i3/clipboard_fix.sh

# Retina Display - DPI Fix
echo 'Xft.dpi: 100' > ~/.Xresources
echo '[ -r /home/kali/.config/kali-HiDPI/xsession-settings ] && . /home/kali/.config/kali-HiDPI/xsession-settings
xrandr --dpi 100
export XCURSOR_SIZE=20' > ~/.xsessionrc

# Install Espanso
echo "Installing Espanso..."
curl -s https://api.github.com/repos/espanso/espanso/releases/latest  | grep -E "browser_download_url.*Espanso-X11.AppImage" | cut -d : -f 2,3 | tr -d \" | grep -v sha256 | wget -qi - -O espanso
chmod +x espanso && sudo mv espanso /usr/bin/espanso 
espanso service register
espanso start
cp ~/kali-setup/dots/base.yml ~/.config/espanso/match/base.yml

# Install tmux and zsh configuration
cp ~/kali-setup/dots/.tmux.conf ~/.tmux.conf
echo "type exit after zsh install"
sleep 10
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
cp ~/kali-setup/dots/.zshrc ~/.zshrc

# Install Powershell tools
echo "Installing PowerShell tools..."
git clone https://github.com/Gerenios/AADInternals $install_dir/AADInternals
git clone https://github.com/dafthack/GraphRunner $install_dir/GraphRunner
git clone https://github.com/f-bader/TokenTacticsV2 $install_dir/TokenTacticsV2
git clone https://github.com/dafthack/MFASweep $install_dir/MFASweep

# Install python tools
echo "Installing Python tools..."
git clone https://github.com/yuyudhn/AzSubEnum $install_dir/AzSubEnum
git clone https://github.com/joswr1ght/basicblobfinder $install_dir/basicblobfinder
git clone https://github.com/gremwell/o365enum $install_dir/o365enum
git clone https://github.com/0xZDH/o365spray $install_dir/o365spray
git clone https://github.com/0xZDH/Omnispray $install_dir/Omnispray
git clone https://github.com/dievus/Oh365UserFinder $install_dir/Oh365UserFinder
sudo mkdir -p $install_dir/exfil_exchange_mail
sudo chown $username:$username $install_dir/exfil_exchange_mail
wget https://raw.githubusercontent.com/rootsecdev/Azure-Red-Team/master/Tokens/exfil_exchange_mail.py -O $install_dir/exfil_exchange_mail/exfil_exchange_mail.py

# Install pip and pipx tools
sudo pipx ensurepath --global
sudo pipx install azure-cli
sudo pipx install pwntools
sudo pipx install graphspy
sudo pipx install "git+https://github.com/dirkjanm/ROADtools" --include-deps
sudo pip install requests colorama

# Configure Docker to run under User Context
sudo usermod -aG docker $username

# AzureHound Setup
echo "Setting up AzureHound..."
file_name=""
case $arch in
    x86_64)
        file_name="azurehound-linux-amd64.zip"
        ;;
    arm64 | aarch64)
        file_name="azurehound-linux-arm64.zip"
        ;;
    *)
        echo "Unsupported architecture: $arch"
        exit 1
        ;;
esac
wget https://github.com/BloodHoundAD/AzureHound/releases/download/v2.1.7/${file_name} -O azurehound.zip
unzip azurehound.zip
mkdir azure_hound
mv ./azurehound azure_hound/
rm azurehound.zip

# Install BloodHoundCE
echo "Setting up BloodHound Community Edition..."
mkdir -p $install_dir/BloodhoundCE
curl https://raw.githubusercontent.com/SpecterOps/BloodHound/main/examples/docker-compose/docker-compose.yml -o /opt/azure_pentesting/BloodhoundCE/docker-compose.yml

# Post Installation Activities
# Clear the terminal
clear

# Define color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Instructions
echo -e "${BLUE}Bloodhound CE docker-compose file has been downloaded to /opt/azure_pentesting/BloodhoundCE${NC}"
echo -e "${YELLOW}To launch Bloodhound CE, navigate to${NC} ${GREEN}"/opt/azure_pentesting/BloodhoundCE/"${NC} ${YELLOW}and run the following command:${NC} ${GREEN}docker-compose up${NC}"
echo -e "${YELLOW}Note the randomly generated password from the logs, as you'll need it for the first login.${NC}"
echo -e "${YELLOW}To retrieve the password, use the command:${NC} ${GREEN}docker logs bloodhoundce_bloodhound_1 2>&1 | grep \"Initial Password Set To:\"${NC}"
echo -e "${YELLOW}Access the GUI at:${NC} ${GREEN}http://localhost:8080/ui/login${NC}. ${YELLOW}Ensure no other applications (e.g., BurpSuite) are using this port.${NC}"
echo -e "${YELLOW}Login using the username:${NC} ${GREEN}admin${NC} ${YELLOW}and the randomly generated password from the logs.${NC}"
echo -e "${YELLOW}Reboot your machine, then run the following command to update your PATH:${NC} ${GREEN}pipx ensurepath${NC}. ${YELLOW}Logout and log back in for changes to take effect.${NC}"

# Final message
echo "Kali setup complete! Please reboot your machine to apply all changes."
