#!/usr/bin/env bash

# Enable the subsequent settings only in interactive sessions
case $- in
  *i*) ;;
    *) return;;
esac

# =============================================================================
# PATH CONFIGURATION
# =============================================================================

export PATH=""

# Primeiro: obter o PATH base do sistema
CLEAN_PATH="/usr/local/bin:/usr/bin:/bin:/usr/games"

# Adicionar paths do usuário na ordem correta (mais genéricos primeiro)
CLEAN_PATH="$HOME/.local/bin:$CLEAN_PATH"
CLEAN_PATH="$HOME/.config/emacs/bin:$CLEAN_PATH"
CLEAN_PATH="$HOME/.local/bin/mpd:$CLEAN_PATH"

# Adicionar scripts do suckless
CLEAN_PATH="$HOME/.config/suckless/scripts/dmenu:$CLEAN_PATH"
CLEAN_PATH="$HOME/.config/suckless/scripts/dwm:$CLEAN_PATH"
CLEAN_PATH="$HOME/.config/suckless/scripts/dwmblocks:$CLEAN_PATH"
CLEAN_PATH="$HOME/.config/suckless/scripts/others:$CLEAN_PATH"
CLEAN_PATH="$HOME/.config/suckless/scripts/conky:$CLEAN_PATH"
CLEAN_PATH="$HOME/.config/suckless/scripts/potato-c:$CLEAN_PATH"
CLEAN_PATH="$HOME/.config/suckless/scripts/themes:$CLEAN_PATH"
CLEAN_PATH="$HOME/.config/suckless/scripts/slock:$CLEAN_PATH"

# FINALMENTE: adicionar conda no FINAL
CLEAN_PATH="$CLEAN_PATH:$HOME/miniconda3/condabin"

# Exportar o PATH limpo
export PATH="$CLEAN_PATH"

# Limpar variável temporária
unset CLEAN_PATH

# =============================================================================
# ALIASES (incorporado do bashrc_alias)
# =============================================================================

# Complementos
alias compila="rm config.h; make; sudo make clean install"
alias edwm="cd /home/anderson/.config/src/suckless/dwm"
alias flexipatch-execute="mv $HOME/.config/suckless/src/dwm/config.def.h \"$HOME/.config/suckless/src/dwm/$(date +%Y-%m-%d_%H:%M:%S)-backup-config\"; $HOME/.config/suckless/src/dev/flexipatch/flexipatch-finalizer/flexipatch-finalizer.sh -r -d $HOME/.config/suckless/src/dev/flexipatch/dwm-flexipatch/ -o $HOME/.config/suckless/src/dwm/"

alias ..='cd ..'
alias ...='cd ../..'
alias df='df -h'
alias free='free -h'
alias myip="ip -f inet address | grep inet | grep -v 'lo$' | cut -d ' ' -f 6,13 && curl ifconfig.me && echo ' external ip'"
alias x="exit"
alias baixa_site="wget -r -erobots=off"

# YouTube downloads
alias yt='ytfzf --max-threads=4 --thumbnail-quality=maxres --features=hd -t --ii=https://yt.securityops.co'
alias baixa_mp3='yt-dlp -f bestaudio --extract-audio --audio-format m4a --embed-thumbnail --add-metadata'
alias ytmp3='yt-dlp -f bestaudio --extract-audio --audio-format m4a --audio-quality 0 -o "%(title)s.%(ext)s" '

# Git aliases
alias gp="git push -u origin main"
alias gsave="git commit -m 'save'"
alias gs="git status"
alias gc="git clone"

# Programas
alias em="emacs -nw"
alias nvidia="__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia"
alias betterdiscord-update="DISC_CONFIG=\"\$HOME/.var/app/com.discordapp.Discord/config/discord\" && BD_ASAR=betterdiscord.asar && wget --timestamping -P \"\${DISC_CONFIG}/../BetterDiscord/data\" -- \"https://github.com/BetterDiscord/BetterDiscord/releases/latest/download/\${BD_ASAR}\" && DISC_VER=\"\$(ls --sort=time --time=creation \"\${DISC_CONFIG}\" | grep -E -m 1 '^[0-9]+\\.[0-9]+\\.[0-9]+\$')\" && echo -e \"require('../../../../BetterDiscord/data/\${BD_ASAR}');\\nmodule.exports = require('./core.asar');\" | tee \"\${DISC_CONFIG}/\${DISC_VER}/modules/discord_desktop_core/index.js\" && echo -e \"\\nBetterDiscord installed. Restart Discord if currently running.\" || echo -e \"\\nInstallation failed.\""
alias EDITOR="emacsclient -c -a 'emacs'"

# Conda
alias R-env="conda activate r-env"

# =============================================================================
# CONDA CONFIGURATION
# =============================================================================

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/anderson/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/anderson/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/anderson/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/anderson/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# =============================================================================
# FUNÇÕES E CONFIGURAÇÕES ADICIONAIS
# =============================================================================

unset MAILCHECK

# Source do tema selecionado (se existir)
if [ -f "$HOME/.theme_selected" ]; then
    source "$HOME/.theme_selected"
fi

PS1='\[\e[0;2m\]\$ \[\e[0m\]\u\[\e[0;2m\]@\[\e[0m\]\h \[\e[0m\](\[\e[0m\]\W\[\e[0m\]) \[\e[0;1m\]~ \[\e[0m\]'

export PATH="/home/anderson/.pixi/bin:$PATH"
