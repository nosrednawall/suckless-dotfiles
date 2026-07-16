#!/usr/bin/env bash

# Script para gerenciar temas facilmente

CONFIG_FILE="$HOME/.config/suckless/scripts/themes/temas.conf"

# Função para listar temas
list_themes() {
    echo "Temas disponíveis:"
    echo "=================="
    echo ""
    
    echo "Dark :"
    grep -A1 "^\[.*\]$" "$CONFIG_FILE" | grep -B1 "color_mode = Dark" | grep "^\[" | sed 's/[][]//g' | sed 's/^/  - /'
    
    echo ""
    echo "Light :"
    grep -A1 "^\[.*\]$" "$CONFIG_FILE" | grep -B1 "color_mode = Light" | grep "^\[" | sed 's/[][]//g' | sed 's/^/  - /'
}

# Função para mostrar informações de um tema
show_theme() {
    local theme="$1"
    
    if ! grep -q "^\[$theme\]$" "$CONFIG_FILE"; then
        echo "Tema não encontrado: $theme"
        return 1
    fi
    
    echo "Informações do tema: $theme"
    echo "========================"
    
    awk -v theme="[$theme]" '
        $0 == theme { found=1 }
        found && $1 ~ /^[a-z_]+$/ && $2 == "=" {
            gsub(/^[ \t]+/, "", $3)
            printf "  %-20s = %s\n", $1, $3
        }
        found && /^\[/ && $0 != theme { exit }
    ' "$CONFIG_FILE"
}

# Função para adicionar novo tema (interativo)
add_theme() {
    echo "Adicionar novo tema"
    echo "=================="
    
    read -p "Nome do tema: " theme_name
    
    if grep -q "^\[$theme_name\]$" "$CONFIG_FILE"; then
        echo "Erro: Tema já existe!"
        return 1
    fi
    
    echo ""
    echo "Agora vamos configurar o tema..."
    echo ""
    
    read -p "Theme GTK: " theme_gtk
    read -p "Theme Icon: " theme_icon
    read -p "Theme Mode: " theme_mode
    read -p "Color Mode (Dark/Light): " color_mode
    read -p "GTK Prefer Dark (0/1): " gtk_prefer
    read -p "Emacs Theme: " emacs_theme
    read -p "Wallpaper: " wallpaper
    
    echo ""
    echo "Cores base:"
    read -p "Background: " background
    read -p "Background2: " background2
    read -p "Text: " text
    
    echo ""
    echo "Cores principais (1-8):"
    for i in {1..8}; do
        read -p "color$i: " color
        eval "color$i=$color"
    done
    
    echo ""
    echo "Cores secundárias (9-16):"
    for i in {9..16}; do
        read -p "color$i: " color
        eval "color$i=$color"
    done
    
    # Adiciona ao arquivo
    cat >> "$CONFIG_FILE" << EOF

[$theme_name]
theme_gtk = $theme_gtk
theme_icon = $theme_icon
theme_mode = $theme_mode
color_mode = $color_mode
gtk_prefer_dark = $gtk_prefer
emacs_theme = $emacs_theme
wallpaper = $wallpaper

background = $background
background2 = $background2
text = $text

color1 = $color1
color2 = $color2
color3 = $color3
color4 = $color4
color5 = $color5
color6 = $color6
color7 = $color7
color8 = $color8

color9 = $color9
color10 = $color10
color11 = $color11
color12 = $color12
color13 = $color13
color14 = $color14
color15 = $color15
color16 = $color16

EOF
    
    echo "Tema '$theme_name' adicionado com sucesso!"
}

# Menu principal
case "$1" in
    list)
        list_themes
        ;;
    show)
        show_theme "$2"
        ;;
    add)
        add_theme
        ;;
    *)
        echo "Uso: $0 {list|show <tema>|add}"
        echo ""
        echo "Comandos:"
        echo "  list           - Lista todos os temas"
        echo "  show <tema>    - Mostra detalhes de um tema"
        echo "  add            - Adiciona um novo tema (interativo)"
        ;;
esac
