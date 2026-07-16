#!/usr/bin/env bash

# Configurações
CONFIG_FILE="$HOME/.config/suckless/scripts/themes/temas.conf"
TEMA_APPLY_SCRIPT="$HOME/.config/suckless/scripts/themes/temas-aplicar.sh"

# Função para listar temas por modo
list_themes_by_mode() {
    local mode="$1"  # Dark ou Light

    awk -v mode="$mode" '
        /^\[.+\]$/ { theme = substr($0, 2, length($0)-2) }
        /color_mode = / && $3 == mode { print "  " theme }
    ' "$CONFIG_FILE" | sort
}

# Gera lista de temas disponíveis
generate_theme_list() {
    echo "Pywal:"
    echo "  Wallpaper Atual Dark"
    echo "  Wallpaper Aleatório Dark"
    echo "  Wallpaper Atual Light"
    echo "  Wallpaper Aleatório Light"
    echo ""
    echo "Dark :"
    list_themes_by_mode "Dark"
    echo ""
    echo "Light :"
    list_themes_by_mode "Light"
}

# Apresenta Dmenu com as opções
chosen="$(generate_theme_list | dmenu -p "Tema menu " -l 25 -i)"

# Verifica se escolheu alguma opção
if [[ -z "$chosen" ]]; then
    exit 0
fi

# Remove espaços do início
chosen_clean=$(echo "$chosen" | sed 's/^[[:space:]]*//')

# Notifica início
dunstify "Aplicando tema" "Iniciando aplicação do tema..." \
    -h int:value:10 \
    -i /usr/share/icons/ePapirus/16x16/status/package-reinstall.svg

# Envia a escolha ao script
"$TEMA_APPLY_SCRIPT" "$chosen_clean"
