#!/usr/bin/env bash

status=$(cat /sys/class/net/enp4s0/operstate | grep "up" -ic)
status_on="BROADCAST,MULTICAST,UP,LOWER_UP"

if [ $status -eq 1 ]; then
    ip=$(ip addr show enp4s0  | grep 'inet' | awk '{print$2}' | sed 's/\/[0-9]*//' | head -1)
    ethernet="^c#6c71c4^󰈀 ^c#93a1a1^$ip  "
else
    ethernet=""
fi

echo "$ethernet"
