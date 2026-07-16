#!/usr/bin/env bash

# Função para ler um recurso do Xresources
get_xres_value() {
    xrdb -query | grep "$1" | awk '{print $2}'
}

# Ler as cores do Xresources
foreground=$(get_xres_value "dwmblocks.foreground")
background=$(get_xres_value "dwmblocks.background")

# Definir cores padrão caso não sejam encontradas no Xresources
foreground=${foreground:-#ffffff}
background=${background:-#000000}

# Exportar as cores para que possam ser usadas em outros scripts
export FOREGROUND_COLOR=$foreground
export BACKGROUND_COLOR=$background
echo "$foreground $background"
