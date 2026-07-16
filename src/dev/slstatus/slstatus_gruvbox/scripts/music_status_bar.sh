#!/usr/bin/env bash

state=$(mpc status %state%)
if [ "$state" == "paused"  ]; then
	echo ""
else
	icon="󰝚"
	artist=$(mpc -f %artist% current  | cut -c 1-20)
	time=$(mpc -f %time% current)
	title=$(mpc -f %title% current  | cut -c 1-20)
	echo "^b#282828^^c#89B482^$icon ^b#282828^^c#d4be98^$title[$artist]"
fi
