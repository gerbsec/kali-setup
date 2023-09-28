echo "Script to set up kali VM on spawn"
echo "No need to run with root, if it needs sudo it'll ask for it just be ready to enter the password"
echo "These are my settings not yours so don't hate me cause im beautiful"
sleep 2
echo "Quick and dirty Firefox settings"
for i in $(find ~ | grep firefox | grep search.json); do cp ~/kali-setup/firefoxConfig/search.json.mozlz4 $i 2>/dev/null;done
for i in $(find ~ | grep firefox | grep prefs.js); do cp ~/kali-setup/firefoxConfig/prefs.js $i 2>/dev/null;done

echo "Installing some heat (dependencies)"
sleep 2
sudo dpkg --add-architecture i386
sudo apt update && sudo apt dist-upgrade -y
sudo apt install curl zsh tmux vim binutils dnsmasq gobuster seclists dirsearch libncurses5:i386 libstdc++6:i386 openjdk-17-jdk  -y
sudo apt install -y arandr flameshot arc-theme feh i3blocks i3status i3 i3-wm lxappearance python3-pip rofi unclutter cargo compton papirus-icon-theme imagemagick
sudo apt install -y libxcb-shape0-dev libxcb-keysyms1-dev libpango1.0-dev libxcb-util0-dev xcb libxcb1-dev libxcb-icccm4-dev libyajl-dev libev-dev libxcb-xkb-dev libxcb-cursor-dev libxkbcommon-dev libxcb-xinerama0-dev libxkbcommon-x11-dev libstartup-notification0-dev libxcb-randr0-dev libxcb-xrm0 libxcb-xrm-dev autoconf meson apt-transport-https neo4j bloodhound
sudo apt install -y libxcb-render-util0-dev libxcb-shape0-dev libxcb-xfixes0-dev 
sudo apt autoremove && sudo apt autoclean -y
sudo gem install evil-winrm
echo "Goooooolang setup"
go=$(curl https://go.dev/dl/ -s 2>/dev/null | grep linux | grep amd64 | head -n 1 | awk -F \" '{print $4}')
wget https://go.dev$go
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf $(echo $go | awk -F "/" '{print $3}')
rm -rf $(echo $go | awk -F "/" '{print $3}')
mkdir -p ~/go
bash -c "$(curl -fsSL https://gef.blah.cat/sh)"

echo "Installing bloodhound"
systemctl enable neo4j
curl -L "https://github.com/BloodHoundAD/BloodHound/releases/download/4.0.1/BloodHound-linux-x64.zip" --output /tmp/bloodhound.zip
unzip /tmp/bloodhound.zip -d /opt

mkdir -p ~/.local/share/fonts/

curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest  | grep -E "browser_download_url.*RobotoMono.zip" | cut -d : -f 2,3 | tr -d \" |  wget -qi -

unzip RobotoMono.zip -d ~/.local/share/fonts/
fc-cache -fv

git clone https://www.github.com/Airblader/i3 i3-gaps
cd i3-gaps && mkdir -p build && cd build && meson ..
ninja
sudo ninja install
cd ../..

mkdir -p ~/.config/i3
mkdir -p ~/.config/compton
mkdir -p ~/.config/rofi

cp .config/i3/i3blocks.conf ~/.config/i3/i3blocks.conf
cp .config/compton/compton.conf ~/.config/compton/compton.conf
cp .config/rofi/config ~/.config/rofi/config
cp .config/i3/config ~/.config/i3/config

cp .fehbg ~/.fehbg
mkdir -p ~/.wallpaper
cp ~/kali-setup/wallpaper.jpeg ~/.wallpaper/wallpaper.jpeg

cp .config/i3/clipboard_fix.sh ~/.config/i3/clipboard_fix.sh

# Retina Display - DPI Fix
echo 'Xft.dpi: 100' > ~/.Xresources
echo '[ -r /home/kali/.config/kali-HiDPI/xsession-settings ] && . /home/kali/.config/kali-HiDPI/xsession-settings
xrandr --dpi 100
export XCURSOR_SIZE=20' > ~/.xsessionrc

echo "Installing Espanso"
curl -s https://api.github.com/repos/espanso/espanso/releases/latest  | grep -E "browser_download_url.*Espanso-X11.AppImage" | cut -d : -f 2,3 | tr -d \" | grep -v sha256 | wget -qi - -O espanso
chmod +x espanso && sudo mv espanso /usr/bin/espanso 
espanso service register
espanso start
cp ~/kali-setup/dots/base.yml ~/.config/espanso/match/base.yml
cp ~/kali-setup/dots/.tmux.conf ~/.tmux.conf
sudo vim /etc/dnsmasq.d/gerbsec.conf
sudo echo vim /etc/resolv.conf
sudo chattr +i /etc/resolv.conf
sudo systemctl enable dnsmasq
sudo systemctl start dnsmasq
echo "type exit after zsh install"
sleep 10
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
cp ~/kali-setup/dots/.zshrc ~/.zshrc

echo "Import Bookmarks"
echo "Get Burp pro :D"
echo "Done! To have the wallpaper set on every boot edit ~.fehbg"
echo "After reboot: Select i3 on login, run lxappearance and select arc-dark"
