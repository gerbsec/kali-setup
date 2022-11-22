echo "Script to set up VM on spawn"
echo "No need to run with root, if it needs sudo it'll ask for it just be ready to enter the password"
echo "These are my settings not yours so haha"
sleep 1
echo "firefox config? y/n"
read firefox
if [[ $firefox == "y" ]];then
    echo "Setting up firefox search engines"
    for i in $(find ~ | grep firefox | grep search.json); do cp firefoxConfig/search.json.mozlz4 $i 2>/dev/null;done
    echo "Setting up firefox preferences"
    for i in $(find ~ | grep firefox | grep prefs.js); do cp firefoxConfig/prefs.js $i 2>/dev/null;done
    echo "Setting up firefox extensions"
    for i in $(find ~ | grep firefox | grep default | grep extensions);do
        if [[ $i == *extensions ]];then
            dir=$i
        fi
    done
    mkdir -p extensions && cd extensions
    wget https://addons.mozilla.org/firefox/downloads/file/4028976/ublock_origin-1.45.2.xpi
    unzip ublock_origin-1.45.2.xpi
    name=$(cat manifest.json | grep \"id\" | awk -F \" '{print $4}')
    mv ublock_origin-1.45.2.xpi $dir/$name.xpi
    rm -rf extensions
    mkdir -p extensions && cd extensions
    wget https://addons.mozilla.org/firefox/downloads/file/3616824/foxyproxy_standard-7.5.1.xpi
    unzip foxyproxy_standard-7.5.1.xpi
    name=$(cat manifest.json | grep \"id\" | awk -F \" '{print $4}')
    mv foxyproxy_standard-7.5.1.xpi $dir/$name.xpi
    rm -rf extensions
    mkdir -p extensions && cd extensions
    wget https://addons.mozilla.org/firefox/downloads/file/3755764/cookie_editor-1.10.1.xpi
    unzip cookie_editor-1.10.1.xpi
    name=$(cat manifest.json | grep \"id\" | awk -F \" '{print $4}')
    mv cookie_editor-1.10.1.xpi $dir/$name.xpi
    rm -rf extensions
    mkdir -p extensions && cd extensions
    wget https://addons.mozilla.org/firefox/downloads/file/3952467/user_agent_string_switcher-0.4.8.xpi
    unzip user_agent_string_switcher-0.4.8.xpi
    name=$(cat manifest.json | grep \"id\" | awk -F \" '{print $4}')
    mv user_agent_string_switcher-0.4.8.xpi $dir/$name.xpi
    rm -rf extensions
elif [[ $firefox == "n" ]];then
    echo "ok moving on"
else
    echo "please choose y/n"
    exit 1
fi

echo "dotfiles config? y/n"
read dotfiles
if [[ $dotfiles == "y" ]];then
    sudo apt update && sudo apt install curl zsh -y
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    go=$(curl https://go.dev/dl/ -s 2>/dev/null | grep linux | grep amd64 | head -n 1 | awk -F \" '{print $4}')
    wget https://go.dev$go
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf $(echo $go | awk -F "/" '{print $3}')
    rm -rf $(echo $go | awk -F "/" '{print $3}')
    mkdir -p ~/go
    cp dots/.zshrc ~/.zshrc
    cp dots/.tmux.conf ~/.tmux.conf
elif [[ $dotfiles == "n" ]];then
    echo "nay"
else
    echo "please choose y/n"
    exit 1
fi