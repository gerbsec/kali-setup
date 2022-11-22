echo "Script to set up VM on spawn"
echo "No need to run with root, if it needs sudo it'll ask for it just be ready to enter the password"
echo "These are my settings not yours so haha"
sleep 1
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