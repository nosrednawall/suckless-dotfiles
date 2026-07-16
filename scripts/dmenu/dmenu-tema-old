#!/bin/bash

# Temas disponiveis
solarized_dark="  Solarized Dark"
solarized_light="  Solarized Light"
gruvbox_dark="  Gruvbox Dark"
gruvbox_light="  Gruvbox Light"
catppuccin_dark="  Catppuccin Dark"
catppuccin_light="  Catppuccin Light"
nordic_dark="  Nord Dark"
nordic_light="  Nord Light"
dracula_dark="  Dracula Dark"
dracula_light="  Dracula Light"
vaporwave_dark="  Vaporwave Dark"
vaporwave_light="  Vaporwave Light"

# Opcoes Pywal
pywal_wallpaper_atual_dark="  Wallpaper Atual Dark"
pywal_wallpaper_aleatorio_dark="  Wallpaper Aleatório Dark"
pywal_wallpaper_atual_light="  Wallpaper Atual Light"
pywal_wallpaper_aleatorio_light="  Wallpaper Aleatório Light"

# Variable passed to dmenu
options="Pywal: \n$pywal_wallpaper_atual_dark\n$pywal_wallpaper_aleatorio_dark\n$pywal_wallpaper_atual_light\n$pywal_wallpaper_aleatorio_light\nDark :\n$catppuccin_dark\n$dracula_dark\n$gruvbox_dark\n$nordic_dark\n$solarized_dark\n$vaporwave_dark\nLight :\n$catppuccin_light\n$dracula_light\n$gruvbox_light\n$nordic_light\n$solarized_light\n$vaporwave_light"

# Apresenta Dmenu com as opcoes
chosen="$(echo -e "$options" | dmenu -p "Tema menu " )"

# Verifica se ecolheu alguma opcao
if [[ -z $chosen ]]; then
    exit 0
else
    # Notifica
    dunstify "Aplicando tema" "Iniciando.." -h int:value:10  -i /usr/share/icons/ePapirus/16x16/status/package-reinstall.svg

    # Envia a escolha ao script que fara a aplicação do tema
    $HOME/.local/bin/others/tema-aplicar "$chosen"
fi
