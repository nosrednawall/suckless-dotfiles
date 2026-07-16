#!/usr/bin/env bash

# Coloque aqui o local que identifica sem seu dispositivo está carregando ou descarregando
# IMPORTANTE ! A saída deve ser em binário, caso contrário resultará em erro!
is_plugged=$(cat /sys/class/power_supply/ACAD/online)

# Coloque aqui o local que identifica o número relativo a porcentagem da bateria de seu dispositivo
battery_level=$(cat /sys/class/power_supply/BAT1/capacity)

# EXTRA! Altere os ícones para qualquer um de sua preferência, assim como os valores da %
# EXTRA! Customize a cor do ícone começando com %{F#} e fechando com %{F-}
if [[ "$is_plugged" -eq 1 ]]; then
    icon="^b#282828^^c#989711^"
else
    if [ "$battery_level" -le 30 ]; then
	icon="^b#282828^^c#cc241d^"
    elif [ "$battery_level" -le 40 ]; then
	icon="^b#282828^^c#cc241d^"
    elif [ "$battery_level" -le 60 ]; then
	icon="^b#282828^^c#d79921^"
    elif [ "$battery_level" -le 90 ]; then
	icon="^b#282828^^c#98971a^"
    else
	icon="^b#282828^^c#98971a^"
    fi
fi

if [ "$battery_level" -le 95 ]; then
    echo "$icon ^b#282828^^c#d4be98^$battery_level󰏰 "
else
    echo ""
fi
