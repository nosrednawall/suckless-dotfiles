# Better ls
alias ls='eza --icons'

# Detailed listing
alias ll='eza -lh --icons --git'

# Detailed listing including hidden files
alias la='eza -lah --icons --git'

# Tree view
alias tree='eza --tree --icons'

# Reuse ls completions for eza (avoids defining a separate completion function)
compdef eza=ls

# Better cat
alias catbat='bat'

# =========================================================
# Suckless utilities
# =========================================================
alias compila="rm config.h; make; sudo make clean install"
alias edwm="cd /home/anderson/.config/src/suckless/dwm"


# =========================================================
# Other utilities
# =========================================================
alias myip="ip -f inet address | grep inet | grep -v 'lo$' | cut -d ' ' -f 6,13 && curl ifconfig.me && echo ' external ip'"
alias yt='ytfzf --max-threads=4 --thumbnail-quality=maxres --features=hd -t --ii=https://yt.securityops.co'
alias baixa_mp3='yt-dlp -f bestaudio --extract-audio --audio-format m4a --embed-thumbnail --add-metadata'
alias ytmp3='yt-dlp -f bestaudio --extract-audio --audio-format m4a --audio-quality 0 -o "%(title)s.%(ext)s" '

# =========================================================
# Core utilities
# =========================================================

alias grep='rg --color=auto'
alias diff='diff --color=auto'
alias df='df -h'

# =========================================================
# Navigation
# =========================================================

alias -- -='cd -'  # -- prevents - being parsed as a flag; cd - jumps to previous directory

lf() { # zsh follow lf navigation
    tmp=$(mktemp)
    command lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        dir=$(cat "$tmp")
        rm -f "$tmp"
        [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
    fi
}

# =========================================================
# Editor
# =========================================================

alias vim='nvim'
alias EDITOR="emacsclient -c -a 'emacs'"

# =========================================================
# Git
# =========================================================

alias glog='PAGER="less -F -X" git log'                              # -F quit if one screen, -X no clear on exit
alias gadog='PAGER="less -F -X" git log --all --decorate --oneline --graph'
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

# =========================================================
# Video
# =========================================================

alias stream='mpv av://v4l2:/dev/video4 --fullscreen --demuxer-lavf-o=input_format=mjpeg,framerate=30 --profile=low-latency --untimed'
