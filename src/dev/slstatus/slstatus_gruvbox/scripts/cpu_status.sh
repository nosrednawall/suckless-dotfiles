#!/usr/bin/env bash

tempCpu=$(sensors | awk '/edge/ {print$2}' | sed 's/+//')
#usageCpu=$(top -bn1 | grep load | awk '{printf "%.2f%%\t\t\n", $(NF-2)}')
icon="^b#282828^^c#89B482^"

read cpu a b c previdle rest < /proc/stat
prevtotal=$((a+b+c+previdle))
sleep 0.5
read cpu a b c idle rest < /proc/stat
total=$((a+b+c+idle))
usageCpu=$((100*( (total-prevtotal) - (idle-previdle) ) / (total-prevtotal) ))

if [ "$usageCpu" -le 10 ]; then
    icon="^b#282828^^c#98971a^"

elif [ "$usageCpu" -le 40 ]; then
    icon="^b#282828^^c#89B482^"

elif [ "$usageCpu" -le 60 ]; then
    icon="^b#282828^^c#d79921^"

elif [ "$usageCpu" -le 100 ]; then
    icon="^b#282828^^c#cc241d^"

else
    icon="^b#282828^^c#98971a^"

fi
echo "$icon ^b#282828^^c#d4be98^$usageCpu󰏰 $tempCpu"
