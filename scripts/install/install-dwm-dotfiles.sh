#!/usr/bin/env sh


cd ~/.config/suckless/src/dwm

# Install dwm
sudo make clean install

# Copy desktop laucher for session manager
sudo mkdir -p /usr/share/xsessions/
sudo cp dwm.desktop /usr/share/xsessions/dwm.desktop

# Install ST
cd ../st
sudo mkdir -p /usr/local/share/pixmaps/
sudo cp st.png /usr/local/share/pixmaps/st.png
sudo make clean install

# Install dmenu
cd ../dmenu
sudo make clean install

# Install dwmblocks
cd ../dwmblocks-async
sudo make clean install

# Install slock
cd ../slock
sudo make clean install

# Install potato-c - pomodoro
cd ../potato-c
sudo make clean install

# Fonts DWM e DWMblocks
cd ~/.config/suckless/assets
mkdir -p ~/.fonts
cp fonts/* ~/.fonts/
fc-cache -fvr
