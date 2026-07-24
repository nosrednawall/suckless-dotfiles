# ~/.config/zsh/.zshenv

# ---------- XDG base directories ----------
# Centralizes config/cache/data locations
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"

# ---------- Editor ----------
# Default editor used by git, crontab, etc.
export EDITOR="micro"
export VISUAL="emacs"

# ---------- Pager ----------
if command -v bat >/dev/null 2>&1; then
  export MANPAGER="bat -l man -p"
elif command -v batcat >/dev/null 2>&1; then
  export MANPAGER="batcat -l man -p"
fi

# ---------- GPG ----------
export GPG_TTY=$(tty)

# ---------- Starship ----------
export STARSHIP_CONFIG="$ZDOTDIR/starship.toml"

# ---------- PATH ----------
# Personal binaries/scripts
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.config/emacs/bin:$PATH"
export PATH="$HOME/.local/bin/mpd:$PATH"

# Adicionar scripts do suckless
export PATH="$HOME/.config/suckless/scripts/dmenu:$PATH"
export PATH="$HOME/.config/suckless/scripts/dwm:$PATH"
export PATH="$HOME/.config/suckless/scripts/dwmblocks:$PATH"
export PATH="$HOME/.config/suckless/scripts/others:$PATH"
export PATH="$HOME/.config/suckless/scripts/conky:$PATH"
export PATH="$HOME/.config/suckless/scripts/potato-c:$PATH"
export PATH="$HOME/.config/suckless/scripts/themes:$PATH"
export PATH="$HOME/.config/suckless/scripts/slock:$PATH"


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
