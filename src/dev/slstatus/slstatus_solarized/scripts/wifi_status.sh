#!/usr/bin/env bash

status=$(cat /sys/class/net/wlp5s0/operstate | grep "up" -ic)

if [ $status -eq 1 ]; then
    ip=$(ip addr show wlp5s0  | grep 'inet' | awk '{print$2}' | sed 's/\/[0-9]*//' | head -1)
    wifiname=$(nmcli -t -f NAME connection show --active | grep -E "[^Conexão cabeada 1]" | head -1)
    wifi="^c#b58900^ ^c#93a1a1^$wifiname $ip  "
else
    wifi=""
fi

echo "$wifi"
