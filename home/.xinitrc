#!/usr/bin/env bash

# Carrega configuracoes do tema
source /home/anderson/.theme_selected

export QT_QPA_PLATFORMTHEME=gtk2

# Executa o script para verificar se o segundo monitor está ativo
if [ ! -f ~/.monitor_config.sh ]
then
    bash ~/.config/suckless/scripts/others/check_second_monitor_is_active.sh
else
    bash ~/.monitor_config.sh
fi

# Define o papel de parede usando feh
feh --recursive --bg-fill $(grep -oP "'\K[^']+(?=')" ~/.fehbg) &
# feh --recursive --bg-fill --randomize ~/.wallpapers/${THEME_MODE}/${COLOR_MODE}/ &
#if [ "${THEME_MODE}" = "Pywal"  ]; then
#    feh --recursive --bg-fill $(grep -oP "'\K[^']+(?=')" ~/.fehbg) &
#else
#    feh --recursive --bg-fill --randomize $(find ~/.wallpapers/${THEME_MODE}/${COLOR_MODE}/ -type f \( -iname \*.jpg -o -iname \*.png -o -iname \*.jpeg \) | shuf -n 1) &
#fi


# Função para verificar se um processo está rodando
is_running() {
    ps aux | grep -v grep | grep -q "$1"
}

# Polkit - para autenticar programas
is_running "lxpolkit" || lxpolkit &

# Inicia o xautolock com as configurações personalizadas se não estiver rodando
is_running "xautolock" || xautolock -time 15 -locker ~/.config/suckless/scripts/dwm/dwm-slock-personalizado -detectsleep &

# Inicia o picom em modo background
is_running "picom" || picom -b

# Inicia o dunst se não estiver rodando
is_running "dunst" || dunst -conf "$HOME/.config/dunst/dunstrc" &

# Inicia o copyq se não estiver rodando
is_running "copyq" || copyq &

# Está em um servico
# Inicia o daemon do emacs se não estiver rodando
#is_running "emacs" || emacs --daemon &

#is_running "solaar" || /usr/bin/solaar -w hide &
#TECLADO_USA_CONECTADO=$(solaar show 521B6154 | grep "unknown (device is offline)" -ic)
#setxkbmap -model pc105 -layout br -variant abnt2

# Inicia o dwmblocks
is_running "dwmblocks" || dwmblocks &

exec dwm
