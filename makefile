drivemake: drivestatus.c
	sudo add-apt-repository ppa:heyarje/makemkv-beta -y
	sudo add-apt-repository ppa:stebbins/handbrake-releases -y
	sudo add-apt-repository ppa:mc3man/xerus-media -y
	sudo apt-get update || true
	sudo apt install makemkv-bin makemkv-oss handbrake-cli libavcodec-extra abcde flac imagemagick glyrc cdparanoia abcde flac imagemagick glyrc cdparanoia at python3 python3-pip libdvd-pkg cifs-utils regionset -y
	sudo pip3 install -r requirements.txt
	sudo gcc drivestatus.c -o drivestatus.bin
	sudo dpkg-reconfigure libdvd-pkg
	sudo [ -f /opt/arm/config ] && echo "Config Already Exists" || sudo cp /opt/arm/config.sample /opt/arm/config
	sudo [ -f /lib/udev/rules.d/51-automedia.rules ] && echo "udev rules already copied" || sudo ln -s /opt/arm/51-automedia.rules /lib/udev/rules.d/
	sudo [ -f /root/.abcde.conf ] && echo "abcde config already copied" || sudo ln -s /opt/arm/.abcde.conf /root/
	sudo ln /opt/arm/0update-bin.sh /etc/cron.weekly/ || true
	whiptail --yesno "Set up beta key updater?" 20 60 && /opt/arm/install-beta.sh || true
