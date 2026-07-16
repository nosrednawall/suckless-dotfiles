#!/usr/bin/env sh
# Carrega o tema
source $HOME/.theme_selected

status=$(nmcli radio wifi | grep "enabled" -ic)

if [ $status -eq 1 ]; then
    nmcli radio wifi off
    notify-send -t 3000 "Wifi Off" "Placa wifi desligada" --icon="$THEME_ICON_DUNST/16x16/actions/brightnesssettings.svg"

else
    nmcli radio wifi on
    notify-send -t 3000 "Wifi On" "Placa wifi ligada" --icon="$THEME_ICON_DUNST/16x16/actions/brightnesssettings.svg"
fi

kill -10 $(pidof dwmblocks)
