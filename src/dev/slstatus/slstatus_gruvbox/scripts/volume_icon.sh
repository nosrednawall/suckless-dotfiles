#!/usr/bin/env bash

muteVol=$(pactl get-sink-mute @DEFAULT_SINK@ | grep "sim" -ic)
muteMic=$(pactl get-source-mute @DEFAULT_SOURCE@ | grep 'sim' -ic)
volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep "Volume" | awk '{print$5}' | sed 's/%//')
microfone=$(pactl get-source-volume @DEFAULT_SOURCE@ | grep "Volume" | awk '{print$5}' | sed 's/%//')
camera=$(fuser /dev/video*)
brilho=$(brightnessctl | awk '/%/ {print$4}' | cut -c 2-4 | sed 's/%//' | sed 's/)//')
microfoneOn=$(cat /proc/asound/card0/pcm3p/sub0/status | grep "RUNNING")


if [ "$muteVol" -eq 1 ]; then
    iconVolume="^b#282828^^c#4A5947^󰸈 $volume󰏰"
else
    if [ "$volume" -le 30 ]; then
	iconVolume="^b#282828^^c#B8bb26^󰕿^b#282828^^c#d4be98^$volume󰏰"
    elif [ "$volume" -le 60 ]; then
	iconVolume="^b#282828^^c#B8bb26^󰖀^b#282828^^c#d4be98^$volume󰏰"
    elif [ "$volume" -ge 61 ]; then
	iconVolume="^b#282828^^c#B8bb26^󰕾 ^b#282828^^c#d4be98^$volume󰏰"
    fi
fi

if [ "$muteMic" -eq 1 ]; then
    iconMic="^b#282828^^c#4A5947^ $microfone󰏰"
else
    iconMic="^b#282828^^c#B8bb26^ ^b#282828^^c#d4be98^$microfone󰏰"
fi

if [ -z "$camera" ]; then
    iconCam=""
else
    iconCam=" ^b#282828^^c#fb4934^"
fi

brilhoIcone="^b#282828^^c#B8bb26^󰃠 ^b#282828^^c#d4be98^$brilho󰏰"

echo "$brilhoIcone $iconVolume $iconMic$iconCam"
