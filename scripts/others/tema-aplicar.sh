#!/usr/bin/env bash

# Lê o nome da distribuição a partir do arquivo /etc/os-release
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        arch)
            sudo_askpass="/usr/lib/ssh/gnome-ssh-askpass3"
            ;;
        debian)
            sudo_askpass="/usr/bin/ssh-askpass"
            ;;
        *)
            echo "Sistema desconhecido ou não suportado: $ID"
            ;;
    esac
else
    echo "Não foi possível determinar a distribuição. O arquivo /etc/os-release não existe."
fi

# Opcoes de temas disponiveis
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

# Opcoes de Pywal
pywal_wallpaper_atual_dark="  Wallpaper Atual Dark"
pywal_wallpaper_aleatorio_dark="  Wallpaper Aleatório Dark"
pywal_wallpaper_atual_light="  Wallpaper Atual Light"
pywal_wallpaper_aleatorio_light="  Wallpaper Aleatório Light"
pywal="pywal"

# Variavel de controle, para configurar o wallpaper do pywal
pywal_flag="0"

# Aqui comeca a executar o script, o $1 é a opcao de tema passado como parametro para o script
case $1 in
    $pywal)

        # Aplica a flag que  um tema pywal
        pywal_flag="1"

        # gera o schema das cores conforme o wallpaper passado como parametro $2
        # esse script é importante pois ele vai salvar as cores para os temas do suckless
        bash $HOME/.config/suckless/scripts/others/pywal-execute "dark" "$2"

        # faz uma pausa enquando o pywal termina de salvar as informações
        sleep 1

        # Carrega o nome do wallpaper do pywal
        pywal_wallpaper="$(cat ~/.cache/wal/colors.json | jq -r '.wallpaper')"

        # variaveis do tema para o pywal
        THEME_GTK="FlatColor";
        THEME_ICON="flattrcolor";
        THEME_MODE="Pywal";
        COLOR_MODE="Dark";
        GTK_PREFER_DARK_MODE=1;
        EMACS_THEME="doom-one";
        WALLPAPER_LIGHTDM="$(basename pywal_wallpaper)";

        # carrega as cores geradas pelo pywal
        COLOR_BACKGROUND="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color0')"
        COLOR_BACKGROUND2="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color0')"
        COLOR_TEXT="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color7')"
        COLOR_1="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color1')"   # Yellow
        COLOR_2="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color2')"   # Orange
        COLOR_3="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color3')"   # Red
        COLOR_4="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color4')"   # Magenta
        COLOR_5="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color5')"   # Violet
        COLOR_6="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color6')"   # Blue
        COLOR_7="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color7')"   # Green
        COLOR_8="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color8')"   # Cyan
        COLOR_9="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color9')"   # Yellow
        COLOR_10="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color10')"   # Orange
        COLOR_11="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color11')"   # Red
        COLOR_12="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color12')"   # Magenta
        COLOR_13="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color13')"   # Violet
        COLOR_14="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color14')"   # Blue
        COLOR_15="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color15')"   # Green
        COLOR_16="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color0')"   # Cyan

        ;;
    $pywal_wallpaper_aleatorio_dark)
        pywal_flag="1"
        bash $HOME/.config/suckless/scripts/others/pywal-execute "dark"
        pywal_wallpaper="$(cat ~/.cache/wal/colors.json | jq -r '.wallpaper')"

        THEME_GTK="FlatColor";
        THEME_ICON="flattrcolor";
        THEME_MODE="Pywal";
        COLOR_MODE="Dark";
        GTK_PREFER_DARK_MODE=1;
        EMACS_THEME="doom-one";
        WALLPAPER_LIGHTDM="$(basename pywal_wallpaper)";

        COLOR_BACKGROUND="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color0')"
        COLOR_BACKGROUND2="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color0')"
        COLOR_TEXT="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color7')"
        COLOR_1="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color1')"   # Yellow
        COLOR_2="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color2')"   # Orange
        COLOR_3="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color3')"   # Red
        COLOR_4="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color4')"   # Magenta
        COLOR_5="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color5')"   # Violet
        COLOR_6="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color6')"   # Blue
        COLOR_7="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color7')"   # Green
        COLOR_8="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color8')"   # Cyan
        COLOR_9="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color9')"   # Yellow
        COLOR_10="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color10')"   # Orange
        COLOR_11="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color11')"   # Red
        COLOR_12="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color12')"   # Magenta
        COLOR_13="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color13')"   # Violet
        COLOR_14="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color14')"   # Blue
        COLOR_15="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color15')"   # Green
        COLOR_16="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color0')"   # Cyan
        ;;
    $pywal_wallpaper_atual_dark)
        pywal_flag="1"
        pywal_wallpaper=$(grep -oP "'\K[^']+(?=')" ~/.fehbg)

        bash $HOME/.config/suckless/scripts/others/pywal-execute "dark" "${wallpaper}"

        THEME_GTK="FlatColor";
        THEME_ICON="flattrcolor";
        THEME_MODE="Pywal";
        COLOR_MODE="Dark";
        GTK_PREFER_DARK_MODE=1;
        EMACS_THEME="doom-one";
        WALLPAPER_LIGHTDM="$(basename pywal_wallpaper)";

        COLOR_BACKGROUND="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color0')"
        COLOR_BACKGROUND2="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color0')"
        COLOR_TEXT="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color7')"
        COLOR_1="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color1')"   # Yellow
        COLOR_2="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color2')"   # Orange
        COLOR_3="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color3')"   # Red
        COLOR_4="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color4')"   # Magenta
        COLOR_5="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color5')"   # Violet
        COLOR_6="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color6')"   # Blue
        COLOR_7="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color8')"   # Green
        COLOR_8="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color9')"   # Cyan
        COLOR_9="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color1')"   # Yellow
        COLOR_10="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color2')"   # Orange
        COLOR_11="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color3')"   # Red
        COLOR_12="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color4')"   # Magenta
        COLOR_13="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color5')"   # Violet
        COLOR_14="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color6')"   # Blue
        COLOR_15="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color8')"   # Green
        COLOR_16="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color9')"   # Cyan
    ;;
    $pywal_wallpaper_aleatorio_light)
        pywal_flag="1"
        bash $HOME/.config/suckless/scripts/others/pywal-execute "light"
        pywal_wallpaper="$(cat ~/.cache/wal/colors.json | jq -r '.wallpaper')"

        THEME_GTK="FlatColor";
        THEME_ICON="flattrcolor";
        THEME_MODE="Pywal";
        COLOR_MODE="Light";
        GTK_PREFER_DARK_MODE=1;
        EMACS_THEME="doom-one";
        WALLPAPER_LIGHTDM="$(basename pywal_wallpaper)";

        COLOR_BACKGROUND="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color0')"
        COLOR_BACKGROUND2="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color0')"
        COLOR_TEXT="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color7')"
        COLOR_1="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color1')"   # Yellow
        COLOR_2="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color2')"   # Orange
        COLOR_3="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color3')"   # Red
        COLOR_4="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color4')"   # Magenta
        COLOR_5="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color5')"   # Violet
        COLOR_6="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color6')"   # Blue
        COLOR_7="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color7')"   # Green
        COLOR_8="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color8')"   # Cyan
        COLOR_9="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color9')"   # Yellow
        COLOR_10="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color10')"   # Orange
        COLOR_11="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color11')"   # Red
        COLOR_12="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color12')"   # Magenta
        COLOR_13="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color13')"   # Violet
        COLOR_14="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color14')"   # Blue
        COLOR_15="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color15')"   # Green
        COLOR_16="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color0')"   # Cyan

    ;;
    $pywal_wallpaper_atual_light)
        pywal_flag="1"
        pywal_wallpaper=$(grep -oP "'\K[^']+(?=')" ~/.fehbg)

        bash $HOME/.config/suckless/scripts/others/pywal-execute "light" "${wallpaper}"

        THEME_GTK="FlatColor";
        THEME_ICON="flattrcolor";
        THEME_MODE="Pywal";
        COLOR_MODE="Light";
        GTK_PREFER_DARK_MODE=1;
        EMACS_THEME="doom-one";
        WALLPAPER_LIGHTDM="$(basename pywal_wallpaper)";

        COLOR_BACKGROUND="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color0')"
        COLOR_BACKGROUND2="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color0')"
        COLOR_TEXT="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color7')"
        COLOR_1="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color1')"   # Yellow
        COLOR_2="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color2')"   # Orange
        COLOR_3="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color3')"   # Red
        COLOR_4="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color4')"   # Magenta
        COLOR_5="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color5')"   # Violet
        COLOR_6="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color6')"   # Blue
        COLOR_7="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color7')"   # Green
        COLOR_8="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color8')"   # Cyan
        COLOR_9="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color9')"   # Yellow
        COLOR_10="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color10')"   # Orange
        COLOR_11="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color11')"   # Red
        COLOR_12="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color12')"   # Magenta
        COLOR_13="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color13')"   # Violet
        COLOR_14="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color14')"   # Blue
        COLOR_15="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color15')"   # Green
        COLOR_16="$(cat ~/.cache/wal/colors.json | jq -r '.colors.color0')"   # Cyan

    ;;
    $solarized_dark)

        THEME_GTK="NumixSolarizedDarkCyan";
        THEME_ICON="Numix-Circle";
        THEME_MODE="Solarized";
        COLOR_MODE="Dark";
        GTK_PREFER_DARK_MODE=1;
        EMACS_THEME="doom-solarized-dark";
        WALLPAPER_LIGHTDM="LbI3B9z.jpeg";

        # Cores base (originais)
        COLOR_BACKGROUND="#002B36"       # Fundo principal (azul-escuro)
        COLOR_BACKGROUND2="#073642"      # Fundo secundário (mesmo que o principal)
        COLOR_TEXT="#839496"             # Texto principal (cinza-azulado)
        COLOR_1="#b58900"                # Amarelo
        COLOR_2="#cb4b16"                # Laranja
        COLOR_3="#dc322f"                # Vermelho
        COLOR_4="#d33682"                # Magenta
        COLOR_5="#6c71c4"                # Violeta
        COLOR_6="#268bd2"                # Azul
        COLOR_7="#859900"                # Verde
        COLOR_8="#2aa198"                # Ciano

        # Versões mais claras (tints)
        COLOR_9="#f0c674"          # Amarelo claro
        COLOR_10="#ff9d5c"          # Laranja claro
        COLOR_11="#ff6b55"          # Vermelho claro
        COLOR_12="#ff7cb8"          # Magenta claro
        COLOR_13="#9a9ee8"          # Violeta claro
        COLOR_14="#62b3e2"          # Azul claro
        COLOR_15="#a3d572"          # Verde claro
        COLOR_16="#69d9cf"          # Ciano claro
    ;;
    $solarized_light)
        THEME_GTK="NumixSolarizedLightCyan"
        THEME_ICON="Numix-Circle-Light"
        THEME_MODE="Solarized"
        COLOR_MODE="Light"
        GTK_PREFER_DARK_MODE=0
        EMACS_THEME="doom-solarized-light"
        WALLPAPER_LIGHTDM="burst-light.png"

        # Cores base (originais)
        COLOR_BACKGROUND="#eee8d5"       # Fundo principal (bege claro)
        COLOR_BACKGROUND2="#eee8d5"      # Fundo secundário (bege médio)
        COLOR_TEXT="#657b83"             # Texto principal (cinza-azulado escuro)

        # Cores acentuadas originais (1-8)
        COLOR_1="#b58900"                # Amarelo
        COLOR_2="#cb4b16"                # Laranja
        COLOR_3="#dc322f"                # Vermelho
        COLOR_4="#d33682"                # Magenta
        COLOR_5="#6c71c4"                # Violeta
        COLOR_6="#268bd2"                # Azul
        COLOR_7="#859900"                # Verde
        COLOR_8="#2aa198"                # Ciano

        # Versões mais escuras (9-16)
        COLOR_9="#9a7b00"          # Amarelo escuro
        COLOR_10="#a83c0f"         # Laranja escuro
        COLOR_11="#b8221f"         # Vermelho escuro
        COLOR_12="#a92b68"         # Magenta escuro
        COLOR_13="#555ab7"         # Violeta escuro
        COLOR_14="#1a73b8"         # Azul escuro
        COLOR_15="#6a7d00"         # Verde escuro
        COLOR_16="#1f8881"         # Ciano escuro
    ;;
    $gruvbox_dark)

        THEME_GTK="Gruvbox-Material-Dark"
        THEME_ICON="Numix-Circle"
        THEME_MODE="Gruvbox"
        COLOR_MODE="Dark"
        GTK_PREFER_DARK_MODE=1
        EMACS_THEME="doom-gruvbox"
        WALLPAPER_LIGHTDM="wallhaven-jxl8mw.jpg"

        # Cores base (originais)
        COLOR_BACKGROUND="#282828"       # Fundo principal (cinza muito escuro)
        COLOR_BACKGROUND2="#3c3836"      # Fundo secundário (cinza escuro)
        COLOR_TEXT="#ebdbb2"             # Texto principal (bege claro)

        # Cores acentuadas originais (1-8)
        COLOR_1="#d79921"                # Amarelo
        COLOR_2="#fe8019"                # Laranja
        COLOR_3="#fb4934"                # Vermelho
        COLOR_4="#d3869b"                # Magenta
        COLOR_5="#83a598"                # Azul
        COLOR_6="#8ec07c"                # Verde-água/Ciano
        COLOR_7="#b8bb26"                # Verde
        COLOR_8="#928374"                # Cinza

        # Versões mais claras (9-16)
        COLOR_9="#f2c76e"          # Amarelo claro
        COLOR_10="#ffa347"         # Laranja claro
        COLOR_11="#ff6e5a"         # Vermelho claro
        COLOR_12="#e9aec5"         # Magenta claro
        COLOR_13="#a7c7d4"         # Azul claro
        COLOR_14="#b0d9a1"         # Verde-água claro
        COLOR_15="#d5d85c"         # Verde claro
        COLOR_16="#b5aa99"         # Cinza claro
    ;;
    $gruvbox_light)

        THEME_GTK="Gruvbox-Plus-Light"
        THEME_ICON="Numix-Circle-Light"
        THEME_MODE="Gruvbox"
        COLOR_MODE="Light"
        GTK_PREFER_DARK_MODE=0
        EMACS_THEME="doom-gruvbox-light"
        WALLPAPER_LIGHTDM="gruv-takumi-drift.png"

        # Cores base (originais)
        COLOR_BACKGROUND="#fbf1c7"       # Fundo principal (bege claro)
        COLOR_BACKGROUND2="#ebdbb2"      # Fundo secundário (bege médio)
        COLOR_TEXT="#3c3836"             # Texto principal (cinza escuro)

        # Cores acentuadas originais (1-8)
        COLOR_1="#b57614"                # Amarelo
        COLOR_2="#af3a03"                # Laranja
        COLOR_3="#9d0006"                # Vermelho
        COLOR_4="#8f3f71"                # Magenta
        COLOR_5="#076678"                # Azul
        COLOR_6="#427b58"                # Verde-água/Ciano
        COLOR_7="#79740e"                # Verde
        COLOR_8="#928374"                # Cinza

        # Versões mais escuras (9-16)
        COLOR_9="#8a5a0a"          # Amarelo escuro
        COLOR_10="#7a2900"         # Laranja escuro
        COLOR_11="#6d0000"         # Vermelho escuro
        COLOR_12="#6a2f55"         # Magenta escuro
        COLOR_13="#05404d"         # Azul escuro
        COLOR_14="#2d5a3e"         # Verde-água escuro
        COLOR_15="#56520a"         # Verde escuro
        COLOR_16="#6c5d4e"         # Cinza escuro
    ;;
    $catppuccin_dark)

        THEME_GTK="Catppuccin-Frappe-Standard-Pink-Dark"
        THEME_ICON="Numix-Circle"
        THEME_MODE="Catppuccin"
        COLOR_MODE="Dark"
        GTK_PREFER_DARK_MODE=1
        EMACS_THEME='catppuccin) (setq catppuccin-flavor '"'"'frappe'
        WALLPAPER_LIGHTDM="CatppuccinMocha-Planets.png"

        # Cores base (originais)
        COLOR_BACKGROUND="#303446"       # Fundo principal (azul-escuro)
        COLOR_BACKGROUND2="#414559"      # Fundo secundário (azul médio)
        COLOR_TEXT="#c6d0f5"             # Texto principal (branco-azulado)

        # Cores acentuadas originais (1-8)
        COLOR_1="#e5c890"                # Amarelo
        COLOR_2="#ef9f76"                # Laranja
        COLOR_3="#e78284"                # Vermelho
        COLOR_4="#ca9ee6"                # Magenta
        COLOR_5="#8caaee"                # Azul
        COLOR_6="#81c8be"                # Verde-água/Ciano
        COLOR_7="#a6d189"                # Verde
        COLOR_8="#b5bfe2"                # Cinza

        # Versões mais claras (9-16)
        COLOR_9="#f5e0b8"          # Amarelo claro (brilho aumentado)
        COLOR_10="#ffb896"         # Laranja claro
        COLOR_11="#ffa2a4"         # Vermelho claro
        COLOR_12="#e2b5f2"         # Magenta claro
        COLOR_13="#a8c7ff"         # Azul claro
        COLOR_14="#a3e0d6"         # Verde-água claro
        COLOR_15="#c5e8b1"         # Verde claro
        COLOR_16="#d5def5"         # Cinza claro (quase branco-azulado)
    ;;
    $catppuccin_light)

        THEME_GTK="Catppuccin-Latte-Standard-Sapphire-Light"
        THEME_ICON="Numix-Circle-Light"
        THEME_MODE="Catppuccin"
        COLOR_MODE="Light"
        GTK_PREFER_DARK_MODE=0
        EMACS_THEME='catppuccin) (setq catppuccin-flavor '"'"'latte'
        WALLPAPER_LIGHTDM="wp11912478-catppuccin-wallpapers.png"

        # Cores base (originais)
        COLOR_BACKGROUND="#eff1f5"       # Fundo principal (branco-azulado)
        COLOR_BACKGROUND2="#ccd0da"      # Fundo secundário (cinza-azulado claro)
        COLOR_TEXT="#4c4f69"             # Texto principal (cinza-azulado escuro)

        # Cores acentuadas originais (1-8)
        COLOR_1="#df8e1d"                # Amarelo
        COLOR_2="#ea76cb"                # Rosa
        COLOR_3="#d20f39"                # Vermelho
        COLOR_4="#8839ef"                # Magenta
        COLOR_5="#1e66f5"                # Azul
        COLOR_6="#04a5e5"                # Verde-água/Ciano
        COLOR_7="#40a02b"                # Verde
        COLOR_8="#7287fd"                # Violeta

        # Versões mais escuras (9-16)
        COLOR_9="#b67416"          # Amarelo escuro
        COLOR_10="#c05fb0"         # Rosa escuro
        COLOR_11="#a00c2d"         # Vermelho escuro
        COLOR_12="#6c2bc9"         # Magenta escuro
        COLOR_13="#174fc9"         # Azul escuro
        COLOR_14="#0384b8"         # Verde-água escuro
        COLOR_15="#2d7d22"         # Verde escuro
        COLOR_16="#5a6be8"         # Violeta escuro
    ;;
    $nordic_dark)

        THEME_GTK="Nordic-darker-v40"
        THEME_ICON="Zafiro-Nord-Black"
        THEME_MODE="Nord"
        COLOR_MODE="Dark"
        GTK_PREFER_DARK_MODE=1
        EMACS_THEME="doom-nord"
        WALLPAPER_LIGHTDM="ign_unsplash15.png"

        # Cores base (originais)
        COLOR_BACKGROUND="#2e3440"       # Fundo principal (azul-escuro)
        COLOR_BACKGROUND2="#3b4252"      # Fundo secundário (azul-cinza)
        COLOR_TEXT="#d8dee9"             # Texto principal (branco-azulado)

        # Cores acentuadas originais (1-8)
        COLOR_1="#ebcb8b"                # Amarelo
        COLOR_2="#d08770"                # Laranja
        COLOR_3="#bf616a"                # Vermelho
        COLOR_4="#b48ead"                # Magenta
        COLOR_5="#81a1c1"                # Azul
        COLOR_6="#88c0d0"                # Verde-água/Ciano
        COLOR_7="#a3be8c"                # Verde
        COLOR_8="#4c566a"                # Cinza

        # Versões mais claras (9-16)
        COLOR_9="#f5e5bc"          # Amarelo claro (brilho aumentado)
        COLOR_10="#e5a28a"         # Laranja claro
        COLOR_11="#d97782"         # Vermelho claro
        COLOR_12="#c9a5c7"         # Magenta claro
        COLOR_13="#a8c7e0"         # Azul claro
        COLOR_14="#a0d5e0"         # Verde-água claro
        COLOR_15="#c3d8b1"         # Verde claro
        COLOR_16="#6d798c"         # Cinza claro
    ;;
    $nordic_light)

        THEME_GTK="Nordic-Polar-v40"
        THEME_ICON="Numix-Circle-Light"
        THEME_MODE="Nord"
        COLOR_MODE="Light"
        GTK_PREFER_DARK_MODE=0
        EMACS_THEME="doom-nord-light"
        WALLPAPER_LIGHTDM="ign_sunAndClouds.png"

        # Cores base (originais)
        COLOR_BACKGROUND="#eceff4"       # Fundo principal (branco-azulado)
        COLOR_BACKGROUND2="#e5e9f0"      # Fundo secundário (branco-azulado mais escuro)
        COLOR_TEXT="#2e3440"             # Texto principal (azul-escuro)

        # Cores acentuadas originais (1-8)
        COLOR_1="#b48ead"                # Lilás (Yellow no Nord Light é normalmente #ebcb8b)
        COLOR_2="#d08770"                # Laranja
        COLOR_3="#bf616a"                # Vermelho
        COLOR_4="#5e81ac"                # Azul (Magenta no Nord Light é normalmente #b48ead)
        COLOR_5="#81a1c1"                # Azul-claro
        COLOR_6="#88c0d0"                # Verde-água/Ciano
        COLOR_7="#a3be8c"                # Verde
        COLOR_8="#4c566a"                # Cinza

        # Versões mais escuras (9-16)
        COLOR_9="#8a6d8b"          # Lilás escuro
        COLOR_10="#a56a53"         # Laranja escuro
        COLOR_11="#8f4a54"         # Vermelho escuro
        COLOR_12="#4a6685"         # Azul escuro
        COLOR_13="#5e7b9b"         # Azul-claro escuro
        COLOR_14="#5d929f"         # Verde-água escuro
        COLOR_15="#7a9668"         # Verde escuro
        COLOR_16="#3b4252"         # Cinza escuro (cor de fundo do Nord Dark)
	;;

    $dracula_dark)

        THEME_GTK="Dracula"
        THEME_ICON="Numix-Circle"
        THEME_MODE="Dracula"
        COLOR_MODE="Dark"
        GTK_PREFER_DARK_MODE=1
        EMACS_THEME="doom-dracula"
        WALLPAPER_LIGHTDM="base.png"

        # Cores base (originais)
        COLOR_BACKGROUND="#282a36"       # Fundo principal (roxo-escuro)
        COLOR_BACKGROUND2="#343746"      # Fundo secundário (slightly lighter)
        COLOR_TEXT="#f8f8f2"             # Texto principal (branco-creme)

        # Cores acentuadas originais (1-8)
        COLOR_1="#f1fa8c"                # Amarelo
        COLOR_2="#ffb86c"                # Laranja
        COLOR_3="#ff5555"                # Vermelho
        COLOR_4="#ff79c6"                # Magenta
        COLOR_5="#bd93f9"                # Roxo/Azul
        COLOR_6="#8be9fd"                # Ciano
        COLOR_7="#50fa7b"                # Verde
        COLOR_8="#6272a4"                # Cinza

        # Versões mais claras (9-16)
        COLOR_9="#f8ffb8"          # Amarelo claro (mais brilhante)
        COLOR_10="#ffd4a2"         # Laranja claro
        COLOR_11="#ff8888"         # Vermelho claro
        COLOR_12="#ffa6da"         # Magenta claro
        COLOR_13="#d9b8ff"         # Roxo claro
        COLOR_14="#b1f1ff"         # Ciano claro
        COLOR_15="#8affa6"         # Verde claro
        COLOR_16="#8a9acf"         # Cinza claro
    ;;
    $dracula_light)

        THEME_GTK="Yaru-Pink-light"
        THEME_ICON="Numix-Circle-Light"
        THEME_MODE="Dracula"
        COLOR_MODE="Light"
        GTK_PREFER_DARK_MODE=0
        EMACS_THEME="doom-one-light"
        WALLPAPER_LIGHTDM="dracula-galaxy-6272a4.png"


        # Cores base (originais)
        COLOR_BACKGROUND="#f8f8f2"       # Fundo principal (branco-creme)
        COLOR_BACKGROUND2="#e8e8e3"      # Fundo secundário (cinza-claro)
        COLOR_TEXT="#44475a"             # Texto principal (roxo-escuro)

        # Cores acentuadas originais (1-8)
        COLOR_1="#f1fa8c"                # Amarelo
        COLOR_2="#ffb86c"                # Laranja
        COLOR_3="#ff5555"                # Vermelho
        COLOR_4="#ff79c6"                # Magenta
        COLOR_5="#bd93f9"                # Roxo/Azul
        COLOR_6="#8be9fd"                # Ciano
        COLOR_7="#50fa7b"                # Verde
        COLOR_8="#6272a4"                # Cinza

        # Versões mais escuras (9-16)
        COLOR_9="#c8d45e"          # Amarelo escuro
        COLOR_10="#d99448"         # Laranja escuro
        COLOR_11="#cc3333"         # Vermelho escuro
        COLOR_12="#d95aa8"         # Magenta escuro
        COLOR_13="#9a72d6"         # Roxo escuro
        COLOR_14="#5cb8cc"         # Ciano escuro
        COLOR_15="#3ac55a"         # Verde escuro
        COLOR_16="#4a5679"         # Cinza escuro
	;;
    $vaporwave_dark)

        THEME_GTK="retrowave-glow"
        THEME_ICON="candy-icons"
        THEME_MODE="Vaporwave"
        COLOR_MODE="Dark"
        GTK_PREFER_DARK_MODE=1
        EMACS_THEME="rebecca"
        WALLPAPER_LIGHTDM="vaporwave005.jpg"

        # Cores base (originais)
        COLOR_BACKGROUND="#2e1a47"       # Fundo principal (roxo profundo)
        COLOR_BACKGROUND2="#3a2257"      # Fundo secundário (roxo médio)
        COLOR_TEXT="#d8d8d8"             # Texto principal (cinza claro)

        # Cores acentuadas originais (1-8)
        COLOR_1="#ff77ff"                # Rosa neon
        COLOR_2="#9c64e8"                # Roxo vibrante
        COLOR_3="#ff6c6c"                # Vermelho claro
        COLOR_4="#ff5a8f"                # Magenta
        COLOR_5="#7ec8ff"                # Azul claro
        COLOR_6="#84e1f2"                # Ciano
        COLOR_7="#76ff7f"                # Verde ácido
        COLOR_8="#b8a4c9"                # Cinza lilás

        # Versões mais claras (9-16)
        COLOR_9="#ffa3ff"          # Rosa neon claro (mais brilhante)
        COLOR_10="#b88aff"         # Roxo claro eletrico
        COLOR_11="#ff9c9c"         # Vermelho pastel
        COLOR_12="#ff8db3"         # Magenta claro
        COLOR_13="#a8dfff"         # Azul céu
        COLOR_14="#a3edff"         # Ciano brilhante
        COLOR_15="#9dffa3"         # Verde menta
        COLOR_16="#d8cce5"         # Cinza-perolizado
    ;;
    $vaporwave_light)


        THEME_GTK="Lavanda-Light"
        THEME_ICON="Numix-Circle-Light"
        THEME_MODE="Vaporwave"
        COLOR_MODE="Light"
        GTK_PREFER_DARK_MODE=0
        EMACS_THEME="rebecca"
        WALLPAPER_LIGHTDM="vaporwave009.jpg"

        # Cores base (originais)
        COLOR_BACKGROUND="#f8f2ff"       # Fundo principal (lavanda)
        COLOR_BACKGROUND2="#f8f2ff"      # Fundo secundário (roxo-pastel)
        COLOR_TEXT="#2e1a47"             # Texto principal (roxo-escuro)

        # Cores acentuadas originais (1-8)
        COLOR_1="#FF77FF"                # Rosa néon
        COLOR_2="#8A2BE2"                # Roxo-violeta
        COLOR_3="#FFD700"                # Dourado (no lugar do Light Red)
        COLOR_4="#FF6F61"                # Coral
        COLOR_5="#153CB4"                # Azul-elétrico
        COLOR_6="#00BFFF"                # Ciano
        COLOR_7="#00FA9A"                # Verde-mint
        COLOR_8="#F0E68C"                # Amarelo-claro

        # Versões mais escuras (9-16)
        COLOR_9="#D95FD9"          # Rosa profundo
        COLOR_10="#6A1FC1"         # Roxo intenso
        COLOR_11="#CCAC00"         # Dourado escuro
        COLOR_12="#D84F3F"         # Coral escuro
        COLOR_13="#0E2B8C"         # Azul marinho
        COLOR_14="#0099CC"         # Ciano escuro
        COLOR_15="#00C97A"         # Verde-água escuro
        COLOR_16="#C9C160"         # Amarelo-terroso

	;;

    *)
        exit 0
    ;;
esac

if [[ -z $1 ]]; then
    exit 0
else
    # Arquivo variavel
    rm -rf ~/.theme_selected
    cat > ~/.theme_selected << EOF
#!/bin/bash
THEME_GTK="$THEME_GTK"
THEME_ICON="$THEME_ICON"
THEME_MODE="$THEME_MODE"
COLOR_MODE="$COLOR_MODE"
COLOR_BACKGROUND="$COLOR_BACKGROUND"
COLOR_BACKGROUND2="$COLOR_BACKGROUND2"
COLOR_TEXT="$COLOR_TEXT"
COLOR_1="$COLOR_1"     # Pink
COLOR_2="$COLOR_2"     # Purple
COLOR_3="$COLOR_3"     # Light Red
COLOR_4="$COLOR_4"     # Magenta
COLOR_5="$COLOR_5"     # Light Blue
COLOR_6="$COLOR_6"     # Cyan
COLOR_7="$COLOR_7"     # Light Green
COLOR_8="$COLOR_8"     # Light Gray
COLOR_9="$COLOR_9"     # Pink
COLOR_10="$COLOR_10"   # Purple
COLOR_11="$COLOR_11"   # Light Red
COLOR_12="$COLOR_12"   # Magenta
COLOR_13="$COLOR_13"   # Light Blue
COLOR_14="$COLOR_14"   # Cyan
COLOR_15="$COLOR_15"   # Light Green
COLOR_16="$COLOR_16"   # Light Gray
EOF

    # Altero as configuracoes do gtk
    # GTK2
    sed -i "s/^gtk-icon-theme-name =.*/gtk-icon-theme-name = \"$THEME_ICON\"/" ~/.config/gtk-2.0/gtkrc
    sed -i "s/^gtk-theme-name =.*/gtk-theme-name = \"$THEME_GTK\"/" ~/.config/gtk-2.0/gtkrc

    sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=\"$THEME_ICON\"/" ~/.gtkrc-2.0
    sed -i "s/^gtk-theme-name=.*/gtk-theme-name=\"$THEME_GTK\"/" ~/.gtkrc-2.0

    # GTK3
    sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$THEME_GTK/" ~/.config/gtk-3.0/settings.ini
    sed -i "s/^gtk-icon-theme-name=.*/gtk-icon-theme-name=$THEME_ICON/" ~/.config/gtk-3.0/settings.ini
    sed -i "s/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=$GTK_PREFER_DARK_MODE/" ~/.config/gtk-3.0/settings.ini

    #Flatpak
    SUDO_ASKPASS=/usr/bin/ssh-askpsas sudo flatpak override --filesystem=$HOME/.themes
    SUDO_ASKPASS="$sudo_askpass" sudo flatpak override --env=GTK_THEME=$THEME_GTK

    # Suckless
    sed -i "s|^#include \"themes/.*|#include \"themes/${THEME_MODE,,}_${COLOR_MODE,,}.h\"|" ~/.config/suckless/dwm/config.def.h
    sed -i "s|^#include \"themes/.*|#include \"themes/${THEME_MODE,,}_${COLOR_MODE,,}.h\"|" ~/.config/suckless/st/config.def.h
    sed -i "s|^#include \"themes/.*|#include \"themes/${THEME_MODE,,}_${COLOR_MODE,,}.h\"|" ~/.config/suckless/dmenu/config.def.h
    sed -i "s|^#include \"themes/.*|#include \"themes/${THEME_MODE,,}_${COLOR_MODE,,}.h\"|" ~/.config/suckless/slock/config.def.h

    # Emacs Doom
    sed -i "s|(setq doom-theme .*)|(setq doom-theme '$EMACS_THEME)|" ~/.config/doom/config.el

    # Btop
    sed -i "s|^color_theme =.*|color_theme = \"${THEME_MODE,,}_${COLOR_MODE,,}\"|" ~/.config/btop/btop.conf

    # Lightdm
    SUDO_ASKPASS=/usr/bin/ssh-askpsas sudo cp -r ~/.icons/$THEME_ICON /usr/share/icons/
    SUDO_ASKPASS=/usr/bin/ssh-askpsas sudo cp -r ~/.themes/$THEME_GTK /usr/share/themes/

    # Copia o wallpaper para ser usado pelo o slock e lightdm
    if [ "$pywal_flag" = "1"  ]; then
        SUDO_ASKPASS=/usr/bin/ssh-askpsas sudo cp -r $pywal_wallpaper /usr/share/images/desktop-base/$WALLPAPER_LIGHTDM
    else
        SUDO_ASKPASS=/usr/bin/ssh-askpsas sudo cp -r ~/.wallpapers/$THEME_MODE/$COLOR_MODE/$WALLPAPER_LIGHTDM /usr/share/images/desktop-base/$WALLPAPER_LIGHTDM
    fi

    SUDO_ASKPASS=/usr/bin/ssh-askpsas sudo rm /etc/lightdm/lightdm-gtk-greeter.conf

    SUDO_ASKPASS=/usr/bin/ssh-askpsas sudo bash -c "cat > /etc/lightdm/lightdm-gtk-greeter.conf << EOF
[greeter]
background=/usr/share/images/desktop-base/$WALLPAPER_LIGHTDM
theme-name=$THEME_GTK
cursor-theme-name=capitaine-cursors-gruvbox-white
icon-theme-name=$THEME_ICON
default-user-image=/var/lib/AccountsService/icons/default.png
indicators=~a11y;~language;~spacer;~host;~clock;~spacer;~session;~power;
EOF"

    # Slock
    SUDO_ASKPASS=/usr/bin/ssh-askpsas sudo rm -rf /usr/share/images/desktop-base/wallpaper-slock
    SUDO_ASKPASS=/usr/bin/ssh-askpsas sudo ln -s /usr/share/images/desktop-base/$WALLPAPER_LIGHTDM /usr/share/images/desktop-base/wallpaper-slock

   # Abre o dunst com o tema certo
    source $HOME/.theme_selected
    killall dunst
    dunst -conf "$HOME/.config/dunst/themes/${THEME_MODE}_${COLOR_MODE}" &
    dunstify "Aplicando tema" "Aguarde.." -h int:value:10  -i /usr/share/icons/ePapirus/16x16/status/package-reinstall.svg

    # Fecha programas systray
    killall copyq
    killall solaar
    killall slock

    # Compila dwm
    cd $HOME/.config/suckless/dwm
    rm config.h
    make
    SUDO_ASKPASS="$sudo_askpass" sudo make clean install

    dunstify "Aplicando tema" "Aguarde.." -h int:value:40 -i /usr/share/icons/ePapirus/16x16/status/package-reinstall.svg

    # Compila st
    cd $HOME/.config/suckless/st
    rm config.h
    make
    SUDO_ASKPASS="$sudo_askpass" sudo make clean install

    dunstify "Aplicando tema" "Aguarde.." -h int:value:60 -i /usr/share/icons/ePapirus/16x16/status/package-reinstall.svg

    # Compila dmenu
    cd $HOME/.config/suckless/dmenu
    rm config.h
    make
    SUDO_ASKPASS="$sudo_askpass" sudo make clean install

    # Compila slock
    cd $HOME/.config/suckless/slock
    rm config.h
    make
    SUDO_ASKPASS="$sudo_askpass" sudo make clean install

    dunstify "Aplicando tema" "Aguarde.." -h int:value:80 -i /usr/share/icons/ePapirus/16x16/status/package-reinstall.svg
    sleep 0.8
    # Faz sincronizacao do doom
    #$HOME/.config/emacs/bin/doom sync

    dunstify "Aplicando tema" "Aguarde.." -h int:value:99 -i /usr/share/icons/ePapirus/16x16/status/package-reinstall.svg

    # Aplica wallpaper aleatorio para o tema selecionado
    if [ "$pywal_flag" = "0" ]; then
        feh --recursive --bg-fill --randomize $(find ~/.wallpapers/${THEME_MODE}/${COLOR_MODE}/ -type f \( -iname \*.jpg -o -iname \*.png -o -iname \*.jpeg \) | shuf -n 1) &
    fi
    # Restart dwm
    xdotool key Super_L+r
    kill -10 $(pidof dwmblocks)
    dunstify "Pronto" "Aplicação do tema finalizado!!!" -h int:value:100 -i /usr/share/icons/ePapirus/16x16/status/package-install.svg
fi
