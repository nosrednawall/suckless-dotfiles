#!/bin/bash

# Nosrednawall - My Personal DWM Setup
# https://github.com/nosrednawall/suckless-dotfiles

set -e

# Command line options
ONLY_CONFIG=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --only-config)
            ONLY_CONFIG=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo "  --only-config      Only copy config files (skip packages and external tools)"
            echo "  --help            Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/suckless"
TEMP_DIR="/tmp/dwm_$$"
LOG_FILE="$HOME/dwm-install.log"

# Logging and cleanup
exec > >(tee -a "$LOG_FILE") 2>&1
trap "rm -rf $TEMP_DIR" EXIT

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

die() { echo -e "${RED}ERROR: $*${NC}" >&2; exit 1; }
warn() { echo -e "${YELLOW}WARNING: $*${NC}" >&2; }
msg() { echo -e "${CYAN}$*${NC}"; }


# Banner
clear
echo -e "${CYAN}"
echo " +-+-+-+-+-+-+-+-+-+-+-+-+-+ "
echo " |N|O|S|R|E|D|N|A|W|A|L|L| | "
echo " +-+-+-+-+-+-+-+-+-+-+-+-+-+ "
echo " |d|w|m| |s|e|t|u|p|        | "
echo " +-+-+-+-+-+-+-+-+-+-+-+-+-+ "
echo -e "${NC}\n"

read -p "Install DWM? (y/n) " -n 1 -r
echo
[[ ! $REPLY =~ ^[Yy]$ ]] && exit 1

# Update system
if [ "$ONLY_CONFIG" = false ]; then
    msg "Updating system..."
    sudo pacman -Syuv

else
    msg "Skipping system update (--only-config mode)"
fi

# Package groups for better organization
PACKAGES_BUILD=(
    base-devel
)

PACKAGES_DEPENDENCIES_DWM=(
    libxinerama libxft libxcb libxext imlib2
)

PACKAGES_DEPENDENCIES_ST=(
    libconfig libxft harfbuzz imlib2 libxcursor freetype2 pkgconf
)

PACKAGES_DEPENDENCIES_DMENU=(
    libxinerama libxft
)

PACKAGES_DEPENDENCIES_SLOCK=(
    libx11 libxcrypt libxext libxrandr libxinerama imlib2
    libxcb libxft libxrender freetype2 xcb-proto libxcb
    libxau libxdmcp zlib libpng
)

PACKAGES_DEPENDENCIES_DWMBLOCKS=(
    xcb-util libxau libxdmcp
)

PACKAGES_DEPENDENCIES_NSXIV=(
    libexif
)

PACKAGES_DEPENDENCIES_WALRS=(
    cargo-make
)


PACKAGES_CORE=(
    xorg-server xorg-xsetroot xorg-xinit stow pacman-contrib
)

PACKAGES_FONTS=(
    ttf-nerd-fonts-symbols ttf-iosevkaterm-nerd
)

PACKAGES_TERMINAL=(
    curl pv htop btop xdotool libnotify ripgrep fd findutils
    calcurse python-oauth2client python-httplib2 pulsemixer
    less newsboat jq bc gd ueberzugpp xclip
)

PACKAGES_SYSTEM=(
    ly avahi flatpak
)

PACKAGES_DESKTOP_ENVIROMENT=(
    polkit lxsession xsettingsd xdg-user-dirs xdg-user-dirs-gtk
)

PACKAGES_UI=(
    dunst feh networkmanager network-manager-applet copyq picom
    rofi
)

PACKAGES_SECURITY=(
    gnupg pinentry bitwarden pass qtpass x11-ssh-askpass
)

PACKAGES_BROWSERS=(
    firefox firefox-i18n-pt-br firefoxpwa
)

PACKAGES_OFFICE=(
    libreoffice-fresh libreoffice-fresh-pt-br aspell-pt atril
    xournalpp qalculate-gtk gthumb thunderbird thunderbird-i18n-pt-br
)

PACKAGES_FILE_MANAGER=(
    thunar ranger thunar-archive-plugin thunar-media-tags-plugin
    udisks2 smbclient samba gvfs gvfs-smb cifs-utils xarchiver cpio
    unarj unzip zip unace unrar p7zip sharutils uudeview arj cabextract
    lzip zlib laszip lbzip2 lrzip pbzip2 lzop tumbler ffmpegthumbnailer
    thunar-shares-plugin thunar-vcs-plugin thunar-volman
)

PACKAGES_AUDIO=(
    pipewire pipewire-alsa pipewire-pulse wireplumber pavucontrol
    alsa-utils pulsemixer pamixer pasystray
)

PACKAGES_BLUETOOTH=(
    bluez bluez-tools bluez-utils blueman
)

PACKAGES_UTILITIES=(
    xf86-input-wacom libwacom solaar papirus-icon-theme lxappearance qt5ct
    flameshot gpicview arandr conky redshift brightnessctl
    acpi acpid xfce4-power-manager
)

PACKAGES_CODECS=(
    ffmpeg gst-plugins-ugly gst-plugins-good gst-plugins-base gst-plugins-bad
    gst-libav gstreamer slop
)

PACKAGES_PLAYERS=(
    playerctl mpd ncmpcpp mpc rmpc mpv
)

PACKAGES_EDITORS=(
    emacs vim neovim micro geany
)

# Install packages by group
if [ "$ONLY_CONFIG" = false ]; then
    msg "Installing core packages..."
    sudo pacman -S --noconfirm  "${PACKAGES_CORE[@]}" || die "Failed to install core packages"
    sudo pacman -S --noconfirm  "${PACKAGES_SYSTEM[@]}" || die "Failed to install system core packages"

    msg "Installing Desktop Enviroments components..."
    sudo pacman -S --noconfirm "${PACKAGES_DESKTOP_ENVIROMENT[@]}" || die "Failed to install Desktop Enviroment packages"

    msg "Installing UI components..."
    sudo pacman -S --noconfirm "${PACKAGES_UI[@]}" || die "Failed to install UI packages"

    msg "Installing file manager..."
    sudo pacman -S --noconfirm "${PACKAGES_FILE_MANAGER[@]}" || die "Failed to install file manager"

    msg "Installing audio support..."
    sudo pacman -S --noconfirm "${PACKAGES_AUDIO[@]}" || die "Failed to install audio packages"

    msg "Installing codecs support..."
    sudo pacman -S --noconfirm "${PACKAGES_CODECS[@]}" || die "Failed to install codecs packages"

    msg "Installing players components..."
    sudo pacman -S --noconfirm "${PACKAGES_PLAYERS[@]}" || die "Failed to install players packages"

    msg "Installing bluetooth support..."
    sudo pacman -S --noconfirm "${PACKAGES_BLUETOOTH[@]}" || die "Failed to install bluetooth packages"

    msg "Installing system utilities..."
    sudo pacman -S --noconfirm "${PACKAGES_UTILITIES[@]}" || die "Failed to install utilities"

    msg "Installing terminal tools..."
    sudo pacman -S --noconfirm "${PACKAGES_TERMINAL[@]}" || die "Failed to install terminal tools"

    msg "Installing fonts..."
    sudo pacman -S --noconfirm "${PACKAGES_FONTS[@]}" || die "Failed to install fonts"

    msg "Installing security components..."
    sudo pacman -S --noconfirm "${PACKAGES_SECURITY[@]}" || die "Failed to install Security packages"

    msg "Installing office support..."
    sudo pacman -S --noconfirm "${PACKAGES_OFFICE[@]}" || die "Failed to install office packages"

    msg "Installing browsers support..."
    sudo pacman -S --noconfirm "${PACKAGES_BROWSERS[@]}" || die "Failed to install browsers packages"

    msg "Installing editors support..."
    sudo pacman -S --noconfirm "${PACKAGES_EDITORS[@]}" || die "Failed to install editors packages"

    msg "Installing build dependencies..."
    sudo pacman -S --noconfirm "${PACKAGES_BUILD[@]}" || die "Failed to install build tools"
    sudo pacman -S --noconfirm "${PACKAGES_DEPENDENCIES_DWM[@]}" || die "Failed to install dwm  build tools"
    sudo pacman -S --noconfirm "${PACKAGES_DEPENDENCIES_ST[@]}" || die "Failed to install st build tools"
    sudo pacman -S --noconfirm "${PACKAGES_DEPENDENCIES_DMENU[@]}" || die "Failed to install dmenu build tools"
    sudo pacman -S --noconfirm "${PACKAGES_DEPENDENCIES_DWMBLOCKS[@]}" || die "Failed to install dwmblocks build tools"
    sudo pacman -S --noconfirm "${PACKAGES_DEPENDENCIES_SLOCK[@]}" || die "Failed to install slock build tools"
    sudo pacman -S --noconfirm "${PACKAGES_DEPENDENCIES_NSXIV[@]}" || die "Failed to install nsxiv build tools"
    sudo pacman -S --noconfirm "${PACKAGES_DEPENDENCIES_WALRS[@]}" || die "Failed to install walrs build tools"

    # Enable services
    sudo systemctl enable avahi-daemon acpid NetworkManager bluetooth
    sudo systemctl enable ly@tty2.service

    # Disable system mpd service and enable user mpd service
    sudo systemctl disable mpd
    sudo systemctl stop mpd
    systemctl --user enable mpd

    # Install repo for flatpak
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

else
    msg "Skipping package installation (--only-config mode)"
fi


# Create folders
mkdir -p ~/.fonts ~/.icons ~/.themes ~/.local/share/sounds ~/.local/bin/scripts ~/.local/src ~/.wallpapers

# Create Symlinks of configs
msg "Stow configuration..."
mv ~/.bashrc ~/.bashrc_original
stow -d "$CONFIG_DIR/config" -t "$HOME/.config" .
stow -d "$CONFIG_DIR/fonts" -t "$HOME/.fonts" .
stow -d "$CONFIG_DIR/home" -t "$HOME" .
stow -d "$CONFIG_DIR/icons" -t "$HOME/.icons" .
stow -d "$CONFIG_DIR/scripts" -t "$HOME/.local/bin/scripts" .
stow -d "$CONFIG_DIR/sounds" -t "$HOME/.local/share/sounds" .
stow -d "$CONFIG_DIR/src" -t "$HOME/.local/src" .
stow -d "$CONFIG_DIR/themes" -t "$HOME/.themes" .
stow -d "$CONFIG_DIR/wallpapers" -t "$HOME/.wallpapers" .

# Build suckless tools
msg "Building suckless tools..."
for tool in dwm dmenu dwmblocks-async nsxiv potato-c slock st walrs; do
    cd "$CONFIG_DIR/src/$tool" || die "Cannot find $tool"
    make && sudo make install || die "Failed to build $tool"
done

# Build c3
cd "$CONFIG_DIR/src/c3"
cargo build --release
sudo cp target/release/c3 /usr/local/bin/


# Create desktop entries (skip if --only-config since they likely exist)
if [ "$ONLY_CONFIG" = false ]; then
    # Create desktop entry for DWM
    sudo mkdir -p /usr/share/xsessions
    cat <<EOF | sudo tee /usr/share/xsessions/dwm.desktop >/dev/null
[Desktop Entry]
Name=dwm
Comment=Dynamic window manager
Exec=dwm
Type=XSession
EOF

    # Create desktop file for ST
    mkdir -p ~/.local/share/applications
    cat > ~/.local/share/applications/st.desktop << EOF
[Desktop Entry]
Name=st
Comment=Simple Terminal
Exec=st
Icon=utilities-terminal
Terminal=false
Type=Application
Categories=System;TerminalEmulator;
EOF

    # create folder with wallpapers slock
    sudo mkdir -p /usr/share/images/desktop-base/wallpapers-slock
    sudo cp -R "$CONFIG_DIR/src/slock/wallpapers-slock/" /usr/share/images/desktop-base/wallpapers-slock/

else
    msg "Skipping desktop entry creation (--only-config mode)"
fi


# Files for themes
cat > ~/.theme_selected << EOF
#!/bin/bash
THEME_GTK="Catppuccin-Frappe-Standard-Pink-Dark"
THEME_ICON="Catppuccin-Mocha-Alt2"
THEME_MODE="Catppuccin"
COLOR_MODE="Dark"
THEME_ICON_DUNST="/usr/share/icons/Papirus-Dark/"
GTK_PREFER_DARK_MODE="1"
EMACS_THEME="frappe"
WALLPAPER_LIGHTDM="/usr/share/images/desktop-base/CatppuccinMocha-Planets.png"
COLOR_BACKGROUND="#303446"
COLOR_BACKGROUND2="#414559"
COLOR_TEXT="#c6d0f5"
COLOR_1="#e5c890"
COLOR_2="#ef9f76"
COLOR_3="#e78284"
COLOR_4="#ca9ee6"
COLOR_5="#8caaee"
COLOR_6="#81c8be"
COLOR_7="#a6d189"
COLOR_8="#b5bfe2"
COLOR_9="#f5e0b8"
COLOR_10="#ffb896"
COLOR_11="#ffa2a4"
COLOR_12="#e2b5f2"
COLOR_13="#a8c7ff"
COLOR_14="#a3e0d6"
COLOR_15="#c5e8b1"
COLOR_16="#d5def5"

EOF

mkdir -p ~/.config/gtk-2.0/
cat > ~/.config/gtk-2.0/gtkrc << EOF
gtk-icon-theme-name = "Catppuccin-Mocha-Alt2"
gtk-theme-name = "Catppuccin-Frappe-Standard-Pink-Dark"
EOF

mkdir -p  ~/.config/gtk-3.0/
cat >  ~/.config/gtk-3.0/settings.ini << EOF
[Settings]
gtk-theme-name=Catppuccin-Frappe-Standard-Pink-Dark
gtk-icon-theme-name=Catppuccin-Mocha-Alt2
gtk-font-name=Sans 10
gtk-cursor-theme-name=capitaine-cursors-gruvbox-white
gtk-cursor-theme-size=16
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintmedium
gtk-xft-rgba=none
gtk-application-prefer-dark-theme=1

EOF


mkdir -p  ~/.config/gtk-4.0/
cat >  ~/.config/gtk-4.0/settings.ini << EOF
[Settings]
gtk-theme-name=Catppuccin-Frappe-Standard-Pink-Dark
gtk-icon-theme-name=Catppuccin-Mocha-Alt2
gtk-font-name=Sans 10
gtk-cursor-theme-name=capitaine-cursors-gruvbox-white
gtk-cursor-theme-size=16
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintmedium
gtk-xft-rgba=none
gtk-application-prefer-dark-theme=1

EOF

cat >  ~/.gtkrc-2.0 << EOF
gtk-theme-name="Nordic-darker-v40"
gtk-icon-theme-name="Zafiro-Nord-Black"
gtk-font-name="Sans 10"
gtk-cursor-theme-name=" capitaine-cursors-gruvbox-white "
gtk-cursor-theme-size=0
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle="hintfull"

EOF

cat > ~/.Xresources <<EOF
! ==========================================
! Tema: Catppuccin Dark
! Gerado em: qua 15 jul 2026 15:14:29 -03
! ==========================================

! Cores base
background: #303446
foreground: #c6d0f5

! Cores principais (1-16)
*color1:  #e5c890
*color2:  #ef9f76
*color3:  #e78284
*color4:  #ca9ee6
*color5:  #8caaee
*color6:  #81c8be
*color7:  #a6d189
*color8:  #b5bfe2
*color9:  #f5e0b8
*color10: #ffb896
*color11: #ffa2a4
*color12: #e2b5f2
*color13: #a8c7ff
*color14: #a3e0d6
*color15: #c5e8b1
*color16: #d5def5

! ==========================================
! CORES COMPLETAS DO ST
! ==========================================

! Cores base
st.background: #303446
st.foreground: #c6d0f5

! Cores principais (0-15)
st.color0:  #51576D
st.color1:  #E78284
st.color2:  #A6D189
st.color3:  #E5C890
st.color4:  #8CAAEE
st.color5:  #F4B8E4
st.color6:  #81C8BE
st.color7:  #B5BFE2
st.color8:  #626880
st.color9:  #E78284
st.color10: #A6D189
st.color11: #E5C890
st.color12: #8CAAEE
st.color13: #F4B8E4
st.color14: #81C8BE
st.color15: #A5ADCE

! Configurações adicionais do ST
st.borderpx: 2
st.cwscale: 1.0
st.chscale: 1.0
st.alpha: 0.95
st.alphaUnfocused: 0.85
st.font: Iosevka Term:pixelsize=18:antialias=true:autohint=true:style=Regular
st.defaultfg: 256
st.defaultbg: 257
st.defaultcs: 258
st.defaultrcs: 258

! ==========================================
! CORES COMPLETAS DO DWM
! ==========================================

! Esquema Normal
dwm.normfgcolor: #F4B8E4
dwm.normbgcolor: #303446
dwm.normbordercolor: #51576D
dwm.normfloatcolor: #51576D

! Esquema Selecionado
dwm.selfgcolor: #F2D5CF
dwm.selbgcolor: #51576D
dwm.selbordercolor: #F2D5CF
dwm.selfloatcolor: #F2D5CF

! Título Normal
dwm.titlenormfgcolor: #CDD6F4
dwm.titlenormbgcolor: #303446
dwm.titlenormbordercolor: #51576D
dwm.titlenormfloatcolor: #F2D5CF

! Título Selecionado
dwm.titleselfgcolor: #F2D5CF
dwm.titleselbgcolor: #303446
dwm.titleselbordercolor: #303446
dwm.titleselfloatcolor: #303446

! Tags Normal
dwm.tagsnormfgcolor: #CDD6F4
dwm.tagsnormbgcolor: #303446
dwm.tagsnormbordercolor: #51576D
dwm.tagsnormfloatcolor: #F2D5CF

! Tags Selecionado
dwm.tagsselfgcolor: #F2D5CF
dwm.tagsselbgcolor: #51576D
dwm.tagsselbordercolor: #51576D
dwm.tagsselfloatcolor: #51576D

! Tags Não Utilizadas
dwm.tagsunusedfgcolor: #51576D
dwm.tagsunusedbgcolor: #303446
dwm.tagsunusedbordercolor: #51576D
dwm.tagsunusedfloatcolor: #F2D5CF

! Esquema Oculto
dwm.hidnormfgcolor: #51576D
dwm.hidnormbgcolor: #303446
dwm.hidselfgcolor: #C6D0F5
dwm.hidselbgcolor: #303446

! Esquema Urgente
dwm.urgfgcolor: #CDD6F4
dwm.urgbgcolor: #303446
dwm.urgbordercolor: #E78284
dwm.urgfloatcolor: #F2D5CF

! Símbolo do Layout
dwm.ltsymbolfgcolor: #ef9f76
dwm.ltsymbolbgcolor: #303446

! Cores individuais das tags (para compatibilidade)
dwm.tag1: #e5c890
dwm.tag2: #ef9f76
dwm.tag3: #e78284
dwm.tag4: #ca9ee6
dwm.tag5: #8caaee
dwm.tag6: #81c8be
dwm.tag7: #a6d189
dwm.tag8: #b5bfe2
dwm.tag9: #f5e0b8

! ==========================================
! CORES COMPLETAS DO DMENU
! ==========================================
dmenu.font: Caskaydia Mono Nerd Font:size=14:style=Regular:antialias=true:pixelsize=15
dmenu.background:       #303446
dmenu.foreground:       #CDD6F4
dmenu.selbackground:    #F2D5CF
dmenu.selforeground:    #303446
dmenu.outbackground:    #A6D189
dmenu.outforeground:    #303446
dmenu.bordercolor:      #F2D5CF
dmenu.selhlbackground:  #51576D
dmenu.selhlforeground:  #F4B8E4
dmenu.hlbackground:     #303446
dmenu.hlforeground:     #F4B8E4

! ==========================================
! CORES COMPLETAS DO SLOCK
! ==========================================
slock.locked  : #303446
slock.input   : #babbf1
slock.failed  : #e78284
slock.capslock: #ca9ee6
slock.blocks  : #a6e3a1
slock.bg_image: /usr/share/images/desktop-base/CatppuccinMocha-Planets.png

EOF


# Primeiro Wallpaper
cat > ~/.fehbg <<EOF
#!/bin/sh
feh --no-fehbg --bg-fill '/home/anderson/.wallpapers/Catppuccin/Dark/CatppuccinMocha-Saturn.png'
EOF

# install gtk themes
cd ~/.themes
tar -xvzf themes.tar.gz

# install icons
cd ~/.icons
tar -xvzf icons.tar.gz

# Setup directories
xdg-user-dirs-update
mkdir -p ~/Imagens/Screenshoots
