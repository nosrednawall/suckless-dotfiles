#!/usr/bin/env bash

muteVol=$(pactl get-sink-mute @DEFAULT_SINK@ | grep "sim" -ic)
muteMic=$(pactl get-source-mute @DEFAULT_SOURCE@ | grep 'sim' -ic)
volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep "Volume" | awk '{print$5}' | sed 's/%//')
microfone=$(pactl get-source-volume @DEFAULT_SOURCE@ | grep "Volume" | awk '{print$5}' | sed 's/%//')
camera=$(lsmod | grep "uvcvideo" | awk '{print$3}' | head -1)
brilho=$(brightnessctl | awk '/%/ {print$4}' | cut -c 2-4 | sed 's/%//' | sed 's/)//')
microfoneOn=$(cat /proc/asound/card0/pcm3p/sub0/status | grep "RUNNING")


if [ "$muteVol" -eq 1 ]; then
    iconVolume="^c#4A5947^󰸈 $volume󰏰"
else
    if [ "$volume" -le 30 ]; then
	iconVolume="^c#859900^󰕿 ^c#93a1a1^$volume󰏰"
    elif [ "$volume" -le 60 ]; then
	iconVolume="^c#859900^󰖀 ^c#93a1a1^$volume󰏰"
    elif [ "$volume" -ge 61 ]; then
	iconVolume="^c#859900^󰕾 ^c#93a1a1^$volume󰏰"
    fi
fi

if [ "$muteMic" -eq 1 ]; then
    iconMic="^c#4A5947^ $microfone󰏰"
else
    iconMic="^c#d33682^ ^c#93a1a1^$microfone󰏰"
fi

if [ "$camera" -eq 1 ]; then
    iconCam="  ^c#dc322f^ ^c#93a1a1^ On"
else
    iconCam=""
fi

brilhoIcone="^c#268bd2^󰃠 ^c#93a1a1^$brilho󰏰"

echo "$brilhoIcone  $iconVolume  $iconMic$iconCam"
