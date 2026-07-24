#!/usr/bin/env sh
msg() { echo -e "${CYAN}$*${NC}"; }
CONFIG_DIR="$HOME/.config/suckless"

# Create Symlinks of configs
msg "Re-Stow configuration..."
stow -d "$CONFIG_DIR/config" -t "$HOME/.config" .
stow -d "$CONFIG_DIR/fonts" -t "$HOME/.fonts" .
stow -d "$CONFIG_DIR/home" -t "$HOME" .
stow -d "$CONFIG_DIR/icons" -t "$HOME/.icons" .
stow -d "$CONFIG_DIR/scripts" -t "$HOME/.local/bin/scripts" .
stow -d "$CONFIG_DIR/sounds" -t "$HOME/.local/share/sounds" .
stow -d "$CONFIG_DIR/src" -t "$HOME/.local/src" .
stow -d "$CONFIG_DIR/themes" -t "$HOME/.themes" .
stow -d "$CONFIG_DIR/wallpapers" -t "$HOME/.wallpapers" .
