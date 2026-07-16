#!/usr/bin/env bash

# Obtém a temperatura atual do monitor
temperatura=$(xrandr --verbose | awk '/Gamma/ {print $2}' | cut -d: -f3 | head -1)

# Verifica se conseguiu obter a temperatura
if [ -z "$temperatura" ]; then
    notify-send -t 3000 "Erro" "Não foi possível obter a temperatura atual" --icon=dialog-error
    exit 1
fi

# Comparação decimal usando bc
if (( $(echo "$temperatura >= 1.3" | bc -l) )); then
    redshift -P -O 6500
    notify-send -t 3000 "󰛨 Modo Diurno" "Alterado a temperatura para 6500K" --icon="/usr/share/icons/ePapirus/16x16/actions/colors-chromablue.svg"
else
    redshift -P -O 4500
    notify-send -t 3000 "󱩍 Modo Noturno" "Alterado a temperatura para 4500K" --icon="/usr/share/icons/ePapirus/16x16/actions/redeyes.svg"
fi

exit 0
