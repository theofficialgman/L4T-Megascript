#!/bin/bash


clear
echo "You are about to install the MATE desktop environment."
echo "Under most cases this shouldn't break anything and install alongside of your existing one, but just to be sure..."
echo "Are you sure you want to continue?"

##prompt yes/no
sudo apt update
sudo apt install mate-desktop-environment mate-desktop-environment-extras ubuntu-mate-themes plank -y
##should we add these?
##echo "Installing extras..."
##sudo apt-get install mate-session-manager mate-themes mate-screensaver mate-power-manager mate-indicator-applet mate-indicator-applet-common mate-tweak dconf-editor mate-applet-appmenu -y

echo "Adding autorotation script"

sudo apt install iio-sensor-proxy libxrandr2 libglib2.0-dev -y
cd /usr/local/bin
sudo rm -rf auto-rotate
sudo wget -O auto-rotate https://github.com/theofficialgman/yoga-900-auto-rotate/blob/master/auto-rotate?raw=true
sudo chmod +x auto-rotate
cd ~

dd of=~/.config/autostart/auto-rotate.desktop  << EOF
[Desktop Entry]
Type=Application
Name=Auto-Rotate
GenericName=rotation script
Exec=/usr/local/bin/auto-rotate
OnlyShowIn=cinnamon-session;MATE;LXDE;openbox
EOF

# add custom dock-hotplug
sudo rm -rf /etc/dock-hotplug.sh
echo | sudo tee /etc/dock-hotplug.sh <<'EOF'
#!/bin/bash
export DISPLAY=
export DP_SETTINGS=
while [ "$DISPLAY" = "" ]
do
	cd /tmp/.X11-unix && for x in X*;
	do
		if [ ! -e "$x" ]; then continue; fi
		export DISPLAY=":${x#X}"
		if [ "$DISPLAY" = "" ]; then sleep 1; continue; fi
		USER_NAME=$(who | awk -v vt="$DISPLAY" '$0 ~ vt {print $1}')
		USER_ID=$(id -u "$USER_NAME")
		PULSE_SERVER="unix:/run/user/"$USER_ID"/pulse/native"
		# from https://wiki.archlinux.org/index.php/Acpid#Laptop_Monitor_Power_Off
		export XAUTHORITY=$(ps -C Xorg -f --no-header | sed -n 's/.*-auth //; s/ -[^ ].*//; p')
		if [[ "$1" -eq 1 ]]
		then
			echo ""
		else
			xinput set-prop touchscreen "Coordinate Transformation Matrix" 0, -1, 1, 1, 0, 0, 0, 0, 1
			sudo -u "$USER_NAME" xinput set-prop touchscreen "Coordinate Transformation Matrix" 0, -1, 1, 1, 0, 0, 0, 0, 1
		fi
		sleep 1
	done
done

EOF
sudo chmod +x /etc/dock-hotplug.sh
# add the nvidia power profile indicator to startup
sudo dd of=/etc/xdg/autostart/nvpmodel.desktop << EOF
[Desktop Entry]
Type=Application
Name=Nvpmodel Indicator
GenericName=Indicator Nvidia
Exec=/usr/share/nvpmodel_indicator/nvpmodel_indicator.py
OnlyShowIn=LXDE;MATE;cinnamon-session
EOF

echo "Going back to the main menu..."