#!/usr/bin/env bash

status=$(/home/anderson/.dotfiles/.local/bin/pomodoro status --format "^c#dc322f^🍅 ^c#93a1a1^%r")

if [ -z "$status" ];then
   printf ""
else
   printf "$status  "
fi
