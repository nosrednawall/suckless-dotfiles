#!/usr/bin/env sh

# convert-themes.sh - Converte arquivos .h para formato temas.conf

THEMES_DIR="$HOME/.config/suckless/src/dwm/themes"
CONFIG_FILE="$HOME/.config/suckless/scripts/themes/temas.conf"

for theme_file in "$THEMES_DIR"/*.h; do
    theme_name=$(basename "$theme_file" .h | sed 's/_/ /g' | sed 's/\b\(.\)/\u\1/g')

    echo "[$theme_name]" >> "$CONFIG_FILE.tmp"

    # Extrai todas as cores do arquivo .h
    grep -E '^static char.*\[\] = ' "$theme_file" | \
        sed 's/static char //' | \
        sed 's/\[\] = / = /' | \
        sed 's/;//' | \
        sed 's/^[ \t]*//' >> "$CONFIG_FILE.tmp"

    echo "" >> "$CONFIG_FILE.tmp"
done

mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
echo "✅ Temas convertidos para $CONFIG_FILE"
