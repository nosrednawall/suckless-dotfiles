#!/usr/bin/env bash

# Carrega configuracoes do tema
source /home/anderson/.theme_selected
source /home/anderson/.bashrc
xrdb -merge ~/.Xresources

# Executa o script para verificar se o segundo monitor está ativo
if [ ! -f ~/.monitor_config.sh ]
then
    bash ~/.local/bin/check_second_monitor_is_active.sh
else
    bash ~/.monitor_config.sh
fi

# Define o papel de parede usando feh
# feh --recursive --bg-fill --randomize ~/.wallpapers/${THEME_MODE}/${COLOR_MODE}/ &
if [ "${THEME_MODE}" = "Pywal"  ]; then
    feh --recursive --bg-fill $(grep -oP "'\K[^']+(?=')" ~/.fehbg) &
else
    feh --recursive --bg-fill --randomize $(find ~/.wallpapers/${THEME_MODE}/${COLOR_MODE}/ -type f \( -iname \*.jpg -o -iname \*.png -o -iname \*.jpeg \) | shuf -n 1) &
fi

# Abre o dwmblocks
killall dwmblocks
xdotool key control+alt+d

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
is_running "dunst" || dunst -conf "$HOME/.config/dunst/themes/${THEME_MODE}_${COLOR_MODE}" &

# Inicia o copyq se não estiver rodando
is_running "copyq" || copyq &
#is_running "copyq" || flatpak run com.github.hluk.copyq &

# Inicia o daemon do emacs se não estiver rodando
is_running "emacs --daemon" || emacs --daemon &

#is_running "solaar" || /usr/bin/solaar -w hide &
#TECLADO_USA_CONECTADO=$(solaar show 521B6154 | grep "unknown (device is offline)" -ic)
setxkbmap -model pc105 -layout br -variant abnt2

# Bluetooth
#is_running "blueman-applet" || blueman-applet &

#if [ $TECLADO_USA_CONECTADO = "0" ]; then
#    setxkbmap -model pc105 -layout us -variant altgr-intl
#else
#    setxkbmap -model pc105 -layout br -variant abnt2
#fi
# Inicia o dwmblocks se não estiver rodando
#killall dwmblocks; export PATH=$PATH:$HOME/.config/suckless/scripts/dwmblocks && $HOME/.config/suckless/dwmblocks-async/build/dwmblocks &
#is_running "dwmblocks" || /usr/local/bin/dwmblocks
# &


# Inicia o mate-power-manager se não estiver rodando
# is_running "xfce4-power-manager" || xfce4-power-manager &

# Applet som
#is_running "pasystray" || pasystray &

# Wifi
#is_running "nm-applet" || nm-applet &

#bash ~/.local/bin/roda_dwmblocks.sh
