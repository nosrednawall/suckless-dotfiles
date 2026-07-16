#!/bin/ash

# Copyright (c) 2026 sc0ttj
# Licensed under the MIT License
# https://opensource.org

# --- UI colours ---

: ${BG_MAIN:="34;34;34"}            # Dark grey main background
: ${BG_MODAL:="50;50;50"}           # Lighter grey for modal popups
: ${BG_WIDGET:="68;68;68"}          # Standard button/widget background
: ${FG_TEXT:="239;239;239"}         # Off-white primary text
: ${BG_ACTIVE:="60;120;160"}        # Unified deep blue focus color
: ${HL_BLUE:="$BG_ACTIVE"}          # Map highlight blue to active focus
: ${FG_HINT:="150;150;150"}         # Dimmed grey for control hints
: ${FG_BACKTITLE:="95;175;215"}     # Light blue for desktop background text
: ${BG_BACKTITLE:="50;50;50"}      # Grey background for BACKTITLE bar
: ${BG_INPUT:="20;20;20"}           # Near black for input backgrounds
: ${FG_INPUT:="95;175;215"}         # Light blue for active input text
: ${FG_INPUT_ROOT:="255;60;60"}     # Red for Root prompt

# Define a "Soft Bold" that only changes the foreground, not the background
: ${SB:="\e[1;37m"}
# Define a "Soft Reset" that returns to Hint color while keeping BG_MAIN
: ${SR:="\e[22m${FG_HINT_ESC}"}

# --- ANSI helpers ---
 
RESET="\e[0m"    # Reset all formatting and colours
BOLD="\e[1m"     # Set text to bold weight
CLR_EOL="\e[K"   # Clear line from cursor to right edge
CLR_DOWN="\e[J"  # Clear screen from cursor to bottom

# Cached escape chars (computed once to avoid per-keypress forks)
_ESC=$(printf '\e')
_TAB=$(printf '\t')
_DEL=$(printf '\177')
_BS=$(printf '\10')
_CR=$(printf '\r')
_LF=$(printf '\n')

_esc() { printf "\e[%s;2;%sm" "$1" "$2"; }

# --- POSIX helper functions (for ash/busybox compat) ---

_match() { case $1 in $2) return 0;; esac; return 1; }

_is_numeric() { case $1 in ''|*[!0-9]*) return 1;; esac; return 0; }

_tolower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

_is_interactive_field() { _match "$1" ">*" || _match "$1" "[*" || _match "$1" "(*" || _match "$1" "{*"; }

# --- Shell compatibility guard ---
# Verify this shell supports features terminal-menus.sh relies on.
# Minimal Busybox builds may lack [[ ]], read -n, or $'...'.
if ! [[ "" == "" ]] 2>/dev/null; then
    echo "terminal-menus.sh: this shell lacks [[ ]] support. Use bash or a Busybox build with ASH_BASH_COMPAT enabled." >&2
    exit 1
fi
if ! read -n1 _ 2>/dev/null <<'EOF'
a
EOF
then
    echo "terminal-menus.sh: this shell lacks read -n support. Use bash or a Busybox build with ASH_BASH_COMPAT enabled." >&2
    exit 1
fi
a=$'\x41' 2>/dev/null
if [ "$a" != "A" ]; then
    echo "terminal-menus.sh: this shell lacks ANSI-C quoting (\$'...') support. Use bash or a Busybox build with ASH_BASH_COMPAT enabled." >&2
    exit 1
fi

# --- Key reading helpers (IFS-safe for ash compat) ---

_read_key() {
    local _rk_ifs="$IFS"; IFS=; read -r -n1 "$@" < /dev/tty 2>/dev/null; local _rk_rc=$?; IFS="$_rk_ifs"; return $_rk_rc
}

_read_str_timeout() {
    local _rk_ifs="$IFS"; IFS=; read -t 1 -r -n "$@" < /dev/tty 2>/dev/null; local _rk_rc=$?; IFS="$_rk_ifs"; return $_rk_rc
}

# --- Cursor text editing helpers ---
# Move cursor right: pop first char of $2, push it onto $1
_cursor_right() { local _cs; eval "_cs=\"\${$2}\""; [ -z "$_cs" ] && return; local _c="${_cs%"${_cs#?}"}"; eval "$2=\"\${_cs#?}\""; eval "$1=\"\${$1}\${_c}\""; }

# Move cursor left: pop last char of $1, push it onto $2
_cursor_left() { local _cp; eval "_cp=\"\${$1}\""; [ -z "$_cp" ] && return; local _c="${_cp#"${_cp%?}"}"; eval "$1=\"\${_cp%?}\""; eval "$2=\"\${_c}\${$2}\""; }

# Render text with cursor highlight, sets _DISPLAY and _VIS_LEN globals
_render_cursor_display() {
    local _p="$1" _s="$2"
    if [ -n "$_s" ]; then
        local _cc="${_s%"${_s#?}"}" _cr="${_s#?}"
        _DISPLAY="${_p}"$'\x1b[7m'"${_cc}"$'\x1b[27m'"${_cr}"
        _VIS_LEN=$(( ${#_p} + ${#_s} ))
    else
        _DISPLAY="${_p}"$'\x1b[7m \x1b[27m'
        _VIS_LEN=$(( ${#_p} + 1 ))
    fi
}

# --- Key + Escape sequence reader ---
# Reads one key into KEY; if it's ESC, reads trailing sequence into ESC_SEQ
_read_key_esc() {
    ESC_SEQ=""; KEY=""
    _read_key KEY
    [ "$KEY" = "$_ESC" ] && _read_str_timeout 2 ESC_SEQ
}

# --- Extra keys parser and handler ---
# Parses TUI_EXTRA_KEYS env var into numbered globals for custom keybindings.
# Each line: key=command (key supports ctrl_<c> and shift_<c> prefixes)
_parse_extra_keys() {
    _ek_count=0
    [ -z "$TUI_EXTRA_KEYS" ] && return
    local _ek_save="$IFS"; IFS=$'\n'
    for _ek_line in $TUI_EXTRA_KEYS; do
        IFS="$_ek_save"
        while :; do case "$_ek_line" in ' '*) _ek_line="${_ek_line# }" ;; $'\t'*) _ek_line="${_ek_line#	}" ;; *) break ;; esac; done
        [ -z "$_ek_line" ] && continue
        case "$_ek_line" in *=*) ;; *) continue ;; esac
        local _ek_key="${_ek_line%%=*}"
        local _ek_val="${_ek_line#*=}"
        case "$_ek_key" in
            ctrl_*)
                local _ek_ch="${_ek_key#ctrl_}"
                local _ek_code; _ek_code=$(printf '%d' "'$_ek_ch")
                _ek_code=$((_ek_code - 96))
                _ek_key=$(printf '%b' "\\$(printf '%03o' "$_ek_code")")
                ;;
        esac
        case "$_ek_key" in
            shift_*)
                local _ek_ch="${_ek_key#shift_}"
                _ek_key=$(printf '%s' "$_ek_ch" | tr '[:lower:]' '[:upper:]')
                ;;
        esac
        eval "_ek_key_$_ek_count=\$_ek_key"
        # Store value with single-quote escaping for safe eval
        local _ek_val_sq; _ek_val_sq=$(printf '%s' "$_ek_val" | sed "s/'/'\\\\''/g")
        eval "_ek_val_$_ek_count='$_ek_val_sq'"
        _ek_count=$((_ek_count+1))
    done
    IFS="$_ek_save"
}

_handle_extra_keys() {
    [ "$_ek_last_value" != "$TUI_EXTRA_KEYS" ] && { _ek_count=0; _ek_last_value="$TUI_EXTRA_KEYS"; [ -n "$TUI_EXTRA_KEYS" ] && _parse_extra_keys; }
    [ "$_ek_count" -eq 0 ] && return 1
    local _ek_i=0 _ek_k _ek_v
    while [ "$_ek_i" -lt "$_ek_count" ]; do
        eval "_ek_k=\"\$_ek_key_$_ek_i\""
        if [ "$1" = "$_ek_k" ]; then
            eval "_ek_v=\"\$_ek_val_$_ek_i\""
            eval "$_ek_v"
            return 0
        fi
        _ek_i=$((_ek_i+1))
    done
    return 1
}

# --- UI Labels ---

# Optional title that goes at the very top
: ${BACKTITLE:=""}

# Maximum items to process in filter loops (avoids long freezes with 10K+ items)
: ${MAX_FILTER_ITEMS:=5000}

# --- Global Button Labels ---
: ${OK_LABEL:="OK"}
: ${CANCEL_LABEL:="CANCEL"}
: ${YES_LABEL:="YES"}
: ${NO_LABEL:="NO"}


# A var that always captures the output of a widget, users 
# should check this var after a widget exits.
TUI_RESULT=""

LAST_FRAME=""

# --- External script override ---
# If PREVIEW_SCRIPT env var is set, source it to override the built-in preview() function
if [ -n "$PREVIEW_SCRIPT" ] && [ -f "$PREVIEW_SCRIPT" ]; then
    . "$PREVIEW_SCRIPT"
else

# --- Built-in preview function ---
preview() {
    local file=$1 row_start=$2 height=$3 col_start=$4
    local offset=${5:-0}
    local width=$(( MAX_WIDTH - col_start - 1 ))
    local absolute_col=$(( PADDING_LEFT + col_start - 2 ))
    
    # 1. Clear the preview area
    local clear_block=""
    local spaces=$(printf "%*s" "$width" "")
    i=0; while [ "$i" -lt "$height" ]; do
        clear_block="${clear_block}"$'\033'"[$((row_start + i + PADDING_TOP));${absolute_col}H${BG_MAIN_ESC}${spaces}"
        i=$((i+1))
    done
    printf "%b" "$clear_block" >&2

    [ ! -f "$file" ] && return

    local line_count=0
    local preview_content=""
    
    # 2. Optimized Reading & ANSI Stripping (Portable)
    # Stage 1: Strip ANSI (sed)
    # Stage 2: Slice lines (sed -n 'start,endp')
    local _preview_tmp=$(mktemp /tmp/tui_preview.XXXXXX)
    sed $'s/\e[[][^A-Za-z]*[A-Za-z]//g' "$file" | sed -n "$((offset + 1)),$((offset + height))p" > "$_preview_tmp"
    while IFS= read -r line; do
        line="${line//$'\t'/    }"
        line="${line:0:width}"
        
        row_str=$(printf "\e[$((row_start + line_count + PADDING_TOP));${absolute_col}H${FG_HINT_ESC}%-*s${RESET}${BG_MAIN_ESC}" "$width" "$line")
        preview_content="${preview_content}${row_str}"
        line_count=$((line_count+1))
    done < "$_preview_tmp"
    rm -f "$_preview_tmp"
    
    printf "%b" "$preview_content" >&2
}

fi  # end PREVIEW_SCRIPT override check

# --- Setup ---

cleanup() {
    # 1. Send ANSI Escape Sequences to the terminal
    # \e[?25h  -> Show Cursor: Reverses \e[?25l (which hides it during UI drawing)
    # \e[?1000l -> Disable Mouse: Stops the terminal from sending click/scroll events as text
    # \e[0m     -> Reset Colors: Clears all TrueColor/Bold styles and returns to default
    # \e[H      -> Cursor Home: Moves the cursor to the top-left (1,1)
    # \e[J      -> Clear Screen: Wipes everything from the cursor (Home) to the bottom
    # >&2       -> Redirect to STDERR: Ensures these UI codes don't corrupt piped data output
    printf "\e[?25h\e[?1000l\e[0m\e[H\e[J" >&2

    # 2. Reset the terminal line settings
    # sane     -> Restores keyboard 'echo' and standard input buffering. 
    #             Critical if the script crashed while 'stty -echo' was active.
    stty sane

    # 3. Terminfo-based cursor restoration
    # cnorm    -> "Cursor Normal". A portable backup command to ensure the 
    #             cursor is visible even on non-XTerm compatible terminals.
    tput cnorm
}

# trap         -> The Bash built-in command used to catch signals or events.
# cleanup      -> The name of the function to execute when the event occurs.
# EXIT         -> A special Bash "pseudo-signal" that triggers when the shell 
#                 process ends for ANY reason (normal finish, error, or exit command).
#
# Combined: This ensures the terminal is restored (via cleanup) even if the 
#           script crashes or the user exits unexpectedly, preventing a 
#           permanently "broken" terminal state.
trap cleanup 0 2

# Define a function to refresh the TUI on resize
handle_resize() {
    # Most widgets call _init_tui at the start of their loop.
    # By triggering a "continue" in your widget loops or 
    # simply re-calculating dimensions, the UI will "snap" to the new center.
    _init_tui
}

# Trap the WINCH (Window Change) signal
trap handle_resize WINCH

# --- Helper functions ---

_show_cursor() { printf "\e[?25h" >&2; }
_hide_cursor() { printf "\e[?25l" >&2; }

# Define these ONCE at the top level of your script (outside _init_tui)
# to avoid re-calculating strings that never change.
_init_static_colors() {
    # We remove the gate so this can be re-run during theme switches.
    # Map HL_BLUE to BG_ACTIVE to ensure highlights update
    BG_ACTIVE="${HL_BLUE:-$BG_ACTIVE}"
    
    BG_MAIN_ESC="\e[48;2;${BG_MAIN}m"
    BG_MODAL_ESC="\e[48;2;${BG_MODAL}m"
    FG_TEXT_ESC="\e[38;2;${FG_TEXT}m"
    FG_HINT_ESC="\e[22m\e[38;2;${FG_HINT}m"
    BG_ACTIVE_ESC="\e[48;2;${BG_ACTIVE}m"
    BG_BLUE_ESC="$BG_ACTIVE_ESC"
    BG_WID_ESC="\e[48;2;${BG_WIDGET}m"
    BG_WID_TEXT_ESC="${BG_WID_ESC}${FG_TEXT_ESC}"
    FG_INPUT_ESC="\e[38;2;${FG_INPUT}m"
    BG_INPUT_ESC="\e[48;2;${BG_INPUT}m"
    FG_BACKTITLE_ESC="\e[38;2;${FG_BACKTITLE}m"
    BG_BACKTITLE_ESC="\e[48;2;${BG_BACKTITLE}m"
    BG_TABLE_HEADER_ESC="\e[48;2;100;100;100m${FG_TEXT_ESC}"
    
    # Pre-calculate bolds based on the current active/highlight colors
    FG_BLUE_BOLD="\e[1;38;2;${FG_INPUT}m"
    HL_WHITE_BOLD="\e[48;2;${BG_ACTIVE}m\e[38;2;255;255;255;1m"
}

_init_tui() {
    stty -echo -icanon min 1 time 1
    _apply_layout
    
    # ALWAYS re-init colors to support theme switching
    _init_static_colors

    # 1. FLICKER-FREE BACKGROUND HANDLING
    if [ "$TUI_MODAL" = "true" ]; then
        printf "\e[H\e[2m%b\e[0m" "$LAST_FRAME" >&2
    else
        printf "\e[0m\e[H\e[2J\e[3J" >&2
    fi

    # 2. RE-BUILD THE WALL (Now with the new theme colors)
    local wall="" line_fill=""
    line_fill=$(printf "%*s" "$MAX_WIDTH" "")
    
    i=0; while [ "$i" -lt "$MAX_HEIGHT" ]; do
        local r=$((PADDING_TOP + i + 1))
        # This will now use the updated BG_MAIN_ESC
        wall="${wall}"$'\033'"[${r};${PADDING_LEFT}H${BG_MAIN_ESC}${line_fill}"
        i=$((i+1))
    done
    printf "%b\e[0m" "$wall" >&2

    # 3. BACKTITLE
    if [ -n "$BACKTITLE" ]; then
        local title_row=$(( PADDING_TOP ))
        [ "$title_row" -lt 1 ] && title_row=1
        local _bt_fill=""
        if [ "$TUI_MODAL" != "true" ]; then
            local _bt_rem=$(( MAX_WIDTH - ${#BACKTITLE} ))
            [ "$_bt_rem" -lt 0 ] && _bt_rem=0
            _bt_fill=$(printf "%*s" "$_bt_rem" "")
        fi
        printf "\e[${title_row};${PADDING_LEFT}H\e[0m${BG_BACKTITLE_ESC}${FG_BACKTITLE_ESC}${BOLD}%s${_bt_fill}\e[0m" "$BACKTITLE" >&2
    fi

    # 4. PARK CURSOR
    printf "\e[1;1H\e[?25l" >&2

    # Reset global row for the next widget
    if [ -n "$BACKTITLE" ] && [ "$PADDING_TOP" -eq 0 ]; then
        row=3
    else
        row=2
    fi
}

_apply_layout() {
    # Use local variables for the current terminal state to support resizing
    local term_w="${COLUMNS:-$(tput cols)}"
    local term_h="${LINES:-$(tput lines)}"
    local mode="${TUI_MODE:-centered}"

    case "$mode" in
        "fullscreen")
            MAX_WIDTH=$term_w;   MAX_HEIGHT=$term_h
            PADDING_LEFT=0;       PADDING_TOP=0
            ;;
        "popup")
            MAX_WIDTH=50;         MAX_HEIGHT=6
            PADDING_LEFT=$(( (term_w - MAX_WIDTH) / 2 ))
            PADDING_TOP=$(( (term_h - 10) / 2 ))
            ;;
        "top")
            MAX_WIDTH=$term_w;   MAX_HEIGHT=10
            PADDING_LEFT=0;       PADDING_TOP=0
            ;;
        "bottom")
            MAX_WIDTH=$term_w;   MAX_HEIGHT=9
            PADDING_LEFT=0;       PADDING_TOP=$(( term_h - MAX_HEIGHT ))
            ;;
        "toast")
            MAX_WIDTH=${TOAST_WIDTH:-35}
            MAX_HEIGHT=5
            PADDING_TOP=1
            PADDING_LEFT=$(( term_w - MAX_WIDTH - 2 ))
            ;;
        "palette")
            MAX_WIDTH=${PALETTE_WIDTH:-32}
            MAX_HEIGHT=${PALETTE_HEIGHT:-10}
            local anchor=${ANCHOR:-"br"}
            # Vertical Anchor
            case "${anchor:0:1}" in
                "t") PADDING_TOP=1 ;;
                "b") PADDING_TOP=$(( term_h - MAX_HEIGHT - 1 )) ;;
                "c"|*) PADDING_TOP=$(( (term_h - MAX_HEIGHT) / 2 )) ;;
            esac
            # Horizontal Anchor
            case "${anchor:1:1}" in
                "l") PADDING_LEFT=2 ;;
                "r") PADDING_LEFT=$(( term_w - MAX_WIDTH - 2 )) ;;
                "c"|*) PADDING_LEFT=$(( (term_w - MAX_WIDTH) / 2 )) ;;
            esac
            ;;
        "classic")
            MAX_WIDTH=80;         MAX_HEIGHT=25
            PADDING_LEFT=$(( (term_w - MAX_WIDTH) / 2 ))
            PADDING_TOP=$(( (term_h - MAX_HEIGHT) / 2 ))
            ;;
        "custom")
            # Fallback to centered defaults if variables aren't set
            MAX_WIDTH=${TUI_WIDTH:-75}
            MAX_HEIGHT=${TUI_HEIGHT:-22}

            # 1. Manual Position OR 2. Auto-Center
            # If PADDING_X is not set, we calculate it to keep the box centered
            PADDING_LEFT=${TUI_X:-$(( (term_w - MAX_WIDTH) / 2 ))}
            PADDING_TOP=${TUI_Y:-$(( (term_h - MAX_HEIGHT) / 2 ))}
            ;;
        "centered"|*)
            MAX_WIDTH=75;         MAX_HEIGHT=22
            PADDING_LEFT=$(( (term_w - MAX_WIDTH) / 2 ))
            PADDING_TOP=$(( (term_h - MAX_HEIGHT) / 2 ))
            ;;
    esac

    # Safety Clamping (Ensures UI never draws off-screen)
    [ "$MAX_WIDTH" -gt "$term_w" ] && MAX_WIDTH=$term_w && PADDING_LEFT=0
    [ "$MAX_HEIGHT" -gt "$term_h" ] && MAX_HEIGHT=$term_h && PADDING_TOP=0

    # Derived layout constants (recomputed on resize)
    INDENT="  "
    CONTENT_WIDTH=$(( MAX_WIDTH - 6 ))
    CONTENT_WIDTH_WIDE=$(( MAX_WIDTH - 4 ))
    CONTROLS_ROW=$(( MAX_HEIGHT - 1 ))
    FOOTER_HEIGHT=2
    MIN_CONTENT_HEIGHT=3
    INPUT_WIDTH=34
    FILTER_WIDTH=25
}

# Initial call to set global variables based on default mode
_apply_layout

# Parse custom keybindings from environment
_parse_extra_keys

_get_start_row() {
    local offset=0
    
    # 1. Calculate internal padding based on text content
    [ -n "$title" ] && offset=$((offset+1))
    [ -n "$msg" ] && offset=$((offset+1))
    # Only add the spacer if there is a header block to separate
    [ -n "$title" ] || [ -n "$msg" ] && offset=$((offset+1))

    # 2. THE FIX: Protect the BACKTITLE in Fullscreen Mode
    # If we are at the top of the terminal 
    if [ "$TUI_MODE" = "fullscreen" ]; then
        # If we have a backtitle, the first 2 lines are RESERVED.
        # So the minimum safe row is 2.
        if [ -n "$BACKTITLE" ]; then
             [ "$offset" -lt 2 ] && echo 2 || echo "$offset"
        else
             echo "$offset"
        fi
    else
        # In centered/popup modes, we don't have a backtitle 
        # at the top of the terminal, so we can be flush (0).
        echo "$offset"
    fi
}

_draw_at() {
    # target_col = (Padding) + (Relative Col)
    local target_row=$(( $1 + PADDING_TOP ))
    local target_col=$(( PADDING_LEFT + ${2:-${COL_START:-0}} ))

    printf "\e[%d;%dH${FG_TEXT_ESC}${BG_MAIN_ESC}" "$target_row" "$target_col" >&2
}

_draw_line() {
    [[ -n "$2" ]] && row=$2
    local target_row=$(( row + PADDING_TOP ))
    local target_col=$(( PADDING_LEFT + ${COL_START:-0} ))
    
    if [ -n "$1" ]; then
        local _cw=$(( MAX_WIDTH - ${COL_START:-0} ))
        [ "$_cw" -lt 0 ] && _cw=0
        printf "\e[%d;%dH${FG_TEXT_ESC}${BG_MAIN_ESC}%*s\e[%d;%dH${FG_TEXT_ESC}${BG_MAIN_ESC}%b" \
            "$target_row" "$target_col" "$_cw" "" \
            "$target_row" "$target_col" "$1" >&2
    fi
    row=$((row+1))
}

_draw_spacer() { row=$((row+1)); }

_draw_header() {
    local t=$1 m=$2
    title=$t msg=$m

    # Start at the top of the internal box
    row=2

    # Ensure we don't draw over the backtitle in fullscreen
    if [ "$PADDING_TOP" -eq 0 ] && [ -n "$BACKTITLE" ]; then
        row=3
    fi
    # 1. Title Row - Only draw if not empty
    if [ -n "$title" ]; then
        _draw_line "${INDENT}${FG_TEXT_ESC}=== $title ===${RESET}${BG_MAIN_ESC}"
    fi
    
    # 2. Message Rows - Only draw if not empty
    if [ -n "$msg" ]; then
        local expanded_msg
        expanded_msg=$(printf "%b" "$msg")
        local old_ifs="$IFS"
        IFS=$'\n'
        for line in $expanded_msg; do
            # Using your existing target_row/target_col logic
            local target_row=$(( row + PADDING_TOP ))
            local target_col=$(( PADDING_LEFT + ${COL_START:-0} ))
            printf "\e[%d;%dH${FG_TEXT_ESC}${BG_MAIN_ESC}${INDENT}%s" "$target_row" "$target_col" "$line" >&2
            _draw_line ""
        done
        IFS="$old_ifs"
    fi

    # 3. Spacer - Only if header content was drawn
    if [ -n "$title" ] || [ -n "$msg" ]; then
        _draw_line ""
    fi
    
    # Remove the empty line under headers in toast and palette modes,
    # if $title or $msg not empty - if both are empty, dont move things up,
    # this keeps "content only" stuff nicely padded in the box
    if [ "$TUI_MODE" = "toast" ] || [ "$TUI_MODE" = "palette" ]; then
        if [ -n "$title" ] || [ -n "$msg" ]; then
            row=$((row - 1))
        fi
    fi
}

_draw_controls() {
    local hints=$1
    # We use _draw_line to ensure the background fills the MAX_WIDTH 
    # and respects PADDING_LEFT
    _draw_line " ${FG_HINT_ESC}${hints}${RESET}${BG_MAIN_ESC}"
}

# Draw controls at the bottom row of the UI
_draw_controls_at_bottom() {
    row=$CONTROLS_ROW
    case "$TUI_MODE" in popup|toast|palette) return ;; esac
    _draw_controls "$@"
}

# Show context-sensitive help popup for a widget type
_help_popup() {
    local widget="$1"
    local ctxt=""
    case "$widget" in
        list)
            ctxt=" 
${SB}Up${SR}/${SB}Down${SR}    Navigate (also ${SB}w${SR}/${SB}s${SR} and ${SB}j${SR}/${SB}k${SR})
${SB}PgUp${SR}/${SB}PgDn${SR}  Page scroll (also ${SB}J${SR}/${SB}K${SR})
${SB}Home${SR}/${SB}End${SR}   Jump to top/bottom (also ${SB}g${SR}/${SB}G${SR})
${SB}Space${SR}      Toggle
${SB}Enter${SR}      Confirm
${SB}q${SR}          Cancel / Quit" ;;
        form)
            ctxt=" 
${SB}Tab${SR}         Cycle fields
${SB}Left${SR}/${SB}Right${SR}  Move cursor in text input
${SB}Space${SR}       Toggle checkbox/radio, open dropdown
${SB}Enter${SR}       Submit form
${SB}Esc${SR}         Close dropdown / Cancel
${SB}q${SR}           Cancel / Quit" ;;
        filtermenu)
            ctxt=" 
${SB}Up${SR}/${SB}Down${SR}     Navigate results (also ${SB}w${SR}/${SB}s${SR} and ${SB}j${SR}/${SB}k${SR})
${SB}PgUp${SR}/${SB}PgDn${SR}   Page scroll (also ${SB}J${SR}/${SB}K${SR})
${SB}Home${SR}/${SB}End${SR}    Jump to top/bottom (also ${SB}g${SR}/${SB}G${SR})
${SB}Tab${SR}         Toggle focus (list / filter)
${SB}/${SR}           Focus filter (from list)
${SB}Left${SR}/${SB}Right${SR}  Move cursor in filter
${SB}Enter${SR}       Select item
${SB}q${SR}           Cancel / Quit" ;;
        filepicker)
            ctxt=" 
${SB}Up${SR}/${SB}Down${SR}    Navigate (also ${SB}w${SR}/${SB}s${SR} and ${SB}j${SR}/${SB}k${SR})
${SB}PgUp${SR}/${SB}PgDn${SR}  Page scroll (also ${SB}J${SR}/${SB}K${SR})
${SB}Home${SR}/${SB}End${SR}   Jump to top/bottom (also ${SB}g${SR}/${SB}G${SR})
${SB}Tab${SR}        Mark item
${SB}Enter${SR}/${SB}d${SR}    Open dir / Select file
${SB}Left${SR}/${SB}h${SR}/${SB}a${SR}   Parent dir
${SB}.${SR}          Toggle hidden
${SB}q${SR}          Cancel / Quit" ;;
        tree)
            ctxt=" 
${SB}Up${SR}/${SB}Down${SR}     Navigate (also ${SB}w${SR}/${SB}s${SR} and ${SB}j${SR}/${SB}k${SR})
${SB}Left${SR}/${SB}Right${SR}  Collapse / Expand (also ${SB}a${SR}/${SB}d${SR} and ${SB}h${SR}/${SB}l${SR})
${SB}PgUp${SR}/${SB}PgDn${SR}   Page scroll (also ${SB}J${SR}/${SB}K${SR})
${SB}Home${SR}/${SB}End${SR}    Jump to top/bottom (also ${SB}g${SR}/${SB}G${SR})
${SB}Enter${SR}       Select node
${SB}/${SR}           Focus filter (when enabled)
${SB}Tab${SR}         Toggle filter/tree (when enabled)
${SB}q${SR}           Quit" ;;
        table)
            ctxt=" 
${SB}Up${SR}/${SB}Down${SR}    Scroll (also ${SB}w${SR}/${SB}s${SR} and ${SB}j${SR}/${SB}k${SR})
${SB}PgUp${SR}/${SB}PgDn${SR}  Page scroll (also ${SB}J${SR}/${SB}K${SR})
${SB}Home${SR}/${SB}End${SR}   Jump to top/bottom (also ${SB}g${SR}/${SB}G${SR})
${SB}Enter${SR}      Select row
${SB}q${SR}          Cancel / Quit" ;;
        filtertable)
            ctxt=" 
${SB}Up${SR}/${SB}Down${SR}     Scroll results (also ${SB}w${SR}/${SB}s${SR} and ${SB}j${SR}/${SB}k${SR})
${SB}PgUp${SR}/${SB}PgDn${SR}   Page scroll (also ${SB}J${SR}/${SB}K${SR})
${SB}Home${SR}/${SB}End${SR}    Jump to top/bottom (also ${SB}g${SR}/${SB}G${SR})
${SB}Tab${SR}         Toggle focus (list or filter)
${SB}Left${SR}/${SB}Right${SR}  Move cursor in filter
${SB}Enter${SR}       Select row
${SB}q${SR}           Cancel / Quit" ;;
        mainmenu)
            ctxt=" 
${SB}Up${SR}/${SB}Down${SR}     Navigate sidebar or table (also ${SB}w${SR}/${SB}s${SR} and ${SB}j${SR}/${SB}k${SR})
${SB}Tab${SR}         Toggle sidebar / table focus
${SB}PgUp${SR}/${SB}PgDn${SR}   Page scroll (also ${SB}J${SR}/${SB}K${SR})
${SB}Home${SR}/${SB}End${SR}    Jump to top/bottom (also ${SB}g${SR}/${SB}G${SR})
${SB}/${SR}           Focus filter (in table view)
${SB}1-9${SR}         Sort by column
${SB}Enter${SR}       Select item / Run command
${SB}q${SR}           Quit" ;;
        kanban)
            ctxt=" 
${SB}w${SR}/${SB}a${SR}/${SB}s${SR}/${SB}d${SR}     Navigate (also ${SB}Arrows${SR} and ${SB}h${SR}/${SB}j${SR}/${SB}k${SR}/${SB}l${SR})
${SB}W${SR}/${SB}A${SR}/${SB}S${SR}/${SB}D${SR}     Move item (also ${SB}H${SR}/${SB}J${SR}/${SB}K${SR}/${SB}L${SR})
${SB}/${SR}           Search items
${SB}o${SR}           Cycle sort (by rank, modified, created, completed, due)
${SB}O${SR}           Toggle ascending/descending
${SB}Enter${SR}/${SB}e${SR}     Edit note in \\\$EDITOR
${SB}n${SR}           New note
${SB}t${SR}           Append tag
${SB}z${SR}/${SB}Z${SR}         Undo/redo
${SB}q${SR}           Quit" ;;
        *)
            return 1 ;;
    esac
    [ "$TUI_MODE" != "fullscreen" ] && BG_MODAL=$BG_MAIN
    modal "infobox 'Controls' \"$ctxt\""
    _init_tui
}

_draw_footer() {
    # Instead of clearing the whole terminal, we just clear the 
    # remaining lines inside the MAX_HEIGHT boundary.
    local current_row=$row
    while [ "$current_row" -lt "$MAX_HEIGHT" ]; do
        _draw_at "$current_row"
        printf "%*s" "$MAX_WIDTH" "" >&2
        current_row=$((current_row+1))
    done
}

_draw_btn() {
    local label=$1 is_active=$2
    
    if [ "$is_active" -eq 1 ]; then
        # Active: Blue BG + Bold
        printf "${HL_WHITE_BOLD} $label ${RESET}${BG_MAIN_ESC}" >&2
    else
        # Inactive: Widget Grey
        printf "${BG_WID_ESC}${FG_TEXT_ESC} $label ${RESET}${BG_MAIN_ESC}" >&2
    fi
}

_draw_item() {
    local type=$1 is_cur=$2 is_sel=$3 content=$4 width=${5:-30}
    local style px=""

    case "$type" in
        "check") [ "$is_sel" -eq 1 ] && px="[x] " || px="[ ] " ;;
        "radio") [ "$is_sel" -eq 1 ] && px="(*) " || px="( ) " ;;
        *) px="" ;;
    esac

    [ "$is_cur" -eq 1 ] && style="${HL_WHITE_BOLD}" || style="${BG_WID_ESC}${FG_TEXT_ESC}"

    printf "${style} %-${width}s ${RESET}${BG_MAIN_ESC}" "${px}${content}" >&2

}

_draw_form_field() {
    local label=$1 value=$2 is_active=$3 i=$4 width=$5 col_start=$6
    local _cp="${7:-}" _cs="${8:-}"

    local COL_START=$col_start

    _draw_at "$row"
    local style="" content=""

    # --- 1. INPUT & PASSWORD ---
    if _match "$label" ">*"; then
        local box_w=$(( width - 10 ))
        local clean_lbl="${label#\>* }"; [ "$clean_lbl" = "$label" ] && clean_lbl="${label#> }"; clean_lbl="${clean_lbl#* }"
        local prompt=" > "

        local suffix=""
        local box_w=$(( width - 5 ))

        local _is_pw=0
        case "$label" in ">*"*)
            _is_pw=1
            suffix=" 🔑 "
        ;; esac

        local display_val="$value"
        if [ "$is_active" -eq 1 ]; then
            if [ "$_is_pw" -eq 1 ]; then
                local _mp="${_cp//?/*}" _ms="${_cs//?/*}"
                if [ -n "$_cs" ]; then
                    local _cc="${_ms%"${_ms#?}"}" _cr="${_ms#?}"
                    display_val="${_mp}"$'\x1b[7m'"${_cc}"$'\x1b[27m'"${_cr}"
                else
                    display_val="${_mp}"$'\x1b[7m \x1b[27m'
                fi
            else
                if [ -n "$_cs" ]; then
                    local _cc="${_cs%"${_cs#?}"}" _cr="${_cs#?}"
                    display_val="${_cp}"$'\x1b[7m'"${_cc}"$'\x1b[27m'"${_cr}"
                else
                    display_val="${_cp}"$'\x1b[7m \x1b[27m'
                fi
            fi
        elif [ "$_is_pw" -eq 1 ]; then
            local _pw_i=0 _pw_stars=""
            while [ "$_pw_i" -lt "${#value}" ]; do _pw_stars="${_pw_stars}*"; _pw_i=$((_pw_i+1)); done
            display_val="$_pw_stars"
        fi

        if [ "$is_active" -eq 1 ]; then style="$FG_BLUE_BOLD"; else style="$FG_TEXT_ESC"; fi
        _draw_line "  ${style}${clean_lbl}:${RESET}${BG_MAIN_ESC}"

        if [ "$is_active" -eq 1 ]; then style="${BG_INPUT_ESC}${FG_BLUE_BOLD}"; else style="${BG_WID_ESC}${FG_TEXT_ESC}"; fi

        local _vlen=${#display_val}
        if [ "$is_active" -eq 1 ]; then
            _vlen=$(( ${#_cp} + ${#_cs} ))
            [ -z "$_cs" ] && _vlen=$((_vlen + 1))
        fi
        local _pad=$(( box_w - _vlen ))
        [ -n "$suffix" ] && _pad=$(( _pad - 4 ))
        [ "$_pad" -lt 0 ] && _pad=0

        local _tr=$(( row + PADDING_TOP ))
        local _tc=$(( PADDING_LEFT + COL_START ))
        printf "\e[%d;%dH${style}%*s\e[%d;%dH${BG_MAIN_ESC}  ${style}${prompt}%s%${_pad}s${suffix}${RESET}${BG_MAIN_ESC}" \
            "$_tr" "$(( _tc + 2 ))" "$(( width - 2 ))" "" \
            "$_tr" "$_tc" "$display_val" "" >&2
        row=$((row+1))
        _draw_spacer

    # --- 2. STANDALONE CHECKBOX OR RADIO ---
    elif _match "$label" "\[ \]*" || _match "$label" "(*"; then
        local marker="" indent="$INDENT"
        if [ "$is_active" -eq 1 ]; then style="$HL_WHITE_BOLD"; else style="${BG_MAIN_ESC}${FG_TEXT_ESC}"; fi
        
        if _match "$label" "\[ \]*"; then
            content="${label#\[ \] }"
            if [ "$value" = "1" ]; then marker="[x] "; else marker="[ ] "; fi
        else
            content="${label/( ) /}"
            if [ "$value" = "1" ]; then marker="(*) "; else marker="( ) "; fi
        fi
        indent="$INDENT"

        _draw_line "${indent}${style}${marker}${content}${RESET}${BG_MAIN_ESC}"
        
        local next_idx=$((i + 1))
        local _next_f=""; eval "_next_f=\"\$fields_$next_idx\""
        if _match "$label" "\[ \]*" && ! _match "$_next_f" "\[ \]*"; then
            _draw_spacer
        fi

    # --- 3. DROPDOWNS ---
    elif _match "$label" "{*"; then
        local v_rest="$value"
        local state="${v_rest%%|*}"; v_rest="${v_rest#*|}"
        local sel_idx="${v_rest%%|*}"; v_rest="${v_rest#*|}"
        local query="${v_rest%%|*}"; v_rest="${v_rest#*|}"
        local opt_str="$v_rest"
        
        if [ "$state" = "OPEN" ]; then local arrow="▴"; else local arrow="▾"; fi
        local header=""
        local label_text="${label#*\}}"
        label_text="${label_text# }"
        [ -n "$label_text" ] && header="$label_text: "
        if _match "$label" "{ }*" && [ "$state" = "OPEN" ]; then
            header="${header}[ $query ] $arrow"
        else
            local opt_display="${opt_str#*,}"
            _opt_idx=0; _opt_rest="$opt_str"
            while [ "$_opt_idx" -lt "$sel_idx" ] && _match "$_opt_rest" "*,*"; do
                _opt_rest="${_opt_rest#*,}"
                _opt_idx=$((_opt_idx + 1))
            done
            opt_display="${_opt_rest%%,*}"
            opt_display="${opt_display%:*}"
            header="${header}${opt_display} $arrow"
        fi
        # Pure shell padding
        while [ "${#header}" -lt "$width" ]; do header="${header} "; done
        
        if [ "$is_active" -eq 1 ]; then style="$FG_BLUE_BOLD"; else style="$FG_TEXT_ESC"; fi
        _draw_line "  ${style}${header}${RESET}${BG_MAIN_ESC}"
        _draw_spacer

    # --- 4. STATIC LABEL ---
    else
        _draw_line "  $label"
    fi
}

_draw_list() {
    _apply_layout
    local type=$1 title=$2 msg=$3 def_idx=$4; shift 4
    local count=$# cur=$def_idx top=0 i

    # Init selected booleans: sel_0, sel_1, ...
    i=0; while [ "$i" -lt "$count" ]; do eval "sel_$i=0"; i=$((i+1)); done

    if [ "$type" = "radio" ] || [ "$type" = "check" ]; then
        [ "$def_idx" -ge 0 ] && [ "$def_idx" -lt "$count" ] && eval "sel_$def_idx=1"
    fi

    TUI_RESULT=$def_idx

    _init_tui
    local width=$CONTENT_WIDTH

    while true; do
        _draw_header "$title" "$msg"
        local list_top=$row

        local _fh=$FOOTER_HEIGHT; [ "${TUI_HIDE_FOOTER:-false}" = "true" ] && _fh=0
        local max_h=$(( MAX_HEIGHT - list_top - _fh ))
        [ "$max_h" -lt $MIN_CONTENT_HEIGHT ] && max_h=$MIN_CONTENT_HEIGHT

        local display_count=$count
        [ "$display_count" -gt "$max_h" ] && display_count=$max_h

        [ "$cur" -lt "$top" ] && top=$cur
        [ "$cur" -ge "$((top + display_count))" ] && top=$((cur - display_count + 1))

        # 3. RENDER LIST
        i=0; while [ "$i" -lt "$display_count" ]; do
            local idx=$((top + i))
            row=$((list_top + i))
            _draw_at "$row"
            printf "$INDENT" >&2
            local is_cur=0; [ "$idx" -eq "$cur" ] && is_cur=1

            eval "sel_val=\$sel_$idx"
            eval "opt=\${$((idx+1))}"
            _draw_item "$type" "$is_cur" "$sel_val" "$opt" "$width"

            _draw_line "" "$row"
            i=$((i+1))
        done

        # 4. CONTROLS & FOOTER
        local hint=" ${SB}Up${SR}/${SB}Down${SR} Navigate | ${SB}Space${SR} Toggle | ${SB}Enter${SR} Select | ${SB}?${SR} Help"
        [ "$type" = "menu" ] && hint=" ${SB}Up${SR}/${SB}Down${SR} Navigate | ${SB}Enter${SR} Select | ${SB}q${SR} Quit"

        if [ "$_fh" -ne 0 ]; then
            _draw_controls_at_bottom "$hint"
        fi
        _draw_footer

        # --- INPUT HANDLING ---
        _read_key_esc
        _handle_extra_keys "$KEY" && continue

        if [ -n "$ESC_SEQ" ]; then
            case "$ESC_SEQ" in
                "[A"|"OA") [ "$cur" -gt 0 ] && cur=$((cur-1)) ;;
                "[B"|"OB") [ "$cur" -lt "$((count-1))" ] && cur=$((cur+1)) ;;
                "[5"|"[5~"|"5~")
                    local pg=$((cur - display_count))
                    [ "$pg" -lt 0 ] && pg=0
                    cur=$pg ;;
                "[6"|"[6~"|"6~")
                    local pg=$((cur + display_count))
                    [ "$pg" -ge "$count" ] && pg=$((count - 1))
                    cur=$pg ;;
                "[H") cur=0 ;;
                "[F") cur=$((count - 1)) ;;
                "[M"|"<0"|"<3"|"[<")
                    IFS=';' read -r m_btn < /dev/tty
                    IFS=';' read -r m_col < /dev/tty
                    read -r m_last < /dev/tty
                    local m_row="${m_last%[mM]}"
                    local idx=$(( m_row - PADDING_TOP - list_top ))
                    if [ "$idx" -ge 0 ] && [ "$idx" -lt "$display_count" ]; then
                        cur=$((top + idx))
                        case "$m_last" in
                            *M)
                                if [ "$type" = "menu" ]; then
                                    eval "TUI_RESULT=\${$((cur+1))}"
                                    echo "$TUI_RESULT"
                                    return 0
                                else
                                    KEY=" "
                                fi
                                ;;
                        esac
                    fi
                    ;;
            esac
            [ "$ESC_SEQ" != " " ] && continue
        fi

        if [ "$KEY" = " " ]; then
            if [ "$type" = "check" ]; then
                eval "v=\$sel_$cur"; eval "sel_$cur=$((1 - v))"
            elif [ "$type" = "radio" ]; then
                j=0; while [ "$j" -lt "$count" ]; do eval "sel_$j=0"; j=$((j+1)); done
                eval "sel_$cur=1"
            fi
        elif [ "$KEY" = "?" ]; then
            _help_popup list
        elif [ "$KEY" = "j" ] || [ "$KEY" = "s" ]; then
            [ "$cur" -lt "$((count - 1))" ] && cur=$((cur+1))
        elif [ "$KEY" = "k" ] || [ "$KEY" = "w" ]; then
            [ "$cur" -gt 0 ] && cur=$((cur-1))
        elif [ "$KEY" = "J" ]; then
            local pg=$((cur + display_count))
            [ "$pg" -ge "$count" ] && pg=$((count - 1))
            cur=$pg
        elif [ "$KEY" = "K" ]; then
            local pg=$((cur - display_count))
            [ "$pg" -lt 0 ] && pg=0
            cur=$pg
        elif [ "$KEY" = "g" ]; then
            cur=0
        elif [ "$KEY" = "G" ]; then
            cur=$((count - 1))
        elif [ "$KEY" = "q" ]; then
            TUI_RESULT=''
            return 1
        elif [ -z "$KEY" ]; then
            if [ "$type" = "menu" ]; then
                eval "TUI_RESULT=\${$((cur+1))}"
                echo "$TUI_RESULT"
                return 0
            else
                local res=""
                i=0; while [ "$i" -lt "$count" ]; do
                    eval "v=\$sel_$i"
                    if [ "$v" -eq 1 ]; then
                        eval "opt=\${$((i+1))}"
                        res="${res}${opt}"$'\n'
                    fi
                    i=$((i+1))
                done
                TUI_RESULT="${res%$'\n'}"
                echo "$TUI_RESULT"
                return 0
            fi
        fi
    done
}

# --- Widgets ---

# _list_widget: dispatcher for menu/checklist/radiolist
# Handles --file mode, numeric-default, and no-default cases.
_list_widget() {
    local type=$1 t=$2 m=$3 d=0
    shift 3
    if [ "$1" = "--file" ]; then
        local _file=$2 _line
        shift 2
        set --
        while IFS= read -r _line; do
            [ -z "$_line" ] && continue
            set -- "$@" "$_line"
        done < "$_file"
    else
        if _is_numeric "$1"; then
            d=$(($1 - 1))
            shift
        fi
    fi
    _draw_list "$type" "$t" "$m" "$d" "$@"
}

# _tree_widget: dispatcher for tree/configtree
# Handles --file mode, numeric-default, and no-default cases.
_tree_widget() {
    local type=$1 t=$2 m=$3 d=0
    shift 3
    if [ "$1" = "--file" ]; then
        local _file=$2 _line
        shift 2
        set --
        while IFS= read -r _line; do
            [ -z "$_line" ] && continue
            set -- "$@" "$_line"
        done < "$_file"
    else
        if _is_numeric "$1"; then
            d=$(($1 - 1))
            shift
        fi
    fi
    _tree_core "$type" "$t" "$m" "$d" "$@"
}

menu() {
    _list_widget "menu" "$@"
}

checklist() {
    _list_widget "check" "$@"
}

radiolist() {
    _list_widget "radio" "$@"
}

msgbox() {
    local title=$1 msg=$2 key
    _init_tui
    while true; do
        _draw_header "$title" "$msg"
        
        _draw_at "$row"
        printf "$INDENT" >&2
        _draw_btn "$OK_LABEL" 1
        _draw_line ""
        _draw_footer
        
        _read_key key
        _handle_extra_keys "$key" && continue
        [ -z "$key" ] && TUI_RESULT='' && return 0
    done
}

yesno() {
    local title=$1 msg=$2 cur
    cur=$(( ${3:-1} - 1 ))
    
    _init_tui
    while true; do
        _draw_header "$title" "$msg"
        
        _draw_at "$row"
        printf "$INDENT" >&2
        if [ "$cur" -eq 0 ]; then _draw_btn "$YES_LABEL" 1; else _draw_btn "$YES_LABEL" 0; fi
        printf "$INDENT" >&2
        if [ "$cur" -eq 1 ]; then _draw_btn "$NO_LABEL" 1; else _draw_btn "$NO_LABEL" 0; fi
        
        _draw_line "" "$row"
        [ "${TUI_HIDE_FOOTER:-false}" != "true" ] && _draw_controls_at_bottom " ${SB}Left${SR}/${SB}Right${SR} Focus | ${SB}Enter${SR} Confirm | ${SB}Esc${SR} Cancel"
        _draw_footer

        local key
        _read_key key
        _handle_extra_keys "$key" && continue
        
        if [ "$key" = "$_ESC" ]; then
            _read_str_timeout 2 key
            if [ "$key" = "[C" ] || [ "$key" = "[D" ] || [ "$key" = "OC" ] || [ "$key" = "OD" ]; then
                cur=$(( 1 - cur ))
            fi
            continue
        fi
        
        if [ -z "$key" ]; then
            [ "$cur" -eq 0 ] && TUI_RESULT=true
            [ "$cur" -eq 1 ] && TUI_RESULT=false
            return $cur
        fi
    done
}

inputbox() { _input_core text "$@"; }

passwordbox() { _input_core password "$@"; }

_input_core() {
    local _is_pw=0
    [ "$1" = "password" ] && _is_pw=1
    shift
    local title=$1 msg=$2 val="${3:-}" char key _escape
    local cursor_prefix="$val" cursor_suffix=""
    _init_tui
    _draw_header "$title" "$msg"

    local input_row=$row
    local phys_row=$((input_row + PADDING_TOP))
    local _dp _ds

    _escape="$_ESC"

    while true; do
        if [ "$_is_pw" -eq 1 ]; then
            _dp="${cursor_prefix//?/*}"; _ds="${cursor_suffix//?/*}"
        else
            _dp="$cursor_prefix"; _ds="$cursor_suffix"
        fi

        _render_cursor_display "$_dp" "$_ds"

        local _pad=$(( INPUT_WIDTH - _VIS_LEN ))
        [ "$_pad" -lt 0 ] && _pad=0

        _hide_cursor
        _draw_at "$input_row"
        printf "  ${BG_INPUT_ESC}${FG_INPUT_ESC} > %s%${_pad}s ${RESET}${BG_MAIN_ESC}" "$_DISPLAY" "" >&2
        [ "${TUI_HIDE_FOOTER:-false}" != "true" ] && _draw_controls_at_bottom " ${SB}Enter${SR} Confirm | ${SB}Esc${SR} Cancel"
        _draw_footer

        _read_key char
        _handle_extra_keys "$char" && continue

        if [ "$char" = "$_escape" ]; then
            local _del_c="" next_chars=""
            _read_str_timeout 2 next_chars

            case "$next_chars" in
                "[D"|"OD") _cursor_left cursor_prefix cursor_suffix ;;
                "[C"|"OC") _cursor_right cursor_prefix cursor_suffix ;;
                "[3") _read_str_timeout 1 _del_c
                    [ "$_del_c" = "~" ] && [ -n "$cursor_suffix" ] && cursor_suffix="${cursor_suffix#?}"
                    ;;
                "") _hide_cursor; TUI_RESULT=''; return 1 ;;
                *)
                    read -t 0 < /dev/tty 2>/dev/null && read -r -n 5 _flush < /dev/tty 2>/dev/null || true
                    ;;
            esac
            continue
        elif [ -z "$char" ]; then
            break
        elif [ "$char" = "$_TAB" ]; then
            continue
        elif [ "$char" = "$_DEL" ] || [ "$char" = "$_BS" ]; then
            cursor_prefix="${cursor_prefix%?}"
        else
            cursor_prefix="${cursor_prefix}${char}"
        fi

        local _combined="${cursor_prefix}${cursor_suffix}"
        if [ "${#_combined}" -gt $INPUT_WIDTH ]; then
            local _suffix_room=$(( INPUT_WIDTH - ${#cursor_prefix} ))
            [ "$_suffix_room" -lt 0 ] && _suffix_room=0
            cursor_suffix="${cursor_suffix:0:$_suffix_room}"
        fi
    done

    _hide_cursor
    snap_line=$(printf "%*s" "$MAX_WIDTH" "")
    printf "\e[${phys_row};${PADDING_LEFT}H${BG_MAIN_ESC}%s" "$snap_line" >&2

    [ "$_is_pw" -eq 1 ] && _draw_footer

    val="${cursor_prefix}${cursor_suffix}"
    TUI_RESULT="$val"
    echo "$val"
    return 0
}

infobox() {
    local title=$1 msg=$2 key
    _init_tui

    _draw_header "$title" "$msg"

    _draw_footer

    if [ "$TUI_MODAL" = "true" ]; then
        _read_key key
    fi
}

gauge() {
    local title=$1 msg=$2 pct
    # Standardise width
    local bar_width=40
    
    _init_tui
    # Non-blocking read from stdin (allows piping like: seq 1 100 | gauge "Title")
    while read -r pct; do
        # 1. Surgical Redraw of Header
        _draw_header "$title" "$msg"

        # 2. Capture the actual starting point
        local start_row=$row
        local fill=$((pct * bar_width / 100))
        local empty=$((bar_width - fill))

        # 3. Render Progress Bar Zone
        _draw_at "$start_row" 0
        printf "$INDENT" >&2 # Left margin
        
        # Draw Fill (Blue) and Empty (Grey)
        printf "${BG_BLUE_ESC}%*s${BG_WID_ESC}%*s${RESET}" "$fill" "" "$empty" "" >&2
        
        # THE FIX: Apply BG_MAIN_ESC to the percentage text so it doesn't look like a black hole
        printf "${BG_MAIN_ESC} ${FG_TEXT_ESC}${pct}%%${RESET}" >&2

        # 4. Snap the background to the right edge
        row=$start_row
        _draw_line "" 

        # 6. Position footer at the bottom
        row=$CONTROLS_ROW
        _draw_footer
    done
    return 0
}


textbox() {
    local title=$1 msg=$2 src=$3 top=0
    local last_top=-1

    [ ! -f "$src" ] && { msgbox "Error" "File not found: $src"; return 1; }

    local count=$(wc -l < "$src")
    local tmpf=$(mktemp /tmp/tui_tb.XXXXXX)

    _init_tui
    local box_width=$CONTENT_WIDTH
    while true; do
        if [ "$top" -ne "$last_top" ]; then
            _draw_header "$title" "$msg"

            local view_top=$row
local _fh=$FOOTER_HEIGHT; [ "${TUI_HIDE_FOOTER:-false}" = "true" ] && _fh=0
            local height=$(( MAX_HEIGHT - view_top - _fh ))
            [ "$height" -lt $MIN_CONTENT_HEIGHT ] && height=$MIN_CONTENT_HEIGHT

            sed -n "$((top + 1)),$((top + height))p" "$src" > "$tmpf"

            i=0; while IFS= read -r rl && [ "$i" -lt "$height" ]; do
                local current_view_row=$((view_top + i))

                _draw_at "$current_view_row"
                printf "$INDENT" >&2

                local content="${rl//$'\t'/    }"
                content="${content:0:$box_width}"
                _draw_item "text" 0 0 "$content" "$box_width"

                _draw_line "" "$current_view_row"
                i=$((i+1))
            done < "$tmpf"

            # fill remaining rows with blanks
            while [ "$i" -lt "$height" ]; do
                local current_view_row=$((view_top + i))
                _draw_at "$current_view_row"
                printf "$INDENT" >&2
                _draw_item "text" 0 0 "" "$box_width"
                _draw_line "" "$current_view_row"
                i=$((i+1))
            done

            row=$((view_top + height))
            if [ "$_fh" -ne 0 ]; then
                _draw_line "" 
                _draw_controls " ${SB}Up${SR}/${SB}Down${SR} Scroll | ${SB}PgUp${SR}/${SB}PgDn${SR} Page | ${SB}Home${SR}/${SB}End${SR} Jump | ${SB}Enter${SR} Close"
            fi
            _draw_footer
            last_top=$top
        fi

        _read_key_esc
        _handle_extra_keys "$KEY" && continue

        if [ -n "$ESC_SEQ" ]; then
            case "$ESC_SEQ" in
                "[A"|"OA") [ "$top" -gt 0 ] && top=$((top-1)) ;;
                "[B"|"OB") [ "$((top + height))" -lt "$count" ] && top=$((top+1)) ;;
                "[5"|"[5~"|"5~") [ "$top" -gt 0 ] && top=$((top - height + 1)); [ "$top" -lt 0 ] && top=0 ;;
                "[6"|"[6~"|"6~") [ "$((top + height))" -lt "$count" ] && top=$((top + height - 1)); [ "$top" -gt "$((count - height))" ] && top=$((count - height)) ;;
                "[H") top=0 ;;
                "[F") top=$((count - height)); [ "$top" -lt 0 ] && top=0 ;;
            esac
        elif [ "$KEY" = "k" ] || [ "$KEY" = "w" ]; then
            [ "$top" -gt 0 ] && top=$((top-1))
        elif [ "$KEY" = "j" ] || [ "$KEY" = "s" ]; then
            [ "$((top + height))" -lt "$count" ] && top=$((top+1))
        elif [ "$KEY" = "K" ]; then
            [ "$top" -gt 0 ] && top=$((top - height + 1)); [ "$top" -lt 0 ] && top=0
        elif [ "$KEY" = "J" ]; then
            [ "$((top + height))" -lt "$count" ] && top=$((top + height - 1)); [ "$top" -gt "$((count - height))" ] && top=$((count - height))
        elif [ "$KEY" = "g" ]; then
            top=0
        elif [ "$KEY" = "G" ]; then
            top=$((count - height)); [ "$top" -lt 0 ] && top=0
        elif [ "$KEY" = "q" ]; then
            rm -f "$tmpf"
            return 0
        elif [ -z "$KEY" ]; then
            rm -f "$tmpf"
            return 0
        fi
    done
}

tailbox() {
    local title=$1 msg=$2 src=$3 key
    [ ! -f "$src" ] && { msgbox "Error" "File not found: $src"; return 1; }

    local count=$(wc -l < "$src")

    _init_tui
    local box_width=$CONTENT_WIDTH_WIDE
    local tmpf=$(mktemp /tmp/tui_tail.XXXXXX)
    while true; do
        _draw_header "$title" "$msg"

        local view_top=$row
        local _fh=$FOOTER_HEIGHT; [ "${TUI_HIDE_FOOTER:-false}" = "true" ] && _fh=0
        local height=$(( MAX_HEIGHT - view_top - _fh ))
        [ "$height" -lt $MIN_CONTENT_HEIGHT ] && height=$MIN_CONTENT_HEIGHT

        local top=$(( count - height ))
        [ "$top" -lt 0 ] && top=0

        sed -n "$((top + 1)),$((top + height))p" "$src" > "$tmpf"

        i=0; while IFS= read -r _tail_line && [ "$i" -lt "$height" ]; do
            local current_view_row=$((view_top + i))

            _draw_at "$current_view_row" 0
            printf "${BG_MAIN_ESC}  " >&2

            local content="${_tail_line//$'\t'/    }"
            content="${content:0:$box_width}"
            printf "${BG_WID_ESC}${FG_TEXT_ESC}%-${box_width}.${box_width}s${RESET}" "$content" >&2

            printf "${BG_MAIN_ESC}  ${RESET}" >&2
            row=$CONTROLS_ROW
            i=$((i+1))
        done < "$tmpf"

        while [ "$i" -lt "$height" ]; do
            local current_view_row=$((view_top + i))
            _draw_at "$current_view_row" 0
            printf "${BG_MAIN_ESC}  " >&2
            printf "${BG_WID_ESC}%${box_width}s${RESET}" "" >&2
            printf "${BG_MAIN_ESC}  ${RESET}" >&2
            row=$CONTROLS_ROW
            i=$((i+1))
        done

        _draw_at "$((row - 1))" 0
        printf "${BG_MAIN_ESC}%*s${RESET}" "$MAX_WIDTH" "" >&2

        [ "$_fh" -ne 0 ] && _draw_controls " Watching: ${src##*/} | ${SB}Enter${SR} Close"
        _draw_footer

        _read_key_esc
        _handle_extra_keys "$KEY" && continue
        if [ -z "$KEY" ]; then
            rm -f "$tmpf"
            return 0
        fi
    done
}

# Filter comma-separated options against a query, sets filtered_N globals and FILTERED_COUNT
_filter_opts() {
    local _fq="$1" _opts="$2"
    local _lq=$(_tolower "$_fq")
    local _fi=0
    local _old_ifs="$IFS"; IFS=','
    set -- $_opts
    for _o do
        local _lo=$(_tolower "$_o")
        if [ -z "$_fq" ] || _match "$_lo" "*${_lq}*"; then
            eval "filtered_$_fi='$_o'"
            _fi=$((_fi+1))
        fi
    done
    IFS="$_old_ifs"
    FILTERED_COUNT=$_fi
}

form() {
    local title=$1 msg=$2; shift 2
    local count=$#
    local cur=0 i
    local _cursor_prefix="" _cursor_suffix=""

    # --- 1. DSL PRE-PARSER (Fixed to preserve TUI markers) ---
    i=0; while [ "$i" -lt "$count" ]; do
        set -- "$@"
        eval "line=\${$((i+1))}"

        if _match "$line" "---"; then
            eval "fields_$i='---'"
            eval "values_$i=''"
            eval "field_meta_$i='sep'"

        # --- INPUT & PASSWORD ---
        elif _match "$line" ">*"; then
            local prefix="> "
            case "$line" in ">* "*) prefix=">* " ;; esac

            local content="${line#$prefix}"
            local label_var="${content%%=*}"
            local val="${content#*=}"
            [ "$val" = "$content" ] && val=""

            local lbl="${label_var%%:*}"
            local var="${label_var#*:}"
            [ "$var" = "$lbl" ] && var=$(_tolower "$lbl")

            eval "fields_$i='${prefix}${lbl}'"
            eval "values_$i='$val'"
            eval "field_meta_$i='input|$var'"

        # --- CHECKBOX ---
        elif _match "$line" "[*"; then
            local content="${line:4}"
            local lbl="${content%%:*}"
            local var="${content#*:}"

            eval "fields_$i='[ ] ${lbl}'"
            _match "$line" "*\[x\]*" && eval "values_$i=1" || eval "values_$i=0"
            eval "field_meta_$i='check|$var'"

        # --- RADIO ---
        elif _match "$line" "(*"; then
            local content="${line:4}"
            local lbl="${content%%:*}"
            local var="${content#*:}"

            eval "fields_$i='( ) ${lbl}'"
            _match "$line" "*\([*]\)*" && eval "values_$i=1" || eval "values_$i=0"
            eval "field_meta_$i='radio|$var'"

        # --- DROPDOWN ---
        elif _match "$line" "{ *"; then
            local content="${line#\{ \} }"
            local default_idx=0 idx=0 joined=""
            local old_ifs="$IFS"; IFS=','
            for _opt in $content; do
                local cleaned="$_opt"
                if _match "$cleaned" "=*"; then
                    default_idx=$idx
                    cleaned="${cleaned#=}"
                fi
                joined="${joined}${cleaned},"
                idx=$((idx+1))
done <<_EOF_
$_kb_manifest
_EOF_
            joined="${joined%,}"
            eval "fields_$i='{ }'"
            eval "values_$i='CLOSED|$default_idx||$joined'"
            eval "field_meta_$i='dropdown'"
        else
            eval "fields_$i='$line'"
            eval "values_$i=''"
            eval "field_meta_$i='text'"
        fi
        i=$((i+1))
    done

    # Pre-compute field heights for two-column split logic
    i=0; while [ "$i" -lt "$count" ]; do
        eval "f=\"\$fields_$i\""
        local _fh=1
        if _match "$f" "---"; then
            _fh=2
        elif _match "$f" ">*" || _match "$f" "> "; then
            _fh=3
        elif _match "$f" "{*"; then
            _fh=2
        elif _match "$f" "\[ \]*"; then
            _fh=1
            local _ni=$((i + 1))
            if [ "$_ni" -lt "$count" ]; then
                eval "_nf=\"\$fields_$_ni\""
                ! _match "$_nf" "\[ \]*" && _fh=2
            else
                _fh=2
            fi
        fi
        eval "field_height_$i=$_fh"
        i=$((i+1))
    done

    # Initialize cursor state for first field
    eval "cf=\"\$fields_0\""
    if _match "$cf" ">*"; then
        eval "_cursor_prefix=\"\$values_0\""
        eval "_cursor_suffix=\"\$cur_sfx_0\""
    fi

    _init_tui

    # 2. Width: Exactly 2 spaces less than half of the current MAIN_BG
    local form_width=$(( (MAX_WIDTH / 2) - 2 ))

    # 3. Alignment: Start at the left of the container
    local COL_START=0

    local _dd_was_open=0
    local _dd_field=0
    local _dd_count=0
    local _dd_col_start=0
    local _dd_open_row=0

    while true; do
        _draw_header "$title" "$msg"
        local _header_row=$row

        # Determine if 2-column mode is needed
        local total_h=0
        i=0; while [ "$i" -lt "$count" ]; do
            eval "h=\$field_height_$i"
            total_h=$((total_h + h))
            i=$((i+1))
        done
        local avail_h=$(( CONTROLS_ROW - _header_row - 1 ))
        local two_column=0
        local split_idx=$count
        local left_end=$row
        if [ "$total_h" -gt "$avail_h" ] && [ "$count" -gt 2 ]; then
            two_column=1
            local right_col_start=$(( ((MAX_WIDTH + 1) / 2) - 5 ))
            local right_width=$(( form_width + 2 ))
            local col_h=0
            i=0; while [ "$i" -lt "$count" ]; do
                eval "h=\$field_height_$i"
                [ $((col_h + h)) -gt "$avail_h" ] && { split_idx=$i; break; }
                col_h=$((col_h + h))
                i=$((i+1))
            done
        fi

        if [ "$two_column" -eq 1 ]; then
            local left_width=$(( form_width - 4 ))
            # Render left column (0..split_idx-1)
            i=0; while [ "$i" -lt "$split_idx" ]; do
                local active=0
                [ "$i" -eq "$cur" ] && active=1
                eval "field_rows_$i=$row"
                eval "field_colstart_$i=$COL_START"
                eval "f=\"\$fields_$i\""
                eval "v=\"\$values_$i\""
                if _match "$f" "---"; then
                    _draw_at "$row"
                    local box_w=$(( left_width - 2 ))
                    local dashes
                    dashes=$(printf "%*s" "$box_w" "")
                    dashes="${dashes// /-}"
                    printf "  ${FG_HINT_ESC}%s${RESET}${BG_MAIN_ESC}" "$dashes" >&2
                    row=$((row+2))
                else
                    _draw_form_field "$f" "$v" "$active" "$i" "$left_width" "$COL_START" "$_cursor_prefix" "$_cursor_suffix"
                fi
                i=$((i+1))
            done
            left_end=$row

            # Render right column (split_idx..count-1)
            row=$_header_row
            i=$split_idx; while [ "$i" -lt "$count" ]; do
                local active=0
                [ "$i" -eq "$cur" ] && active=1
                eval "field_rows_$i=$row"
                eval "field_colstart_$i=$right_col_start"
                eval "f=\"\$fields_$i\""
                eval "v=\"\$values_$i\""
                if _match "$f" "---"; then
                    _draw_at "$row" "$right_col_start"
                    local box_w=$(( right_width - 2 ))
                    local dashes
                    dashes=$(printf "%*s" "$box_w" "")
                    dashes="${dashes// /-}"
                    printf "  ${FG_HINT_ESC}%s${RESET}${BG_MAIN_ESC}" "$dashes" >&2
                    row=$((row+2))
                else
                    _draw_form_field "$f" "$v" "$active" "$i" "$right_width" "$right_col_start" "$_cursor_prefix" "$_cursor_suffix"
                fi
                i=$((i+1))
            done
            local right_end=$row
            row=$(( left_end > right_end ? left_end : right_end ))
        else
            # Single column (original behavior)
            i=0; while [ "$i" -lt "$count" ]; do
                local active=0
                [ "$i" -eq "$cur" ] && active=1
                eval "field_rows_$i=$row"
                eval "field_colstart_$i=$COL_START"
                eval "f=\"\$fields_$i\""
                eval "v=\"\$values_$i\""
                if _match "$f" "---"; then
                    _draw_at "$row"
                    local box_w=$(( form_width - 2 ))
                    local dashes
                    dashes=$(printf "%*s" "$box_w" "")
                    dashes="${dashes// /-}"
                    printf "  ${FG_HINT_ESC}%s${RESET}${BG_MAIN_ESC}" "$dashes" >&2
                    row=$((row+2))
                else
                    _draw_form_field "$f" "$v" "$active" "$i" "$form_width" "$COL_START" "$_cursor_prefix" "$_cursor_suffix"
                fi
                i=$((i+1))
            done
        fi
        
        _draw_footer

        eval "f_cur=\"\$fields_$cur\""
        if [ "$cur" -lt "$count" ] && _match "$f_cur" "{*"; then
            eval "v_cur=\"\$values_$cur\""
            _v_rest="$v_cur"
            state="${_v_rest%%|*}"; _v_rest="${_v_rest#*|}"
            s_idx="${_v_rest%%|*}"; _v_rest="${_v_rest#*|}"
            query="${_v_rest%%|*}"; _v_rest="${_v_rest#*|}"
            opts="$_v_rest"

            if [ "$state" = "OPEN" ]; then
                eval "fc=\$field_colstart_$cur"
                oi=0; while [ "$oi" -lt "$_dd_count" ]; do
                    local cr=$((_dd_open_row + oi))
                    [ "$cr" -lt "$MAX_HEIGHT" ] && { _draw_at "$cr" "$fc"; local _cw=$(( MAX_WIDTH - fc )); [ "$_cw" -lt 0 ] && _cw=0; printf "%*s" "$_cw" "" >&2; }
                    oi=$((oi+1))
                done
                _filter_opts "$query" "$opts"
                eval "drow=\$((field_rows_$cur + 1))"
                j=0; while [ "$j" -lt "$FILTERED_COUNT" ]; do
                    _draw_at "$drow" "$fc"
                    printf "$INDENT" >&2
                    eval "odisp=\"\$filtered_$j\""
                    local opt_display="${odisp%:*}"
                    local is_active=0; [ "$j" -eq "$s_idx" ] && is_active=1
                    _draw_item "menu" "$is_active" 0 "$opt_display" "$form_width"
                    drow=$((drow+1))
                    j=$((j+1))
                done
                row=$((drow > row ? drow : row))
                _dd_field=$cur
                _dd_count=$FILTERED_COUNT
                eval "_dd_open_row=\$((field_rows_$cur + 1))"
                _dd_col_start=$fc
                _dd_was_open=1
            elif [ "$_dd_was_open" -eq 1 ]; then
                oi=0; while [ "$oi" -lt "$_dd_count" ]; do
                    local cr=$((_dd_open_row + oi))
                    [ "$cr" -lt "$MAX_HEIGHT" ] && { _draw_at "$cr" "$_dd_col_start"; local _cw=$(( MAX_WIDTH - _dd_col_start )); [ "$_cw" -lt 0 ] && _cw=0; printf "%*s" "$_cw" "" >&2; }
                    oi=$((oi+1))
                done
                local saved_row=$row
                local last_clear=$((_dd_open_row + _dd_count))
                i=$((_dd_field+1)); while [ "$i" -lt "$count" ]; do
                    eval "fr=\$field_rows_$i"
                    if [ "$fr" -ge "$_dd_open_row" ] && [ "$fr" -lt "$last_clear" ]; then
                        row=$fr
                        eval "fv=\"\$fields_$i\""
                        eval "vv=\"\$values_$i\""
                        eval "fc=\$field_colstart_$i"
                        _draw_form_field "$fv" "$vv" 0 "$i" "$form_width" "$fc"
                    fi
                    i=$((i+1))
                done
                row=$saved_row
                _dd_was_open=0
            else
                _dd_was_open=0
            fi
        elif [ "$_dd_was_open" -eq 1 ]; then
            oi=0; while [ "$oi" -lt "$_dd_count" ]; do
                local cr=$((_dd_open_row + oi))
                [ "$cr" -lt "$MAX_HEIGHT" ] && { _draw_at "$cr" "$_dd_col_start"; local _cw=$(( MAX_WIDTH - _dd_col_start )); [ "$_cw" -lt 0 ] && _cw=0; printf "%*s" "$_cw" "" >&2; }
                oi=$((oi+1))
            done
            _dd_was_open=0
        fi

        [ "${TUI_HIDE_FOOTER:-false}" != "true" ] && _draw_controls_at_bottom " ${SB}Tab${SR}/${SB}Up${SR}/${SB}Down${SR} Navigate | ${SB}Space${SR} Toggle | ${SB}Enter${SR} Submit | ${SB}?${SR} Help"

        local key
        _read_key key
        _handle_extra_keys "$key" && continue

        if [ "$key" = "$_ESC" ]; then
            _read_str_timeout 2 key

            eval "v_cur=\"\$values_$cur\""
            _v_rest="$v_cur"
            state="${_v_rest%%|*}"; _v_rest="${_v_rest#*|}"
            s_idx="${_v_rest%%|*}"; _v_rest="${_v_rest#*|}"
            query="${_v_rest%%|*}"; _v_rest="${_v_rest#*|}"; opts="$_v_rest"

            if [ "$state" = "OPEN" ]; then
                _filter_opts "$query" "$opts"
                [ "$key" = "[A" ] || [ "$key" = "OA" ] && [ "$s_idx" -gt 0 ] && s_idx=$((s_idx-1))
                [ "$key" = "[B" ] || [ "$key" = "OB" ] && [ "$s_idx" -lt "$((FILTERED_COUNT-1))" ] && s_idx=$((s_idx+1))
                eval "values_$cur='$state|$s_idx|$query|$opts'"; continue
            else
                if [ "$key" = "[C" ] || [ "$key" = "OC" ]; then
                    eval "cf=\"\$fields_$cur\""
                    if _match "$cf" ">*" && [ -n "$_cursor_suffix" ]; then
                        _cursor_right _cursor_prefix _cursor_suffix
                        eval "values_$cur=\"\${_cursor_prefix}\${_cursor_suffix}\""
                    fi
                elif [ "$key" = "[D" ] || [ "$key" = "OD" ]; then
                    eval "cf=\"\$fields_$cur\""
                    if _match "$cf" ">*" && [ -n "$_cursor_prefix" ]; then
                        _cursor_left _cursor_prefix _cursor_suffix
                        eval "values_$cur=\"\${_cursor_prefix}\${_cursor_suffix}\""
                    fi
                elif [ "$key" = "[3" ]; then
                    _read_str_timeout 1 _del_c
                    eval "cf=\"\$fields_$cur\""
                    if _match "$cf" ">*" && [ "$_del_c" = "~" ] && [ -n "$_cursor_suffix" ]; then
                        _cursor_suffix="${_cursor_suffix#?}"
                        eval "values_$cur=\"\${_cursor_prefix}\${_cursor_suffix}\""
                    fi
                elif [ "$key" = "[A" ] || [ "$key" = "OA" ]; then
                    eval "cf=\"\$fields_$cur\""
                    if _match "$cf" ">*"; then
                        eval "cur_pfx_$cur=\"$_cursor_prefix\""
                        eval "cur_sfx_$cur=\"$_cursor_suffix\""
                        eval "values_$cur=\"\${_cursor_prefix}\${_cursor_suffix}\""
                    fi
                    while [ "$cur" -gt 0 ]; do
                        cur=$((cur-1))
                        eval "cf=\"\$fields_$cur\""
                        _is_interactive_field "$cf" && break
                    done
                    eval "cf=\"\$fields_$cur\""
                    if _match "$cf" ">*"; then
                        eval "_cursor_prefix=\"\$cur_pfx_$cur\""
                        [ -z "$_cursor_prefix" ] && eval "_cursor_prefix=\"\$values_$cur\""
                        eval "_cursor_suffix=\"\$cur_sfx_$cur\""
                    fi
                elif [ "$key" = "[B" ] || [ "$key" = "OB" ]; then
                    eval "cf=\"\$fields_$cur\""
                    if _match "$cf" ">*"; then
                        eval "cur_pfx_$cur=\"$_cursor_prefix\""
                        eval "cur_sfx_$cur=\"$_cursor_suffix\""
                        eval "values_$cur=\"\${_cursor_prefix}\${_cursor_suffix}\""
                    fi
                    while [ "$cur" -lt "$((count-1))" ]; do
                        cur=$((cur+1))
                        eval "cf=\"\$fields_$cur\""
                        _is_interactive_field "$cf" && break
                    done
                    eval "cf=\"\$fields_$cur\""
                    if _match "$cf" ">*"; then
                        eval "_cursor_prefix=\"\$cur_pfx_$cur\""
                        [ -z "$_cursor_prefix" ] && eval "_cursor_prefix=\"\$values_$cur\""
                        eval "_cursor_suffix=\"\$cur_sfx_$cur\""
                    fi
                else
                    read -t 0 < /dev/tty 2>/dev/null && read -r -n 5 _flush < /dev/tty 2>/dev/null || true
                fi
            fi
            continue
        fi

        _tab="$_TAB"
        _bs="$_DEL"
        _del="$_BS"

        case "$key" in
            "$_tab")
                eval "cf=\"\$fields_$cur\""
                if _match "$cf" ">*"; then
                    eval "cur_pfx_$cur=\"$_cursor_prefix\""
                    eval "cur_sfx_$cur=\"$_cursor_suffix\""
                    eval "values_$cur=\"\${_cursor_prefix}\${_cursor_suffix}\""
                fi
                while true; do
                    cur=$((cur+1))
                    [ "$cur" -eq "$count" ] && cur=0
                    eval "cf=\"\$fields_$cur\""
                    _match "$cf" ">*" || _match "$cf" "[*" || _match "$cf" "(*" || _match "$cf" "{*" && break
                done
                eval "cf=\"\$fields_$cur\""
                if _match "$cf" ">*"; then
                    eval "_cursor_prefix=\"\$cur_pfx_$cur\""
                    [ -z "$_cursor_prefix" ] && eval "_cursor_prefix=\"\$values_$cur\""
                    eval "_cursor_suffix=\"\$cur_sfx_$cur\""
                fi ;;
            " ")
                eval "v_cur=\"\$values_$cur\""
                _v_rest="$v_cur"
                state="${_v_rest%%|*}"; _v_rest="${_v_rest#*|}"
                s_idx="${_v_rest%%|*}"; _v_rest="${_v_rest#*|}"
                query="${_v_rest%%|*}"; _v_rest="${_v_rest#*|}"; opts="$_v_rest"
                eval "cf=\"\$fields_$cur\""

                if _match "$cf" "{*"; then
            if [ "$state" = "OPEN" ]; then
                oi=0; while [ "$oi" -lt "$_dd_count" ]; do
                    local cr=$((_dd_open_row + oi))
                    [ "$cr" -lt "$MAX_HEIGHT" ] && { _draw_at "$cr" "$_dd_col_start"; local _cw=$(( MAX_WIDTH - _dd_col_start )); [ "$_cw" -lt 0 ] && _cw=0; printf "%*s" "$_cw" "" >&2; }
                    oi=$((oi+1))
                done
                _filter_opts "$query" "$opts"
                        eval "picked=\"\$filtered_$s_idx\""
                        local idx=0
                        local old_ifs2="$IFS"; IFS=','
                        set -- $opts
                        for orig_opt do
                            [ "$orig_opt" = "$picked" ] && { eval "values_$cur='CLOSED|$idx||$opts'"; break; }
                            idx=$((idx+1))
                        done
                        IFS="$old_ifs2"
                        IFS="$old_ifs"
                    else
                        eval "values_$cur='OPEN|0||$opts'"
                    fi
                elif _match "$cf" "[*"; then
                    eval "old=\${values_$cur:-0}"
                    eval "values_$cur=$((1 - old))"
                elif _match "$cf" "(*"; then
                    s=$cur; while [ "$s" -gt 0 ]; do
                        eval "pf=\"\$fields_$((s-1))\""
                        _match "$pf" "(*" && s=$((s-1)) || break
                    done
                    e=$cur; while [ "$e" -lt "$((count-1))" ]; do
                        eval "nf=\"\$fields_$((e+1))\""
                        _match "$nf" "(*" && e=$((e+1)) || break
                    done
                    j=$s; while [ "$j" -le "$e" ]; do eval "values_$j=0"; j=$((j+1)); done
                    eval "values_$cur=1"
                else
                    _cursor_prefix="${_cursor_prefix} "
                    eval "values_$cur=\"\${_cursor_prefix}\${_cursor_suffix}\""
                fi ;;
            "$_bs"|"$_del")
                eval "v_cur=\"\$values_$cur\""
                _v_rest="$v_cur"
                state="${_v_rest%%|*}"; _v_rest="${_v_rest#*|}"
                s_idx="${_v_rest%%|*}"; _v_rest="${_v_rest#*|}"
                query="${_v_rest%%|*}"; _v_rest="${_v_rest#*|}"; opts="$_v_rest"
                eval "cf=\"\$fields_$cur\""
                if _match "$cf" ">*"; then
                    _cursor_prefix="${_cursor_prefix%?}"
                    eval "values_$cur=\"\${_cursor_prefix}\${_cursor_suffix}\""
                elif _match "$cf" "{ }*" && [ "$state" = "OPEN" ]; then
                    query="${query%?}"
                    eval "values_$cur='$state|0|$query|$opts'"
                else
                    eval "v=\"\$values_$cur\""; eval "values_$cur=\"\${v%?}\""
                fi ;;
            "")
                eval "cf_enter=\"\$fields_$cur\""
                if _match "$cf_enter" "{*"; then
                    eval "cv_enter=\"\$values_$cur\""
                    _r="$cv_enter"
                    _st="${_r%%|*}"; _r="${_r#*|}"
                    if [ "$_st" = "OPEN" ]; then
                        _si="${_r%%|*}"; _r="${_r#*|}"
                        _r="${_r#*|}"
                        _opts="$_r"
                        local _old_ifs="$IFS"; IFS=','; set -- $_opts; IFS="$_old_ifs"
                        _pi=""; _ix=0
                        for _o do
                            [ "$_ix" -eq "$_si" ] && _pi="$_o" && break
                            _ix=$((_ix+1))
                        done
                        _ix=0
                        for _o do
                            [ "$_o" = "$_pi" ] && { eval "values_$cur='CLOSED|$_ix||$_opts'"; break; }
                            _ix=$((_ix+1))
                        done
                        continue
                    fi
                fi
                local res=""
                local last_label=""

                i=0; while [ "$i" -lt "$count" ]; do
                    eval "meta=\"\$field_meta_$i\""
                    type="${meta%%|*}"
                    varname="${meta#*|}"
                    eval "val=\"\$values_$i\""
                    eval "field_raw=\"\$fields_$i\""
                    case "$type" in
                        "text")
                            local clean=$(_tolower "${field_raw%%:*}" | tr ' ' '_')
                            last_label="$clean"
                            ;;
                        "input")
                            res="${res}${varname}='${val}'"$'\n'
                            ;;
                        "check")
                            if [ "$val" = "1" ]; then
                                res="${res}${varname}='true'"$'\n'
                            else
                                res="${res}${varname}='false'"$'\n'
                            fi
                            ;;
                        "radio")
                            if [ "$val" = "1" ]; then
                                res="${res}${last_label}='${varname}'"$'\n'
                            fi
                            ;;
                        "dropdown")
                            _v_rest="$val"
                            _rest="${_v_rest#*|}"
                            _rest="${_rest#*|}"
                            _sel_opts="${_rest#*|}"
                            _sel_idx="${_v_rest%%|*}"
                            _rest="${_v_rest#*|}"; _sel_idx="${_rest%%|*}"
                            _rest="${_rest#*|}"; _rest="${_rest#*|}"
                            _sel_opts="$_rest"
                            local old_ifs="$IFS"; IFS=','
                            set -- $_sel_opts
                            _picked=""; idx=0
                            for o do
                                [ "$idx" -eq "$_sel_idx" ] && _picked="$o" && break
                                idx=$((idx+1))
                            done
                            IFS="$old_ifs"
                            local opt_val="${_picked##*:}"
                            res="${res}${last_label}='${opt_val}'"$'\n'
                            ;;
                    esac
                    i=$((i+1))
                done

                TUI_RESULT="${res%$'\n'}"
                echo "$TUI_RESULT" | tr '\n' ' ' && return 0 ;;

            "?")
            _help_popup form ;;
            "q") [ "$cur" -ge 0 ] && TUI_RESULT='' && return 1 ;;
            *)
                eval "cf=\"\$fields_$cur\""
                [ "$key" = "q" ] && ! _match "$cf" ">*" && TUI_RESULT='' && return 1
                if _match "$cf" "{ }*"; then
                    eval "v=\"\$values_$cur\""
                    _v_rest="$v"
                    state="${_v_rest%%|*}"; _v_rest="${_v_rest#*|}"
                    s_idx="${_v_rest%%|*}"; _v_rest="${_v_rest#*|}"
                    query="${_v_rest%%|*}"; _v_rest="${_v_rest#*|}"; opts="$_v_rest"
                    if [ "$state" = "OPEN" ]; then
                        query="${query}${key}"
                        eval "values_$cur='$state|0|$query|$opts'"
                    fi
                elif _match "$cf" ">*"; then
                    _cursor_prefix="${_cursor_prefix}${key}"
                    eval "values_$cur=\"\${_cursor_prefix}\${_cursor_suffix}\""
                fi ;;
        esac
    done
}

_save_undo() {
    # Limit stack size to 20 to prevent disk bloat
    tail -n 20 "$undo_stack" > "${undo_stack}.tmp"
    # Append current state as a single line (convert commas to | for stack)
    cat "$tmp_csv" >> "$undo_stack"
    : > "$redo_stack" # New action clears redo
}

spreadsheet() {
    # --- Spreadsheet Features ---
    # Navigation: Arrow keys for cell movement; scrollable row/column viewport
    # Modes: NAV (movement/commands) and EDIT (text entry via ENTER)
    # Math: Basic operators (+, -, *, /) and cell references (e.g., =A1+B1)
    # Stats: SUM, AVG, MIN, MAX, COUNT, COUNTA (e.g., =SUM(A1:B10))
    # Logic: IF statements with multi-char operators (e.g., =IF(A1>=50,OK,FAIL))
    # Strings: Concatenation using & operator (e.g., =A1&B1)
    # Formatting: ROUND function for decimal precision (e.g., =ROUND(A1,2))
    # Clipboard: Instant X (cut), C (copy), V (paste) in NAV mode
    # History: Multi-level Undo (z) and Redo (Z) support
    # Data: Persistence via CSV; handles row growth and empty cell alignment

    local MAX_COLS=26
    local title="$1"
    local src="$2"
    local tmp_csv=$(mktemp)
    
    local CONTROLS_TXT=" 
 ${SB}Arrows${SR}          Navigate cells (also ${SB}w${SR}/${SB}a${SR}/${SB}s${SR}/${SB}d${SR} and ${SB}h${SR}/${SB}j${SR}/${SB}k${SR}/${SB}l${SR})
 ${SB}PgUp${SR}/${SB}PgDn${SR}       Page scroll (also ${SB}J${SR}/${SB}K${SR})
 ${SB}Home${SR}/${SB}End${SR}        Jump to top/bottom (also ${SB}g${SR}/${SB}G${SR})
 ${SB}Enter${SR}           Enter edit mode for current cell
 ${SB}Right${SR}/${SB}Left${SR}      Move cursor in edit mode
 ${SB}q${SR}               Quit
 ${SB}?${SR}               Toggle this help
 
Supported Expressions in cells:
 
 =A1+B2          Basic math: +, -, *, /
 =SUM(A1:B10)    Range functions: SUM, AVG, MIN, MAX, COUNT, COUNTA
 =ROUND(A1,2)    Round to decimal places
 =IF(A1>=50,Y,N) Conditional logic (supports >=, <=, >, <, =)
 =A1&B1          String concatenation
 =A1             Cell reference (returns A1 value)"

    # 1. Setup Stacks and Clipboard
    local clipboard_val=""
    local undo_idx=0 redo_idx=0
    rm -f /tmp/tui_undo_* /tmp/tui_redo_*

    # 2. Setup Initial Data
    [[ -f "$src" ]] && cp "$src" "$tmp_csv" || echo "10,20,30" > "$tmp_csv"

    # 3. Define Undo Helper OUTSIDE the loop
    _push_undo() {
        undo_idx=$((undo_idx+1))
        cp "$tmp_csv" "/tmp/tui_undo_${undo_idx}.csv"
        # New actions invalidate redo history
        rm -f /tmp/tui_redo_*
        redo_idx=0
    }

    local cur_r=1 cur_c=1 top_r=1 top_c=1
    local mode="NAV" _cursor_prefix="" _cursor_suffix=""
    local cr="$_CR" lf="$_LF"

    # handle shifting viewport up a line if $title is empty
    local shift=0
    [[ -n "$title" ]] && shift=$((shift+1))

    # fix for fullscreen mode
    if [[ "$TUI_MODE" == "fullscreen" ]]; then
        [[ -n "$BACKTITLE" ]] && shift=$((shift+1))
    fi

    _init_tui
    while true; do
        # Viewport Math
        local v_h=$(( MAX_HEIGHT - 7 - shift ))
        local col_w=12 
        local v_w_area=$((MAX_WIDTH - 11)) 
        local v_c_count=$((v_w_area / (col_w + 1) + 1))

        # --- SCROLL LOGIC ---
        # Scroll up: if cursor is above viewport, move viewport top to cursor
        [[ $cur_r -lt $top_r ]] && top_r=$cur_r
        # Scroll down: if cursor is below viewport, slide viewport top to keep cursor at bottom
        [[ $cur_r -ge $((top_r + v_h)) ]] && top_r=$((cur_r - v_h + 1))
        # Scroll left: if cursor is left of viewport, move viewport left to cursor
        [[ $cur_c -lt $top_c ]] && top_c=$cur_c
        # Scroll right: if cursor is right of viewport, slide viewport left to keep cursor at edge
        [[ $cur_c -ge $((top_c + v_c_count)) ]] && top_c=$((cur_c - v_c_count + 1))

        # Nicer (padded) $mode name for header
        [[ "$mode" == "NAV" ]] && modetxt="NAV " || modetxt="EDIT"

        # 1. Header Fix: Use _draw_line or a clamped printf to stop the bleed
        _draw_header "$title" "Mode: $modetxt | ${SB}Arrows${SR} Move  ${SB}Enter${SR} Confirm  ${SB}?${SR} Help  ${SB}q${SR} Quit  "
        # Wipe the subtitle row perfectly to the right edge
        _draw_at "$((row - 1))" 0; printf "${BG_MAIN_ESC}%*s" "$MAX_WIDTH" "" >&2

        # 2. Spreadsheet Body (Using your fixed width)
        local visible_h=$((MAX_HEIGHT - 9))
        local col_w=12 
        local v_w_area=$((MAX_WIDTH - 11)) # Your fix
        local v_c_count=$((v_w_area / (col_w + 1)))


        # 2. Tight math for the Grid
        local grid_data
        grid_data=$(awk -v cur_r="$cur_r" -v cur_c="$cur_c" \
                        -v top_r="$top_r" -v top_c="$top_c" \
                        -v h="$v_h" -v v_c="$v_c_count" \
                        -v col_w="$col_w" -v w="$MAX_WIDTH" \
                        -v bg_m_raw="$BG_MAIN" -v bg_a_raw="$BG_ACTIVE" \
                        -v pt="$PADDING_TOP" -v pl="$PADDING_LEFT" \
                        -v shift="$shift" \
            'BEGIN { FS=","; 
                bm="\033[48;2;"bg_m_raw"m\033[22m"; ba="\033[48;2;"bg_a_raw"m\033[1m"; 
                bh="\033[48;2;80;80;80m\033[38;2;200;200;200m"; 
                abc="ABCDEFGHIJKLMNOPQRSTUVWXYZ";
            }
            { for(i=1; i<=NF; i++) d[NR,i]=$i; }
            function res(v,  tc, tr) {
                v = toupper(v);
                if(v ~ /^[A-Z][0-9]+$/) {
                    # Ensure A matches 1, B matches 2
                    tc = index(abc, substr(v,1,1));
                    tr = substr(v,2); 
                    return d[tr,tc] + 0;
                }
                return v + 0;
            }
            function ev(f,  p, op, s, sc, sr, ec, er, r, c, val, count, min, max, c_num, c_all, n1, n2) {
                f = toupper(f); sub(/^=/, "", f);
                
                # --- RANGE FUNCTIONS ---
                if (f ~ /^(SUM|AVG|MIN|MAX|COUNT|COUNTA)\(/) {
                    op = substr(f, 1, index(f, "(") - 1);
                    sub(/^[A-Z]+\(/, "", f); sub(/\)/, "", f);
                    split(f, p, ":");
                    sc = index(abc, substr(p[1],1,1)); sr = substr(p[1],2);
                    ec = index(abc, substr(p[2],1,1)); er = substr(p[2],2);
                    s = 0; c_num = 0; c_all = 0;
                    min = 999999999; max = -999999999;
                    for(r=sr; r<=er; r++) {
                        for(c=sc; c<=ec; c++) {
                            val = d[r,c]; if (val == "") continue;
                            c_all++;
                            if (val ~ /^-?[0-9.]+$/) {
                                num = val + 0; s += num; c_num++;
                                if (num < min) min = num; if (num > max) max = num;
                            }
                        }
                    }
                    if (op == "SUM") return s;
                    if (op == "AVG") return (c_num > 0) ? s / c_num : 0;
                    if (op == "MIN") return (c_num > 0) ? min : 0;
                    if (op == "MAX") return (c_num > 0) ? max : 0;
                    if (op == "COUNT") return c_num;
                    if (op == "COUNTA") return c_all;
                }
                
                # --- ROUND ---
                if (f ~ /^ROUND\(/) {
                    sub(/^ROUND\(/, "", f); sub(/\)/, "", f);
                    split(f, p, ",");
                    return sprintf("%." (p[2]+0) "f", res(p[1]));
                }
                
                # --- CONCAT ---
                if (f ~ /&/) {
                    split(f, p, "&");
                    return res(p[1]) res(p[2]);
                }

                # --- IF ---
                if (f ~ /^IF\(/) {
                    sub(/^IF\(/, "", f); sub(/\)/, "", f);
                    split(f, p, ",");
                    cond = p[1];
                    op = (cond ~ />=/) ? ">=" : ((cond ~ /<=/) ? "<=" : ((cond ~ />/) ? ">" : ((cond ~ /</) ? "<" : "=")));
                    split(cond, cp, op);
                    v1 = res(cp[1]); v2 = res(cp[2]);
                    rb = 0;
                    if(op==">=") rb=(v1>=v2); else if(op=="<=") rb=(v1<=v2);
                    else if(op==">") rb=(v1>v2); else if(op=="<") rb=(v1<v2); else rb=(v1==v2);
                    return rb ? p[2] : p[3];
                }

                # --- MATH ---
                op = (f~/\+/)?"+":((f~/-/)?"-":((f~/\*/)?"*":((f~/\//)?"/":"")));
                if (op != "") {
                    split(f, p, op); n1 = res(p[1]); n2 = res(p[2]);
                    if(op=="+") return n1+n2; if(op=="-") return n1-n2;
                    if(op=="*") return n1*n2; return (n2==0)?"DIV/0":n1/n2;
                }
                return f;
            }
            END {
                row_num_w = 4;
                # --- HEADER ---
                printf "\033[%d;%dH%s  %*s", (pt + 4 + shift), (pl+1), bm, row_num_w, "";
                used = 4 + row_num_w;
                for(c=top_c; c<(top_c + v_c); c++) {
                    printf "%s %-*.*s %s", bh, col_w, col_w, substr(abc,c,1), bm;
                    used += (col_w + 2);
                }
                # Fill remaining gap to right edge exactly
                if (w > used) printf "%*s", (w - used), "";

                # --- ROWS ---
                for(r=top_r; r<(top_r + h); r++) {
                    ry = r - top_r + pt + 5 + shift;
                    printf "\033[%d;%dH%s  %2d %s", ry, (pl+1), bh, r, bm;
                    used = 2 + row_num_w;
                    for(c=top_c; c<(top_c + v_c); c++) {
                        s=(r==cur_r && c==cur_c)?ba:bm; v=d[r,c];
                        if(v ~ /^=/) v=ev(v);
                        if(v == "") v=" ";
                        printf "%s %-*.*s %s", s, col_w, col_w, v, bm;
                        used += (col_w + 2);
                    }
                    # Fill remaining gap to right edge exactly
                    if (w > used) printf "%*s", (w - used), "";
                }
            }' "$tmp_csv")

        printf "%b" "$grid_data" >&2
        
        # 3. Status Bar - Fixed width with truncation and trailing fill
        _draw_at "$((MAX_HEIGHT - 1))" 0
        local bar_limit=$((MAX_WIDTH - 5)) # Buffer for indents
        
        if [[ "$mode" == "EDIT" ]]; then
            local label=" EDIT: "
            local val_limit=$(( bar_limit - ${#label} ))
            _render_cursor_display "$_cursor_prefix" "$_cursor_suffix"
            printf "${label}${BG_INPUT_ESC}${FG_INPUT_ESC}%-${val_limit}.${val_limit}s ${RESET}${BG_MAIN_ESC}  " "$_DISPLAY" >&2
        else
            local raw=$(awk -F, -v r="$cur_r" -v c="$cur_c" 'NR==r{print $c}' "$tmp_csv")
            local label=" [$(printf \\$(printf '%03o' $((cur_c+64))))${cur_r}] Raw: "
            local val_limit=$(( bar_limit - ${#label} ))
            printf "${FG_HINT_ESC}${label}%-${val_limit}.${val_limit}s ${RESET}${BG_MAIN_ESC}  " "$raw" >&2
        fi

        # 6. Input Handling
        local key
        _read_key key
        _handle_extra_keys "$key" && continue

        # --- ENTER KEY HANDLER ---
        if [ -z "$key" ] || [ "$key" = "$cr" ] || [ "$key" = "$lf" ]; then
            if [[ "$mode" == "NAV" ]]; then
                mode="EDIT"
                _cursor_prefix=$(awk -F, -v r="$cur_r" -v c="$cur_c" 'NR==r{print $c}' "$tmp_csv"); _cursor_suffix=""
            else
                _push_undo
                local row_count=$(wc -l < "$tmp_csv")
                while [[ $row_count -lt $cur_r ]]; do
                    local pad=""; i=1; while [ "$i" -lt "$MAX_COLS" ]; do pad="${pad},"; i=$((i+1)); done
                    echo "$pad" >> "$tmp_csv"; row_count=$((row_count+1))
                done

                # REBUILDER: The only way to prevent the "Shift to Column A" in BusyBox
                awk -F, -v r="$cur_r" -v c="$cur_c" -v nv="${_cursor_prefix}${_cursor_suffix}" -v mc="$MAX_COLS" '
                    BEGIN { OFS="," }
                    NR == r {
                        # 1. Force the line into a clean array using the comma separator
                        # This is more reliable in BusyBox than using $i
                        n = split($0, row, ",")
                        
                        # 2. Update the specific index
                        row[c] = nv
                        
                        # 3. Manually stringify the array back to mc (26) columns
                        out = ""
                        for (i = 1; i <= mc; i++) {
                            val = row[i]
                            # Ensure index exists in output string even if it was null in input
                            out = (i == 1) ? val : out OFS val
                        }
                        print out; next
                    }
                    { print $0 }' "$tmp_csv" > "${tmp_csv}.tmp" && mv "${tmp_csv}.tmp" "$tmp_csv"
                mode="NAV"
            fi
            continue
        fi

        # --- FIX: Handle NAV mode shortcuts (x, c, v) FIRST ---
        if [[ "$mode" == "NAV" ]]; then
            case "$key" in
                "c")
                    clipboard_val=$(awk -F, -v r="$cur_r" -v c="$cur_c" 'NR==r{print $c}' "$tmp_csv")
                    continue
                    ;;
                "x"|"v")
                    _push_undo
                    
                    local target_val=""
                    if [[ "$key" == "x" ]]; then
                        clipboard_val=$(awk -F, -v r="$cur_r" -v c="$cur_c" 'NR==r{print $c}' "$tmp_csv")
                        target_val=""
                    else
                        target_val="$clipboard_val"
                    fi

                    local row_count=$(wc -l < "$tmp_csv")
                    while [[ $row_count -lt $cur_r ]]; do
                        local pad_line=""; i=1; while [ "$i" -lt "$MAX_COLS" ]; do pad_line="${pad_line},"; i=$((i+1)); done
                        echo "$pad_line" >> "$tmp_csv"
                        row_count=$((row_count+1))
                    done
                    # Use nv="$target_val" instead of "$edit_val"
                    awk -F, -v r="$cur_r" -v c="$cur_c" -v nv="$target_val" -v mc="$MAX_COLS" '
                        BEGIN { OFS="," }
                        NR == r {
                            # 1. Force the line into a clean array using the comma separator
                            # This is more reliable in BusyBox than using $i
                            n = split($0, row, ",")
                            
                            # 2. Update the specific index
                            row[c] = nv
                            
                            # 3. Manually stringify the array back to mc (26) columns
                            out = ""
                            for (i = 1; i <= mc; i++) {
                                val = row[i]
                                # Ensure index exists in output string even if it was null in input
                                out = (i == 1) ? val : out OFS val
                            }
                            print out; next
                        }
                        { print $0 }' "$tmp_csv" > "${tmp_csv}.tmp" && mv "${tmp_csv}.tmp" "$tmp_csv"
                    continue
                    ;;
            esac
        fi

        case "$key" in
            "z") # UNDO
                if [[ $undo_idx -gt 0 ]]; then
                    redo_idx=$((redo_idx+1))
                    cp "$tmp_csv" "/tmp/tui_redo_${redo_idx}.csv"
                    cp "/tmp/tui_undo_${undo_idx}.csv" "$tmp_csv"
                    rm -f "/tmp/tui_undo_${undo_idx}.csv"
                    undo_idx=$((undo_idx-1))
                fi
                ;;
            "Z") # REDO
                if [[ $redo_idx -gt 0 ]]; then
                    undo_idx=$((undo_idx+1))
                    cp "$tmp_csv" "/tmp/tui_undo_${undo_idx}.csv"
                    cp "/tmp/tui_redo_${redo_idx}.csv" "$tmp_csv"
                    rm -f "/tmp/tui_redo_${redo_idx}.csv"
                    redo_idx=$((redo_idx-1))
                fi
                ;;

            "?") # Help
                modal "infobox 'Spreadsheet Help' \"$CONTROLS_TXT\""
                _init_tui
                ;;

            # --- VIM and WASD NAVIGATION (NAV Mode Only) ---
            "h"|"a") [[ "$mode" == "NAV" ]] && [[ $cur_c -gt 1 ]] && cur_c=$((cur_c-1)) || { [[ "$mode" == "EDIT" ]] && _cursor_prefix="${_cursor_prefix}${key}"; } ;;
            "j"|"s") [[ "$mode" == "NAV" ]] && cur_r=$((cur_r+1)) || { [[ "$mode" == "EDIT" ]] && _cursor_prefix="${_cursor_prefix}${key}"; } ;;
            "k"|"w") [[ "$mode" == "NAV" ]] && [[ $cur_r -gt 1 ]] && cur_r=$((cur_r-1)) || { [[ "$mode" == "EDIT" ]] && _cursor_prefix="${_cursor_prefix}${key}"; } ;;
            "l"|"d") [[ "$mode" == "NAV" ]] && [[ $cur_c -lt $MAX_COLS ]] && cur_c=$((cur_c+1)) || { [[ "$mode" == "EDIT" ]] && _cursor_prefix="${_cursor_prefix}${key}"; } ;;
            "J") [[ "$mode" == "NAV" ]] && cur_r=$((cur_r + v_h)) || { [[ "$mode" == "EDIT" ]] && _cursor_prefix="${_cursor_prefix}${key}"; } ;;
            "K") [[ "$mode" == "NAV" ]] && { cur_r=$((cur_r - v_h)); [ "$cur_r" -lt 1 ] && cur_r=1; } || { [[ "$mode" == "EDIT" ]] && _cursor_prefix="${_cursor_prefix}${key}"; } ;;
            "g") [[ "$mode" == "NAV" ]] && { cur_r=1; cur_c=1; } || { [[ "$mode" == "EDIT" ]] && _cursor_prefix="${_cursor_prefix}${key}"; } ;;
            "G") [[ "$mode" == "NAV" ]] && { cur_r=9999; cur_c=$MAX_COLS; } || { [[ "$mode" == "EDIT" ]] && _cursor_prefix="${_cursor_prefix}${key}"; } ;;

            $'\033')
                _read_str_timeout 2 key
                if [[ "$mode" == "NAV" ]]; then
                    case "$key" in
                        "[A"|"OA") [[ $cur_r -gt 1 ]] && cur_r=$((cur_r-1)) ;;
                        "[B"|"OB") cur_r=$((cur_r+1)) ;;
                        "[C"|"OC") [[ $cur_c -lt $MAX_COLS ]] && cur_c=$((cur_c+1)) ;;
                        "[D"|"OD") [[ $cur_c -gt 1 ]] && cur_c=$((cur_c-1)) ;;
                        "[5"|"[5~") cur_r=$((cur_r - v_h)); [ "$cur_r" -lt 1 ] && cur_r=1 ;;
                        "[6"|"[6~") cur_r=$((cur_r + v_h)) ;;
                        "[H") cur_r=1; cur_c=1 ;;
                        "[F") cur_r=9999 ; cur_c=$MAX_COLS ;;
                    esac
                elif [[ "$mode" == "EDIT" ]]; then
                    case "$key" in
                        "[C"|"OC") _cursor_right _cursor_prefix _cursor_suffix ;;
                        "[D"|"OD") _cursor_left _cursor_prefix _cursor_suffix ;;
                        "[3") _read_str_timeout 1 _del_c
                            [ "$_del_c" = "~" ] && [ -n "$_cursor_suffix" ] && _cursor_suffix="${_cursor_suffix#?}"
                            ;;
                    esac
                fi
                ;;

            "q"|"Q") 
                if [[ "$mode" == "NAV" ]]; then
                    break
                else
                    _cursor_prefix="${_cursor_prefix}${key}"
                fi
                ;;

            $'\177'|$'\010')
                [[ "$mode" == "EDIT" ]] && _cursor_prefix="${_cursor_prefix%?}"
                ;;

            *)
                # CRITICAL: Only append to edit_val if we are actually in EDIT mode
                # This prevents "v" or "x" from being added to the buffer in NAV mode
                [[ "$mode" == "EDIT" ]] && _cursor_prefix="${_cursor_prefix}${key}" 
                ;;
        esac
    done
    TUI_RESULT="$(cat "$tmp_csv")"
    cat "$tmp_csv"
    rm -f "$tmp_csv" /tmp/tui_undo_* /tmp/tui_redo_*
    return 0
}

filtermenu() {
    local title=$1 msg=$2 d=-1 input_string=""

    if _is_numeric "$3"; then
        d=$(( $3 - 1 ))
        input_string=$4
    else
        input_string=$3
    fi

    local _fm_tmp=$(mktemp /tmp/tui_fm.XXXXXX)
    echo "$input_string" | sed '/^[[:space:]]*$/d; s/^[[:space:]]*//; s/[[:space:]]*$//' > "$_fm_tmp"

    local _fm_n
    _fm_n=$(wc -l < "$_fm_tmp")
    [ $_fm_n -gt $MAX_FILTER_ITEMS ] && _fm_n=$MAX_FILTER_ITEMS

    local _fm_lc_tmp=$(mktemp /tmp/tui_fm_lc.XXXXXX)
    head -n $_fm_n "$_fm_tmp" | tr '[:upper:]' '[:lower:]' > "$_fm_lc_tmp"

    exec 3<"$_fm_tmp" 4<"$_fm_lc_tmp"
    _fm_i=0
    while [ $_fm_i -lt $_fm_n ]; do
        IFS= read -r _fm_opt <&3 && IFS= read -r _fm_lc <&4
        eval "_fm_o_$_fm_i=\$_fm_opt"
        eval "_fm_l_$_fm_i=\$_fm_lc"
        _fm_i=$((_fm_i+1))
    done
    exec 3<&- 4<&-
    rm -f "$_fm_tmp" "$_fm_lc_tmp"

    local cursor_prefix=""
    local cursor_suffix=""
    local filter_query=""
    local last_query="INIT_STATE"
    local cur=$d
    local _saved_cur=0
    local scroll_offset=0
    local start_row=$(_get_start_row)

    _init_tui
    local box_width=$CONTENT_WIDTH
    while true; do
        row=$start_row
        filter_query="${cursor_prefix}${cursor_suffix}"

        if [ "$filter_query" != "$last_query" ]; then
            local f_idx=0 _fm_i=0
            local lq=$(_tolower "$filter_query")
            while [ $_fm_i -lt $_fm_n ]; do
                eval "lo=\$_fm_l_$_fm_i"
                if [ -z "$filter_query" ] || _match "$lo" "*${lq}*"; then
                    eval "filtered_$f_idx=\$_fm_o_$_fm_i"
                    f_idx=$((f_idx+1))
                fi
                _fm_i=$((_fm_i+1))
            done
            count=$f_idx
            last_query="$filter_query"
        fi

        local _fh=$FOOTER_HEIGHT; [ "${TUI_HIDE_FOOTER:-false}" = "true" ] && _fh=0
        local max_vh=$(( MAX_HEIGHT - 7 - _fh ))
        [ "$TUI_MODE" = "fullscreen" ] && max_vh=$(( MAX_HEIGHT - 8 - _fh ))
        [ "$max_vh" -lt $MIN_CONTENT_HEIGHT ] && max_vh=$MIN_CONTENT_HEIGHT

        _draw_header "$title" "$msg"
        _draw_at "$row"

        local style="${BG_WID_ESC}${FG_TEXT_ESC}"
        [ "$cur" -eq -1 ] && style="${BG_INPUT_ESC}${FG_BLUE_BOLD}"

        local _display="$filter_query"
        local _vis_len=${#filter_query}
        if [ "$cur" -eq -1 ]; then
            _render_cursor_display "$cursor_prefix" "$cursor_suffix"
            _display="$_DISPLAY"
            _vis_len=$_VIS_LEN
        fi
        local _pad=$(( FILTER_WIDTH - _vis_len ))
        [ "$_pad" -lt 0 ] && _pad=0
        printf "  Filter: ${style} > %s%${_pad}s ${RESET}${BG_MAIN_ESC}%$((MAX_WIDTH - 39))s" "$_display" "" "" >&2
        _draw_line "" "$row"
        _draw_line ""

        local active_vh=$count
        [ "$active_vh" -gt "$max_vh" ] && active_vh=$max_vh
        [ "$active_vh" -lt 1 ] && active_vh=1

        [ "$cur" -ge "$count" ] && cur=$((count - 1))
        [ "$cur" -lt -1 ] && cur=-1

        if [ "$cur" -ge 0 ] && [ "$cur" -lt "$scroll_offset" ]; then
            scroll_offset=$cur
        elif [ "$cur" -ge 0 ] && [ "$cur" -ge "$((scroll_offset + active_vh))" ]; then
            scroll_offset=$((cur - active_vh + 1))
        fi

        local list_top=$row
        i=0; while [ "$i" -lt "$max_vh" ]; do
            local idx=$((scroll_offset + i))
            local current_row=$((list_top + i))
            _draw_at "$current_row"
            printf "$INDENT" >&2
            local is_cur=0; [ "$cur" -eq "$idx" ] && is_cur=1

            if [ "$idx" -lt "$count" ]; then
                eval "fv=\"\$filtered_$idx\""
                _draw_item "menu" "$is_cur" 0 "$fv" "$box_width"
            else
                printf "${BG_MAIN_ESC}%-${box_width}s${RESET}${BG_MAIN_ESC}" "" >&2
            fi
            printf "%$((MAX_WIDTH - box_width - 4))s" "" >&2
            row=$((row+1))
            i=$((i+1))
        done

        row=$((list_top + max_vh))
        if [ "$_fh" -ne 0 ]; then
            _draw_at "$row"
            _draw_spacer
            _draw_controls " ${SB}Up${SR}/${SB}Down${SR} Navigate | ${SB}Enter${SR} Select | ${SB}Tab${SR} Focus | ${SB}/${SR} Filter | ${SB}?${SR} Help"
            _draw_spacer
            row=$((row + 1))
        fi
        _draw_footer

        _read_key_esc
        _handle_extra_keys "$KEY" && continue

        if [ -n "$ESC_SEQ" ]; then
            case "$ESC_SEQ" in
                "[A"|"OA") [ "$cur" -ge 0 ] && cur=$((cur-1)) ;;
                "[B"|"OB")
                    if [ "$cur" -eq -1 ] && [ "$count" -gt 0 ]; then
                        cur=0
                    elif [ "$cur" -ge 0 ] && [ "$cur" -lt "$((count-1))" ]; then
                        cur=$((cur+1))
                    fi ;;
                "[C"|"OC") [ "$cur" -eq -1 ] && _cursor_right cursor_prefix cursor_suffix ;;
                "[D"|"OD") [ "$cur" -eq -1 ] && _cursor_left cursor_prefix cursor_suffix ;;
                "[3")
                    _read_str_timeout 1 _del_c
                    [ "$cur" -eq -1 ] && [ "$_del_c" = "~" ] && [ -n "$cursor_suffix" ] && cursor_suffix="${cursor_suffix#?}"
                    ;;
                "[5"|"[5~"|"5~") [ "$cur" -ge 0 ] && cur=$((cur - active_vh)); [ "$cur" -lt 0 ] && cur=0 ;;
                "[6"|"[6~"|"6~") [ "$cur" -ge 0 ] && cur=$((cur + active_vh)); [ "$cur" -ge "$count" ] && cur=$((count - 1)) ;;
                "[H") [ "$cur" -ge 0 ] && cur=0 ;;
                "[F") [ "$cur" -ge 0 ] && cur=$((count - 1)) ;;
            esac
            continue
        fi

        case "$KEY" in
            "")
                if [ "$cur" -eq -1 ]; then
                    [ "$count" -gt 0 ] && cur=0
                else
                    eval "TUI_RESULT=\"\$filtered_$cur\""
                    eval "echo \"\$filtered_$cur\""
                    return 0
                fi ;;
            "/") [ "$cur" -ge 0 ] && cur=-1 ;;
"$_DEL"|"$_BS")
                if [ "$cur" -eq -1 ]; then
                    if [ -n "$cursor_prefix" ]; then
                        cursor_prefix="${cursor_prefix%?}"
                    else
                        cur=${_saved_cur:-0}

                    fi
                elif [ "$cur" -ge 0 ]; then
                    cur=-1
                fi ;;
            "$_TAB")
                if [ "$cur" -eq -1 ]; then
                    cur=${_saved_cur:-0}
                    [ "$cur" -ge "$count" ] && cur=$((count - 1))
                else
                    _saved_cur=$cur
                    cur=-1
                fi ;;
            "?")
            _help_popup filtermenu ;;
            "q") if [ "$cur" -eq -1 ]; then cursor_prefix="${cursor_prefix}${KEY}"; else TUI_RESULT=''; return 1; fi ;;
            "j"|"k"|"s"|"w")
                if [ "$cur" -ge 0 ]; then
                    [ "$KEY" = "j" ] || [ "$KEY" = "s" ] && [ "$cur" -lt "$((count - 1))" ] && cur=$((cur+1))
                    [ "$KEY" = "k" ] || [ "$KEY" = "w" ] && [ "$cur" -gt 0 ] && cur=$((cur-1))
                elif [ "$cur" -eq -1 ]; then
                    cursor_prefix="${cursor_prefix}${KEY}"
                fi ;;
            "J")
                if [ "$cur" -ge 0 ]; then
                    cur=$((cur + active_vh))
                    [ "$cur" -ge "$count" ] && cur=$((count - 1))
                elif [ "$cur" -eq -1 ]; then
                    cursor_prefix="${cursor_prefix}${KEY}"
                fi ;;
            "K")
                if [ "$cur" -ge 0 ]; then
                    cur=$((cur - active_vh))
                    [ "$cur" -lt 0 ] && cur=0
                elif [ "$cur" -eq -1 ]; then
                    cursor_prefix="${cursor_prefix}${KEY}"
                fi ;;
            "g") [ "$cur" -ge 0 ] && cur=0 || { [ "$cur" -eq -1 ] && cursor_prefix="${cursor_prefix}${KEY}"; } ;;
            "G") [ "$cur" -ge 0 ] && cur=$((count - 1)) || { [ "$cur" -eq -1 ] && cursor_prefix="${cursor_prefix}${KEY}"; } ;;
            *)
                if [ "$cur" -eq -1 ]; then
                    case "$KEY" in [[:print:]])
                        cursor_prefix="${cursor_prefix}${KEY}"
                        scroll_offset=0 ;;
                    esac
                fi ;;
        esac
    done
}

filepicker() {
    local title=$1 msg=$2 root_dir=${3:-.}
    local cur=${4:-0}
    
    local top=0 menu_w=30 
    local preview_x=$(( menu_w + 8 )) 
    local preview_offset=0
    local last_cur=-1 last_dir="INIT"
    local rebuild=1
    
    local dir_col="\e[1;34m"
    local exe_col="\e[1;32m"
    local hid_col="\e[2m"
    local show_hidden=0
    local sel_path_count=0

    root_dir=$(cd "$root_dir" && pwd)

    while true; do
        if [ "$root_dir" != "$last_dir" ] || [ $rebuild -eq 1 ]; then
            raw_count=0

            eval "raw_0='${root_dir%/*}|..|true'"
            raw_count=1

            local _fp_tmpf=$(mktemp /tmp/tui_fp.XXXXXX)
            find "$root_dir" -maxdepth 1 -mindepth 1 | sort > "$_fp_tmpf"

            # dirs first (visible, then hidden if show_hidden=1)
            while IFS= read -r _entry; do
                [ ! -d "$_entry" ] && continue
                local _name="${_entry##*/}"
                case "$_name" in .*) [ $show_hidden -eq 0 ] && continue ;; esac
                eval "raw_$raw_count='$_entry|$_name|true'"
                raw_count=$((raw_count+1))
            done < "$_fp_tmpf"

            # then files
            while IFS= read -r _entry; do
                [ ! -f "$_entry" ] && continue
                local _name="${_entry##*/}"
                case "$_name" in .*) [ $show_hidden -eq 0 ] && continue ;; esac
                eval "raw_$raw_count='$_entry|$_name|false'"
                raw_count=$((raw_count+1))
            done < "$_fp_tmpf"

            rm -f "$_fp_tmpf"

            count=$raw_count

            if [ "$cur" -eq -2 ]; then
                cur=0
                idx=0; while [ "$idx" -lt "$count" ]; do
                    eval "node=\$raw_$idx"
                    if [ "${node%%|*}" = "$last_path" ]; then
                        cur=$idx; break
                    fi
                    idx=$((idx+1))
                done
            fi

            [ $cur -ge $count ] && cur=$((count - 1))
            [ $cur -lt 0 ] && cur=0

            last_dir="$root_dir"; rebuild=0; _init_tui 
        fi

        local display_path="$root_dir"
        local max_path_w=$(( MAX_WIDTH - 10 ))
        if [ ${#display_path} -gt $max_path_w ]; then
            display_path="...${display_path:$(( ${#display_path} - max_path_w + 3 ))}"
        fi
        case "$display_path" in "$HOME"*) display_path="~${display_path#$HOME}" ;; esac

        _draw_header "$title" "Path: $display_path"

        local list_top=$row
        local _fh=$FOOTER_HEIGHT; [ "${TUI_HIDE_FOOTER:-false}" = "true" ] && _fh=0
        local height=$(( MAX_HEIGHT - list_top - _fh ))
        [ $height -lt 5 ] && height=5

        if [ $cur -lt $top ]; then
            top=$cur
        elif [ $cur -ge $((top + height)) ]; then
            top=$((cur - height + 1))
        fi

        i=0; while [ "$i" -lt "$height" ]; do
            local v_idx=$((top + i))
            local current_row=$((list_top + i))
            _draw_at "$current_row"
            printf "$INDENT" >&2
            
            if [ $v_idx -lt $count ]; then
                eval "node=\$raw_$v_idx"
                local path="${node%%|*}"
                local remain="${node#*|}"
                local label="${remain%|*}"
                local is_dir="${remain##*|}"

                local is_cur=0; [ $v_idx -eq $cur ] && is_cur=1
                
                local display_name="$label"
                [ "$is_dir" = "true" ] && [ "$label" != ".." ] && display_name="${label}/"

                local max_l=$(( menu_w - 2 ))
                if [ ${#display_name} -gt $max_l ]; then
                    display_name="${display_name:0:$((max_l - 2))}.."
                fi

                local color=""
                if [ $is_cur -eq 1 ]; then
                    color="\e[1;37m"
                else
                    local is_tagged=0
                    si=0; while [ "$si" -lt "$sel_path_count" ]; do
                        eval "s_path=\$selpath_$si"
                        [ "$s_path" = "$path" ] && { is_tagged=1; break; }
                        si=$((si+1))
                    done
                    if [ $is_tagged -eq 1 ]; then
                        color="\e[1;33m"
                    elif [ "$is_dir" = "true" ]; then
                        color="$dir_col"
                    elif [ "${label#.}" != "$label" ]; then
                        color="$hid_col"
                    elif [ -x "$path" ]; then
                        color="$exe_col"
                    else
                        color="$FG_TEXT_ESC"
                    fi
                fi

                local style=$BG_WID_ESC
                [ $is_cur -eq 1 ] && style=$HL_WHITE_BOLD
                
                printf "${style}${color} %-${menu_w}s ${RESET}${BG_MAIN_ESC}" "$display_name" >&2
            else
                printf "%$((menu_w + 2))s" "" >&2
            fi
            _draw_line "" "$current_row"
            i=$((i+1))
        done

        if [ "$cur" -ne "$last_cur" ]; then
            eval "node=\$raw_$cur"
            local p="${node%%|*}"
            local is_d="${node##*|}"
            if [ "$is_d" = "false" ]; then
                preview "$p" "$list_top" "$height" "$preview_x" "$preview_offset"
            else
                local preview_file="/tmp/tui_pv_fp_$$.txt"
                { ls -1Ap "$p" 2>/dev/null | grep '/$'; ls -1Ap "$p" 2>/dev/null | grep -v '/$'; } 2>/dev/null | head -"$height" > "$preview_file"
                [ -s "$preview_file" ] && preview "$preview_file" "$list_top" "$height" "$preview_x" 0 || preview "" "$list_top" "$height" "$preview_x" "$preview_offset"
            fi
            last_cur=$cur
        fi

        row=$((list_top + height))
        if [ "$_fh" -ne 0 ]; then
            _draw_spacer
            _draw_controls " ${SB}Arrows${SR} Navigate | ${SB}Enter${SR} Select | ${SB}Tab${SR} Mark | ${SB}.${SR} Hidden | ${SB}?${SR} Help"
        fi
        _draw_footer

        _handle_selection() {
            eval "node=\$raw_$cur"
            local p="${node%%|*}"
            local is_d="${node##*|}"

            if [ "$is_d" = "true" ]; then
                root_dir=$(cd "$p" && pwd); cur=0; top=0; last_cur=-1
                [ -n "$TUI_CD_FILE" ] && echo "cd \"$root_dir\"" > "$TUI_CD_FILE"
                _init_tui
                return 0
            fi

            local results=""
            si=0; while [ "$si" -lt "$sel_path_count" ]; do
                eval "sp_val=\$selpath_$si"
                results="$results$sp_val
"
                si=$((si+1))
            done

            if [ -n "$results" ]; then
                TUI_RESULT="$results"
                printf "%b" "$results"
                return 2
            fi

            TUI_RESULT="$p"
            echo "$p"
            return 2
        }

        local key
        _read_key key
        _handle_extra_keys "$key" && continue
        
        case "$key" in
            $'\t')
                eval "node=\$raw_$cur"
                local path="${node%%|*}"
                local label="${node#*|}"
                label="${label%|*}"
                if [ "$label" != ".." ]; then
                    local found=-1
                    si=0; while [ "$si" -lt "$sel_path_count" ]; do
                        eval "sp_val=\$selpath_$si"
                        [ "$sp_val" = "$path" ] && found=$si && break
                        si=$((si+1))
                    done
                    if [ $found -ge 0 ]; then
                        tmp_count=0
                        si=0; while [ "$si" -lt "$sel_path_count" ]; do
                            if [ "$si" -ne "$found" ]; then
                                eval "selpath_$tmp_count=\$selpath_$si"
                                tmp_count=$((tmp_count+1))
                            fi
                            si=$((si+1))
                        done
                        sel_path_count=$tmp_count
                    else
                        eval "selpath_$sel_path_count='$path'"
                        sel_path_count=$((sel_path_count+1))
                    fi
                fi
                [ $cur -lt $((count - 1)) ] && cur=$((cur+1)) ;;
            '.')
                eval "last_path=\$raw_$cur"
                last_path="${last_path%%|*}"
                show_hidden=$(( 1 - show_hidden )); rebuild=1; cur=-2 ;;
            "?")
                _help_popup filepicker ;;
            "J") cur=$((cur + height)); [ "$cur" -ge "$count" ] && cur=$((count - 1)) ;;
            "K") cur=$((cur - height)); [ "$cur" -lt 0 ] && cur=0 ;;
            "g") cur=0 ;;
            "G") cur=$((count - 1)) ;;
            "q") TUI_RESULT=''; return 1 ;;

            "k"|"w") [ $cur -gt 0 ] && cur=$((cur-1)) ;;
            "j"|"s") [ $cur -lt $((count - 1)) ] && cur=$((cur+1)) ;;
            "[") preview_offset=$((preview_offset - height)); [ $preview_offset -lt 0 ] && preview_offset=0; last_cur=-3 ;;
            "]") preview_offset=$((preview_offset + height)); last_cur=-3 ;;
            "h"|"a")
                local old_name="${root_dir##*/}"
                local parent_dir="${root_dir%/*}"
                if [ -n "$parent_dir" ] && [ "$root_dir" != "/" ]; then
                    root_dir="$parent_dir"
                    last_path="$root_dir/$old_name"
                    rebuild=1; cur=-2
                    [ -n "$TUI_CD_FILE" ] && echo "cd \"$root_dir\"" > "$TUI_CD_FILE"
                    _init_tui
                fi ;;
            "l"|"d"|"")
                _handle_selection; [ $? -eq 2 ] && return 0 ;;

            $'\033')
                _read_str_timeout 2 key
                case "$key" in
                    "[A"|"OA") [ $cur -gt 0 ] && cur=$((cur-1)) ;;
                    "[B"|"OB") [ $cur -lt $((count - 1)) ] && cur=$((cur+1)) ;;
                    "[C"|"OC")
                        _handle_selection; [ $? -eq 2 ] && return 0 ;;
                    "[D"|"OD")
                        local old_name="${root_dir##*/}"
                        local parent_dir="${root_dir%/*}"
                        if [ -n "$parent_dir" ] && [ "$root_dir" != "/" ]; then
                            root_dir="$parent_dir"
                            last_path="$root_dir/$old_name"
                            rebuild=1; cur=-2
                            [ -n "$TUI_CD_FILE" ] && echo "cd \"$root_dir\"" > "$TUI_CD_FILE"
                            _init_tui
                        fi ;;
                    "[5"|"[5~") cur=$((cur - height)); [ "$cur" -lt 0 ] && cur=0 ;;
                    "[6"|"[6~") cur=$((cur + height)); [ "$cur" -ge "$count" ] && cur=$((count - 1)) ;;
                    "[H") cur=0 ;;
                    "[F") cur=$((count - 1)) ;;
                esac ;;
        esac
    done
}

_tree_core() {
    local mode=$1 title=$2 msg=$3 def_idx=${4:-0}; shift 4
    local count=$#
    local cur=$def_idx top=0
    i=0; while [ "$i" -lt "$count" ]; do idx=$((i+1)); eval "node_$i=\"\${$idx}\""; i=$((i+1)); done

    # 1. New Filter State
    : ${ENABLE_FILTER:=false}
    local filter_query=""
    local cursor_prefix=""
    local cursor_suffix=""
    local last_query="INIT"

    local visible_count=0 formatted_count=0 expanded_count=0

    # Pre-populate the expanded array with every parent ID
    i=0; while [ "$i" -lt "$count" ]; do
        eval "node=\"\$node_$i\""
        if _match "${node##*|}" "true"; then
            local rem="${node#*|}"
            eval "expanded_$expanded_count='${rem%%|*}'; expanded_count=$((expanded_count+1))"
        fi
        i=$((i+1))
    done

    # Pre-compute lowercase labels and IDs for faster filter matching
    i=0; while [ "$i" -lt "$count" ]; do
        eval "node=\"\$node_$i\""
        local remaining="${node#*|}"
        local nid="${remaining%%|*}"; remaining="${remaining#*|}"
        local nlbl="${remaining%%|*}"
        local _nlcl=$(_tolower "$nlbl")
        local _nicl=$(_tolower "$nid")
        eval "nlc_$i='$_nlcl'"
        eval "nic_$i='$_nicl'"
        i=$((i+1))
    done

    _update_tree_cache() {
        visible_count=0; formatted_count=0
        local last_hidden_depth=-1
        local exp_str="|"
        local ei=0; while [ "$ei" -lt "$expanded_count" ]; do eval "ev=\"\$expanded_$ei\""; exp_str="${exp_str}${ev}|"; ei=$((ei+1)); done
        local is_filtering=0; [ -n "$filter_query" ] && is_filtering=1

        if [ $is_filtering -eq 1 ]; then
            # --- PHASE 1: DIRECT MATCH CHECK ---
            _fq_lc=$(_tolower "$filter_query")
            local di=0; while [ "$di" -lt "$count" ]; do
                [ $di -ge $MAX_FILTER_ITEMS ] && break
                eval "nm_$di=0"
                eval "nl=\"\$nlc_$di\""; eval "ni=\"\$nic_$di\""
                if _match "$nl" "*$_fq_lc*" || _match "$ni" "*$_fq_lc*"; then
                    eval "nm_$di=1"
                fi
                di=$((di+1))
            done

            # --- PHASE 2: BACKWARD PROPAGATION (mark ancestors of matching nodes) ---
            local pi=$((count-1)); while [ "$pi" -ge 0 ]; do
                eval "pm=\"\$nm_$pi\""
                if [ "$pm" = "1" ]; then
                    eval "pnode=\"\$node_$pi\""
                    local pd="${pnode%%|*}"
                    local scan_p=$pi
                    while [ $scan_p -gt 0 ]; do
                        scan_p=$((scan_p-1))
                        eval "ppnode=\"\$node_$scan_p\""
                        if [ "${ppnode%%|*}" -lt "$pd" ]; then
                            eval "npm=\"\$nm_$scan_p\""
                            [ "$npm" = "1" ] && break
                            eval "nm_$scan_p=1"
                            pd="${ppnode%%|*}"
                        fi
                    done
                fi
                pi=$((pi-1))
            done

            # --- PHASE 3: FORWARD PASS (build visible list from nm_$i flags) ---
            i=0; while [ "$i" -lt "$count" ]; do
                [ $i -ge $MAX_FILTER_ITEMS ] && break
                eval "node=\"\$node_$i\""
                local depth="${node%%|*}"
                local remaining="${node#*|}"
                local id="${remaining%%|*}"; remaining="${remaining#*|}"
                local label="${remaining%%|*}"; local has_kids="${remaining##*|}"

                eval "match_flag=\"\$nm_$i\""
                [ "$match_flag" != "1" ] && { i=$((i+1)); continue; }

                eval "visible_$visible_count=$i"; visible_count=$((visible_count+1))
                local indent=""; d=0; while [ "$d" -lt "$depth" ]; do indent="  $indent"; d=$((d+1)); done
                local icon="  "
                [ "$has_kids" = "true" ] && icon="▼ "

                local is_disabled="false"
                local scan_ptr=$i check_d=$depth
                while [ $scan_ptr -gt 0 ]; do
                    scan_ptr=$((scan_ptr-1))
                    eval "p_node=\"\$node_$scan_ptr\""
                    local p_depth="${p_node%%|*}"
                    if [ $p_depth -lt $check_d ]; then
                        local p_label="${p_node#*|*|}"; p_label="${p_label%%|*}"
                        if _match "$p_label" "*\[ \]*" || _match "$p_label" "*( )*"; then
                            is_disabled="true"; break
                        fi
                        check_d=$p_depth
                    fi
                done

                eval "formatted_$formatted_count='${indent}${icon}${label}|${is_disabled:-false}'"; formatted_count=$((formatted_count+1))
                i=$((i+1))
            done
        else
            # Non-filtering mode: original expansion-based logic
            i=0; while [ "$i" -lt "$count" ]; do
                eval "node=\"\$node_$i\""
                local depth="${node%%|*}"
                local remaining="${node#*|}"
                local id="${remaining%%|*}"; remaining="${remaining#*|}"
                local label="${remaining%%|*}"; local has_kids="${remaining##*|}"

                if [ $last_hidden_depth -ne -1 ] && [ $depth -gt $last_hidden_depth ]; then
                    i=$((i+1)); continue
                fi
                last_hidden_depth=-1
                if [ "$has_kids" = "true" ] && ! _match "$exp_str" "*|$id|*"; then
                    last_hidden_depth=$depth
                fi

                eval "visible_$visible_count=$i"; visible_count=$((visible_count+1))
                local indent=""; d=0; while [ "$d" -lt "$depth" ]; do indent="  $indent"; d=$((d+1)); done
                local icon="  "
                if [ "$has_kids" = "true" ]; then
                    if _match "$exp_str" "*|$id|*"; then
                        icon="▼ "
                    else
                        icon="▶ "
                    fi
                fi

                local is_disabled="false"
                local scan_ptr=$i check_d=$depth
                while [ $scan_ptr -gt 0 ]; do
                    scan_ptr=$((scan_ptr-1))
                    eval "p_node=\"\$node_$scan_ptr\""
                    local p_depth="${p_node%%|*}"
                    if [ $p_depth -lt $check_d ]; then
                        local p_label="${p_node#*|*|}"; p_label="${p_label%%|*}"
                        if _match "$p_label" "*\[ \]*" || _match "$p_label" "*( )*"; then
                            is_disabled="true"; break
                        fi
                        check_d=$p_depth
                    fi
                done

                eval "formatted_$formatted_count='${indent}${icon}${label}|${is_disabled:-false}'"; formatted_count=$((formatted_count+1))
                i=$((i+1))
            done
        fi
    }

    _tree_expand() {
        local _id="$1" _i=0
        while [ "$_i" -lt "$expanded_count" ]; do
            eval "[ \"\$expanded_$_i\" = \"$_id\" ]" && return
            _i=$((_i+1))
        done
        eval "expanded_$expanded_count='$_id'"
        expanded_count=$((expanded_count+1))
    }

    _tree_remove_expanded() {
        local _rid="$1" _ne=0 _i=0 _v
        while [ "$_i" -lt "$expanded_count" ]; do
            eval "_v=\"\$expanded_$_i\""
            [ "$_v" != "$_rid" ] && { eval "expanded_$_ne='$_v'"; _ne=$((_ne+1)); }
            _i=$((_i+1))
        done
        expanded_count=$_ne
    }

    _update_tree_cache

    local box_width=$CONTENT_WIDTH

    _init_tui
    local _skip_header=0 _post_header_row=0
    while true; do
        if [ $_skip_header -eq 0 ]; then
            _draw_header "$title" "$msg"
            _post_header_row=$row
        else
            row=$_post_header_row
        fi
        _skip_header=0

        if [ "$ENABLE_FILTER" = "true" ]; then
            _draw_at "$row"
            local f_style="${BG_WID_ESC}${FG_TEXT_ESC}"
            [ $cur -eq -1 ] && f_style="${BG_INPUT_ESC}${FG_BLUE_BOLD}"
            local _display="$filter_query"
            local _vis_len=${#filter_query}
            if [ $cur -eq -1 ]; then
                _render_cursor_display "$cursor_prefix" "$cursor_suffix"
                _display="$_DISPLAY"
                _vis_len=$_VIS_LEN
            fi
            local _pad=$(( FILTER_WIDTH - _vis_len ))
            [ "$_pad" -lt 0 ] && _pad=0
            printf "  Filter: ${f_style} > %s%${_pad}s ${RESET}${BG_MAIN_ESC}" "$_display" "" >&2
            row=$((row+2))
        fi

        local view_top=$row
        local _fh=$FOOTER_HEIGHT; [ "${TUI_HIDE_FOOTER:-false}" = "true" ] && _fh=0
        # THE FIX: Anchor height to the bottom of the widget box
        local view_height=$(( MAX_HEIGHT - view_top - _fh ))
        [ $view_height -lt 5 ] && view_height=5
        local v_count=$visible_count

        # --- Viewport Clamping ---
        if [ $cur -ge 0 ]; then
            [ $cur -ge $v_count ] && cur=$((v_count - 1))
            [ $cur -lt 0 ] && cur=0
            [ $cur -lt $top ] && top=$cur
            [ $cur -ge $((top + view_height)) ] && top=$((cur - view_height + 1))
        fi

        i=0; while [ "$i" -lt "$view_height" ]; do
            local v_idx=$((top + i))
            local current_view_row=$((view_top + i))
            _draw_at "$current_view_row" 0
            printf "$INDENT" >&2
            
            if [ $v_idx -lt $v_count ]; then
                local is_cur=0; [ $v_idx -eq $cur ] && is_cur=1
                
                eval "line_data=\"\$formatted_$v_idx\""
                local content_line="${line_data%|*}"
                local item_disabled="${line_data##*|}"
                
                local item_w=$CONTENT_WIDTH
                
                if _match "$content_line" "*▶*" || _match "$content_line" "*▼*"; then
                    item_w=$((item_w + 2))
                fi

                if [ "$item_disabled" = "true" ] && [ $is_cur -eq 0 ]; then
                    local OLD_TEXT=$FG_TEXT_ESC
                    FG_TEXT_ESC=$FG_HINT_ESC
                    _draw_item "menu" "$is_cur" 0 "$content_line" "$item_w"
                    FG_TEXT_ESC=$OLD_TEXT
                else
                    _draw_item "menu" "$is_cur" 0 "$content_line" "$item_w"
                fi
            else
                printf "%*s" "$(($MAX_WIDTH - 2))" "" >&2
            fi
            
            row=$((current_view_row + 1))
            i=$((i+1))
        done

        # --- FOOTER ANCHOR ---
        if [ "$_fh" -ne 0 ]; then
            row=$(( MAX_HEIGHT - 2 ))
            local hint=" ${SB}Arrows${SR} Navigate | ${SB}Enter${SR} Select | ${SB}?${SR} Help"
            [ "$mode" = "config" ] && hint=" ${SB}Arrows${SR} Navigate | ${SB}Space${SR} Toggle | ${SB}Enter${SR} Select | ${SB}?${SR} Help"

            row=$((row+1))
            if [ $_skip_header -eq 0 ]; then
                _draw_controls "$hint"
            fi
        fi
        _draw_footer

        # --- STEP 1: ATOMIC CAPTURE ---
        local key="" ESC_SEQ=""
        _read_key key
        _handle_extra_keys "$key" && continue
        [ "$key" = "$_ESC" ] && { _read_str_timeout 2 ESC_SEQ; }

        # --- STEP 2: FILTER INPUT (Focus at -1) ---
        if [ "$ENABLE_FILTER" = "true" ] && [ $cur -eq -1 ]; then
            if [ -z "$ESC_SEQ" ]; then
                case "$key" in
                    $_DEL|$_BS)
                    if [ -n "$cursor_prefix" ]; then
                        cursor_prefix="${cursor_prefix%?}"
                        filter_query="${cursor_prefix}${cursor_suffix}"
                        _update_tree_cache
                        _skip_header=1
                    else
                        [ $v_count -gt 0 ] && cur=0
                    fi
                    continue ;;
                $_TAB)
                    [ -z "$filter_query" ] && [ $v_count -gt 0 ] && cur=0
                    continue ;;
                    "") # ENTER: JUMP TO MATCH
                        if [ $visible_count -gt 0 ]; then
                            cur=0
_fq_lc=$(_tolower "$filter_query")
                            idx=0; while [ "$idx" -lt "$visible_count" ]; do
                                eval "g_idx=\"\$visible_$idx\""
                                eval "glc=\"\$nlc_$g_idx\""; eval "gic=\"\$nic_$g_idx\""
                                if _match "$glc" "*$_fq_lc*" || _match "$gic" "*$_fq_lc*"; then
                                    cur=$idx
                                    break
                                fi
                                idx=$((idx+1))
                            done
                        fi
                        continue
                        ;;
                    *)
                        if [ -n "$key" ]; then
                            cursor_prefix="${cursor_prefix}${key}"
                            filter_query="${cursor_prefix}${cursor_suffix}"
                            _update_tree_cache
                            cur=-1
                            _skip_header=1
                            continue 
                        fi
                        ;;
                esac
            else
                case "$ESC_SEQ" in
                    "[B"|"OB") [ $v_count -gt 0 ] && cur=0 ;;
                    "[C"|"OC") _cursor_right cursor_prefix cursor_suffix; filter_query="${cursor_prefix}${cursor_suffix}" ;;
                    "[D"|"OD") _cursor_left cursor_prefix cursor_suffix; filter_query="${cursor_prefix}${cursor_suffix}" ;;
                    "[3")
                        _read_str_timeout 1 _del_c
                        [ "$_del_c" = "~" ] && [ -n "$cursor_suffix" ] && { cursor_suffix="${cursor_suffix#?}"; filter_query="${cursor_prefix}${cursor_suffix}"; _update_tree_cache; _skip_header=1; }
                        ;;
                    "[5"|"[5~") [ $v_count -gt 0 ] && cur=0 ;;
                    "[6"|"[6~") [ $v_count -gt 0 ] && cur=$((v_count - 1)) ;;
                    "[H") [ $v_count -gt 0 ] && cur=0 ;;
                    "[F") [ $v_count -gt 0 ] && cur=$((v_count - 1)) ;;
                esac
                continue
            fi
        fi

        # --- STEP 3: LIST NAVIGATION (Focus >= 0) ---
        if [ -n "$ESC_SEQ" ]; then
            eval "g_idx=\"\$visible_$cur\""
            eval "node=\"\$node_$g_idx\""
            local d="${node%%|*}"; local rest="${node#*|}"
            local id="${rest%%|*}"; rest="${rest#*|}"; local k="${rest##*|}"

            case "$ESC_SEQ" in
                "[A"|"OA") if [ $cur -gt 0 ]; then cur=$((cur-1)); elif [ "$ENABLE_FILTER" = "true" ]; then cur=-1; fi ;;
                "[B"|"OB") [ $cur -lt $((v_count - 1)) ] && cur=$((cur+1)) ;;
                "[C"|"OC") [ "$k" = "true" ] && { _tree_expand "$id"; _update_tree_cache; } ;;
                "[D"|"OD")
                    _tree_remove_expanded "$id"
                    local scan_idx=$((g_idx + 1))
                    while [ $scan_idx -lt $count ]; do
                        eval "snode=\"\$node_$scan_idx\""
                        [ "${snode%%|*}" -le "$d" ] && break
                        local sid="${snode#*|}"; sid="${sid%%|*}"
                        _tree_remove_expanded "$sid"
                        scan_idx=$((scan_idx+1))
                    done
                    _update_tree_cache ;;
                "[5"|"[5~") cur=$((cur - view_height)); [ "$cur" -lt 0 ] && cur=0 ;;
                "[6"|"[6~") cur=$((cur + view_height)); [ "$cur" -ge "$v_count" ] && cur=$((v_count - 1)) ;;
                "[H") cur=0 ;;
                "[F") cur=$((v_count - 1)) ;;
            esac
            continue
        fi

        case "$key" in
            "/") [ "$ENABLE_FILTER" = "true" ] && [ "$cur" -ge 0 ] && cur=-1 ;;
            $_TAB) # TAB toggle filter
                if [ "$ENABLE_FILTER" = "true" ]; then
                    if [ $cur -eq -1 ]; then
                        [ $v_count -gt 0 ] && cur=0
                    else
                        cur=-1
                    fi
                fi ;;
            $_DEL|$_BS) # Backspace Jump
                [ "$ENABLE_FILTER" = "true" ] && cur=-1 ;;
            " ") # Space Toggle
                eval "g_idx=\"\$visible_$cur\""
                eval "node=\"\$node_$g_idx\""
                local d="${node%%|*}"; local rest="${node#*|}"
                local id="${rest%%|*}"; rest="${rest#*|}"
                local l="${rest%%|*}"; local has_kids="${rest##*|}"

                local is_disabled=0; local scan_ptr=$g_idx; local target_d=$d
                while [ $scan_ptr -gt 0 ]; do
                    scan_ptr=$((scan_ptr-1))
                    eval "pnode=\"\$node_$scan_ptr\""
                    local pd="${pnode%%|*}"; local prest="${pnode#*|}"; local pl="${prest#*|}"
                    if [ $pd -lt $target_d ]; then
                        if _match "$pl" "*\[ \]*" || _match "$pl" "*( )*"; then is_disabled=1; break; fi
                        target_d=$pd
                    fi
                done
                [ $is_disabled -eq 1 ] && continue

                if _match "$l" "*\[ \]*" || _match "$l" "*\[x\]*"; then
                    if _match "$l" "*\[ \]*"; then
                        before="${l%%\[ \]*}"; after="${l#*\[ \]}"; l="${before}[x]${after}"
                    else
                        before="${l%%\[x\]*}"; after="${l#*\[x\]}"; l="${before}[ ]${after}"
                        j=$((g_idx+1)); while [ "$j" -lt "$count" ]; do
                            eval "cnode=\"\$node_$j\""
                            local cd="${cnode%%|*}"
                            [ $cd -le $d ] && break
                            local crest="${cnode#*|}"
                            local cid="${crest%%|*}"; crest="${crest#*|}"
                            local cl="${crest%%|*}"; local chk="${crest##*|}"
                            if _match "$cl" "*\[x\]*"; then
                                before="${cl%%\[x\]*}"; after="${cl#*\[x\]}"; cl="${before}[ ]${after}"
                            fi
                            if _match "$cl" "*\(\*\)*"; then
                                before="${cl%%\(\*\)*}"; after="${cl#*\(\*\)}"; cl="${before}( )${after}"
                            fi
                            eval "node_$j='$cd|$cid|$cl|$chk'"
                            j=$((j+1))
                        done
                    fi
                    eval "node_$g_idx='$d|$id|$l|$has_kids'"
                elif _match "$l" "*( )*" || _match "$l" "*\(\*\)*"; then
                     local scan=$g_idx
                     while [ $scan -gt 0 ]; do
                         eval "sn=\"\$node_$((scan-1))\""
                         [ "${sn%%|*}" -lt "$d" ] && break
                         scan=$((scan-1))
                     done
                     local end=$g_idx
                     while [ $end -lt $((count-1)) ]; do
                         eval "en=\"\$node_$((end+1))\""
                         [ "${en%%|*}" -lt "$d" ] && break
                         end=$((end+1))
                     done
                     j=$scan; while [ "$j" -le "$end" ]; do
                        eval "tnode=\"\$node_$j\""
                        local td="${tnode%%|*}"; local trest="${tnode#*|}"
                        local tid="${trest%%|*}"; trest="${trest#*|}"
                        local tl="${trest%%|*}"; local tk="${trest##*|}"
                        if [ $td -eq $d ]; then
                            if _match "$tl" "*\(\*\)*"; then
                                before="${tl%%\(\*\)*}"; after="${tl#*\(\*\)}"; tl="${before}( )${after}"
                            fi
                            eval "node_$j='$td|$tid|$tl|$tk'"
                        fi
                        j=$((j+1))
                     done
                     before="${l%%\( \)*}"; after="${l#*\( \)}"; l="${before}(*)${after}"
                     eval "node_$g_idx='$d|$id|$l|$has_kids'"
                fi
                _update_tree_cache ;;
            "") # Enter (Select/Confirm)
                if [ "$mode" = "select" ]; then
                    eval "g_idx=\"\$visible_$cur\""
                    eval "selection=\"\$node_$g_idx\""
                    local d="${selection%%|*}"
                    local rest="${selection#*|}"
                    local id="${rest%%|*}"
                    rest="${rest#*|}"
                    local label="${rest%%|*}"
                    local path="$id"
                    if [ "$TREE_RETURN_VALUES" = "true" ]; then
                        path="$label"
                    else
                        path="$id"
                    fi
                    local scan=$g_idx
                    local check_d=$d
                    while [ $scan -gt 0 ]; do
                        scan=$((scan-1))
                        eval "snode=\"\$node_$scan\""
                        local sd="${snode%%|*}"
                        if [ $sd -lt $check_d ]; then
                            local srem="${snode#*|}"
                            local sid="${srem%%|*}"
                            srem="${srem#*|}"
                            local slabel="${srem%%|*}"
                            if [ "$TREE_RETURN_VALUES" = "true" ]; then
                                path="${slabel}/$path"
                            else
                                path="${sid}/$path"
                            fi
                            check_d=$sd
                        fi
                    done
                    TUI_RESULT="$path"
                    echo "$TUI_RESULT"
                    return 0
                else
                    TUI_RESULT=""
                    n=0; while [ "$n" -lt "$count" ]; do
                        eval "nv=\"\$node_$n\""
                        echo "$nv"
                        TUI_RESULT="${TUI_RESULT}${nv} "
                        n=$((n+1))
                    done
                    return 0
                fi ;;
            "j"|"s") [ "$cur" -ge 0 ] && [ $cur -lt $((v_count - 1)) ] && cur=$((cur+1)) ;;
            "k"|"w") [ "$cur" -ge 0 ] && [ $cur -gt 0 ] && cur=$((cur-1)) ;;
            "l"|"d") [ "$cur" -ge 0 ] && eval "g_idx=\"\$visible_$cur\"" && eval "node=\"\$node_$g_idx\"" && local rest="${node#*|}" && local k="${rest##*|}" && [ "$k" = "true" ] && { _tree_expand "${rest%%|*}"; _update_tree_cache; } ;;
            "h"|"a") [ "$cur" -ge 0 ] && eval "g_idx=\"\$visible_$cur\"" && eval "node=\"\$node_$g_idx\"" && local d="${node%%|*}" && local rest="${node#*|}" && local id="${rest%%|*}" && { _tree_remove_expanded "$id"; local scan_idx=$((g_idx + 1)); while [ $scan_idx -lt $count ]; do eval "snode=\"\$node_$scan_idx\""; [ "${snode%%|*}" -le "$d" ] && break; local sid="${snode#*|}"; sid="${sid%%|*}"; _tree_remove_expanded "$sid"; scan_idx=$((scan_idx+1)); done; _update_tree_cache; } ;;
            "J") [ "$cur" -ge 0 ] && cur=$((cur + view_height)); [ "$cur" -ge "$v_count" ] && cur=$((v_count - 1)) ;;
            "K") [ "$cur" -ge 0 ] && cur=$((cur - view_height)); [ "$cur" -lt 0 ] && cur=0 ;;
            "g") [ "$cur" -ge 0 ] && cur=0 ;;
            "G") [ "$cur" -ge 0 ] && cur=$((v_count - 1)) ;;
            "?")
                _help_popup tree ;;
            "q") TUI_RESULT=''; return 1 ;;
        esac
    done
}


# Returns a single ID (Dialog style)
# When TREE_RETURN_VALUES=true, returns label paths instead of ID paths.
: ${TREE_RETURN_VALUES:=false}
tree() {
    _tree_widget "select" "$@"
}

# Returns generated Variable pairs
configtree() {
    local raw_output rc
    raw_output=$(_tree_widget "config" "$@") && rc=$? || rc=$?
    [ $rc -ne 0 ] && TUI_RESULT='' && return 1

    local raw_count=0
    local old_ifs="$IFS"; IFS=$'\n'
    for _line in $raw_output; do
        eval "raw_data_$raw_count='$_line'"
        raw_count=$((raw_count+1))
    done
    IFS="$old_ifs"

    local path_stack_count=0
    local skip_depth=-1
    local i node depth id label has_kids remaining

    i=0; while [ "$i" -lt "$raw_count" ]; do
        eval "node=\"\$raw_data_$i\""
        
        # 2. Performance Fix: Native Parameter Expansion instead of 'read <<<'
        depth="${node%%|*}"
        remaining="${node#*|}"
        id="${remaining%%|*}"
        remaining="${remaining#*|}"
        label="${remaining%%|*}"
        # has_kids is rarely needed here but extracted for consistency
        has_kids="${remaining##*|}"
        
        [ "$skip_depth" -ne -1 ] && [ "$depth" -gt "$skip_depth" ] && { i=$((i+1)); continue; }
        skip_depth=-1

        local clean_id="${id//[-.]/_}"
        eval "path_stack_$depth='$clean_id'"
        if [ "$depth" -ge "$path_stack_count" ]; then
            path_stack_count=$((depth+1))
        fi

        local value=""
        case "$label" in
            *"[x]"*|*"(*)"*) value="true" ;;
            *"[ ]"*|*"( )"*) value="false" ;;
        esac

        if [ -n "$value" ]; then
            local var_name=""
            j=0; while [ "$j" -le "$depth" ]; do
                eval "ps=\"\$path_stack_$j\""
                if [ -z "$var_name" ]; then
                    var_name="$ps"
                else
                    var_name="${var_name}_${ps}"
                fi
                j=$((j+1))
            done

            echo "${var_name}=${value}"

            [ "$value" = "false" ] && skip_depth=$depth
        fi
        i=$((i+1))
    done
}

table() {
    local title=$1 msg=$2 src=$3 top=0 cur=$((${4:-0} - 1))
    local header_row="" count=0

    [ ! -f "$src" ] && { msgbox "Error" "File not found: $src"; return 1; }

    _init_tui

    local box_width=$CONTENT_WIDTH
    local first=true
    local w1=$(( box_width * 33 / 100 ))
    local w2=$(( box_width * 26 / 100 ))
    local w3=$(( box_width - w1 - w2 - 2 ))

    while IFS=',' read -r c1 c2 c3 cmd; do
        local formatted=$(printf "%-${w1}s %-${w2}s %-${w3}s" "$c1" "$c2" "$c3")
        if [ "$first" = "true" ]; then
            header_row="$formatted"
            first=false
        else
            eval "disp_$count='$formatted'"
            eval "cmd_$count='$cmd'"
            count=$((count+1))
        fi
    done < "$src"

    while true; do
        _draw_header "$title" "$msg"

        local view_top=$row
        local _fh=$FOOTER_HEIGHT; [ "${TUI_HIDE_FOOTER:-false}" = "true" ] && _fh=0
        local total_table_area=$(( MAX_HEIGHT - view_top - _fh ))
        local data_height=$(( total_table_area - 1 ))
        [ "$data_height" -lt $MIN_CONTENT_HEIGHT ] && data_height=$MIN_CONTENT_HEIGHT

        [ "$cur" -lt "$top" ] && top=$cur
        [ "$cur" -ge "$((top + data_height))" ] && top=$((cur - data_height + 1))

        _draw_at "$row"
        printf "  ${BG_TABLE_HEADER_ESC}${BOLD} %-${box_width}s ${RESET}${BG_MAIN_ESC}" "$header_row" >&2
        local absolute_right_edge=$(( PADDING_LEFT + MAX_WIDTH ))
        printf "\e[${absolute_right_edge}G${RESET}" >&2
        row=$((row+1))

        local data_start_row=$row
        i=0; while [ "$i" -lt "$data_height" ]; do
            local v_idx=$((top + i))
            local current_view_row=$((data_start_row + i))

            _draw_at "$current_view_row"
            printf "$INDENT" >&2

            if [ "$v_idx" -lt "$count" ]; then
                local is_cur=0; [ "$v_idx" -eq "$cur" ] && is_cur=1
                eval "dl=\"\$disp_$v_idx\""
                _draw_item "text" "$is_cur" 0 "$dl" "$box_width"
            fi
            _draw_line "" "$current_view_row"
            i=$((i+1))
        done

        row=$((data_start_row + data_height))
        if [ "$_fh" -ne 0 ]; then
            _draw_line ""
            _draw_controls " ${SB}Up${SR}/${SB}Down${SR} Scroll | ${SB}Enter${SR} Select | ${SB}?${SR} Help"
        fi
        _draw_footer

        _read_key_esc
        _handle_extra_keys "$KEY" && continue

        if [ -n "$ESC_SEQ" ]; then
            case "$ESC_SEQ" in
                "[A"|"OA") [ "$cur" -gt 0 ] && cur=$((cur-1)) ;;
                "[B"|"OB") [ "$cur" -lt "$((count - 1))" ] && cur=$((cur+1)) ;;
                "[5"|"[5~"|"5~") local pg=$((cur - data_height)); [ "$pg" -lt 0 ] && pg=0; cur=$pg ;;
                "[6"|"[6~"|"6~") local pg=$((cur + data_height)); [ "$pg" -ge "$count" ] && pg=$((count - 1)); cur=$pg ;;
                "[H") cur=0 ;;
                "[F") cur=$((count - 1)) ;;
            esac
        elif [ "$KEY" = "j" ] || [ "$KEY" = "s" ]; then
            [ "$cur" -lt "$((count - 1))" ] && cur=$((cur+1))
        elif [ "$KEY" = "k" ] || [ "$KEY" = "w" ]; then
            [ "$cur" -gt 0 ] && cur=$((cur-1))
        elif [ "$KEY" = "J" ]; then
            local pg=$((cur + data_height)); [ "$pg" -ge "$count" ] && pg=$((count - 1)); cur=$pg
        elif [ "$KEY" = "K" ]; then
            local pg=$((cur - data_height)); [ "$pg" -lt 0 ] && pg=0; cur=$pg
        elif [ "$KEY" = "g" ]; then
            cur=0
        elif [ "$KEY" = "G" ]; then
            cur=$((count - 1))
        elif [ "$KEY" = "?" ]; then
            _help_popup table
        elif [ "$KEY" = "q" ]; then
            TUI_RESULT=''
            return 1
        elif [ -z "$KEY" ]; then
            eval "TUI_RESULT=\"\$cmd_$cur\""
            eval "echo \"\$cmd_$cur\""
            return 0
        fi
    done
}

filtertable() {
    local title=$1 msg=$2 src=$3 d=-1
    case "$4" in ''|*[!0-9]*) ;; *) d=$(($4 - 1)) ;; esac

    local filter_query="" last_query="INIT_STATE"
    local cur=$d top=0
    local cursor_prefix="" cursor_suffix=""
    local _saved_cur=0

    [ ! -f "$src" ] && { msgbox "Error" "File not found: $src"; return 1; }

    _init_tui
    local box_width=$CONTENT_WIDTH
    local w1=$(( box_width * 33 / 100 ))
    local w2=$(( box_width * 26 / 100 ))
    local w3=$(( box_width - w1 - w2 - 2 ))

    # --- 2. Master Data Load (Handles dynamic column counts) ---
    local header_row="" first=true
    master_count=0

    while IFS= read -r line; do
        local old_ifs="$IFS"; IFS=','; set -- $line; IFS="$old_ifs"
        local cell_count=$#
        local display_count=$((cell_count - 1))

        local col_w=$(( (box_width - display_count) / display_count ))
        local formatted="" i=0

        while [ "$i" -lt "$display_count" ]; do
            _idx=$((i + 1))
            eval "val=\"\${$_idx}\""
            if [ ${#val} -gt $col_w ]; then
                val=$(echo "$val" | cut -c1-$((col_w - 3)))...
            fi
            part=$(printf "%-${col_w}.${col_w}s " "$val")
            formatted="${formatted}${part}"
            i=$((i+1))
        done

        if [ "$first" = "true" ]; then
            header_row="$formatted"
            first=false
        else
            _cmd_idx=$((display_count + 1))
            eval "cmd_val=\"\${$_cmd_idx}\""
            eval "master_line_$master_count=\"\$formatted\""
            eval "master_search_$master_count=\"\$line\""
            eval "master_search_lc_$master_count=\"\$(_tolower \"\$line\")\""
            eval "master_cmd_$master_count=\"\$cmd_val\""
            master_count=$((master_count+1))
        fi
    done < "$src"

    while true; do
        filter_query="${cursor_prefix}${cursor_suffix}"

        # --- 3. Filtering (Maintain relative master order) ---
        if [ "$filter_query" != "$last_query" ]; then
            filter_count=0
            i=0
            local max_i=$master_count
            [ $max_i -gt $MAX_FILTER_ITEMS ] && max_i=$MAX_FILTER_ITEMS
            _flow=$(_tolower "$filter_query")
            while [ "$i" -lt "$max_i" ]; do
                if [ -n "$filter_query" ]; then
                    eval "_slow=\"\$master_search_lc_$i\""
                    case "$_slow" in *$_flow*) ;; *) i=$((i+1)); continue ;; esac
                fi
                eval "filtered_line_$filter_count=\"\$master_line_$i\""
                eval "filtered_cmd_$filter_count=\"\$master_cmd_$i\""
                filter_count=$((filter_count+1))
                i=$((i+1))
            done
            count=$filter_count
            last_query="$filter_query"
        fi

        _draw_header "$title" "$msg"
        _draw_at "$row"

        local style="${BG_WID_ESC}${FG_TEXT_ESC}"
        [ "$cur" -eq -1 ] && style="${BG_INPUT_ESC}${FG_BLUE_BOLD}"

        local _display="$filter_query"
        local _vis_len=${#filter_query}
        if [ "$cur" -eq -1 ]; then
            _render_cursor_display "$cursor_prefix" "$cursor_suffix"
            _display="$_DISPLAY"
            _vis_len=$_VIS_LEN
        fi
        local _pad=$(( FILTER_WIDTH - _vis_len ))
        [ "$_pad" -lt 0 ] && _pad=0
        printf "  Filter: ${style} > %s%${_pad}s ${RESET}${BG_MAIN_ESC}" "$_display" "" >&2

        _draw_line "" "$row"
        _draw_line ""

        local view_top=$row
        local _fh=$FOOTER_HEIGHT; [ "${TUI_HIDE_FOOTER:-false}" = "true" ] && _fh=0
        local view_height=$(( MAX_HEIGHT - view_top - _fh ))
        [ $view_height -lt 5 ] && view_height=5

        _draw_at "$row"
        printf "  ${BG_TABLE_HEADER_ESC}${BOLD} %-${box_width}.${box_width}s ${RESET}" "${header_row}" >&2
        _draw_line "" "$row"

        local data_top=$row
        local data_height=$(( view_height - 1 ))

        [ $cur -ge $count ] && cur=$((count - 1))
        if [ $cur -ge 0 ]; then
            [ $cur -lt $top ] && top=$cur
            [ $cur -ge $((top + data_height)) ] && top=$((cur - data_height + 1))
        fi

        i=0
        while [ "$i" -lt "$data_height" ]; do
            local v_idx=$((top + i))
            local current_view_row=$((data_top + i))
            _draw_at "$current_view_row"
            printf "$INDENT" >&2

            if [ $v_idx -lt $count ]; then
                local is_cur=0; [ $v_idx -eq $cur ] && is_cur=1
                eval "filtered_line=\"\$filtered_line_$v_idx\""
                _draw_item "text" "$is_cur" 0 "$filtered_line" "$box_width"
            else
                printf "%$((box_width + 2))s" "" >&2
            fi
            _draw_line "" "$current_view_row"
            i=$((i+1))
        done

        row=$((data_top + data_height))
        _draw_footer
        if [ "$_fh" -ne 0 ]; then
            _draw_spacer
            _draw_controls " ${SB}Up${SR}/${SB}Down${SR} Scroll | ${SB}Enter${SR} Select | ${SB}Tab${SR} Focus | ${SB}/${SR} Filter | ${SB}?${SR} Help"
        fi

        _read_key_esc
        _handle_extra_keys "$KEY" && continue

        if [ -n "$ESC_SEQ" ]; then
            case "$ESC_SEQ" in
                "[A"|"OA") [ "$cur" -ge 0 ] && cur=$((cur-1)) ;;
                "[B"|"OB")
                    if [ "$cur" -eq -1 ] && [ "$count" -gt 0 ]; then
                        cur=0
                    elif [ "$cur" -ge 0 ] && [ "$cur" -lt "$((count-1))" ]; then
                        cur=$((cur+1))
                    fi ;;
                "[C"|"OC") [ "$cur" -eq -1 ] && _cursor_right cursor_prefix cursor_suffix ;;
                "[D"|"OD") [ "$cur" -eq -1 ] && _cursor_left cursor_prefix cursor_suffix ;;
                "[3")
                    _read_str_timeout 1 _del_c
                    [ "$cur" -eq -1 ] && [ "$_del_c" = "~" ] && [ -n "$cursor_suffix" ] && cursor_suffix="${cursor_suffix#?}"
                    ;;
                "[5"|"[5~"|"5~") [ "$cur" -ge 0 ] && cur=$((cur - data_height)); [ "$cur" -lt 0 ] && cur=0 ;;
                "[6"|"[6~"|"6~") [ "$cur" -ge 0 ] && cur=$((cur + data_height)); [ "$cur" -ge "$count" ] && cur=$((count - 1)) ;;
                "[H") [ "$cur" -ge 0 ] && cur=0 ;;
                "[F") [ "$cur" -ge 0 ] && cur=$((count - 1)) ;;
            esac
            continue
        fi

        case "$KEY" in
            "j"|"k"|"s"|"w")
                if [ "$cur" -ge 0 ]; then
                    [ "$KEY" = "j" ] || [ "$KEY" = "s" ] && [ "$cur" -lt "$((count - 1))" ] && cur=$((cur+1))
                    [ "$KEY" = "k" ] || [ "$KEY" = "w" ] && [ "$cur" -gt 0 ] && cur=$((cur-1))
                elif [ "$cur" -eq -1 ]; then
                    cursor_prefix="${cursor_prefix}${KEY}"
                fi ;;
            "") # Enter
                if [ $cur -ge 0 ]; then
                    if [ $count -gt 0 ]; then
                        eval "TUI_RESULT=\"\$filtered_cmd_$cur\""
                        eval "echo \"\$filtered_cmd_$cur\""
                        return 0
                    fi
                else
                    [ $count -gt 0 ] && cur=0
                fi ;;
            "$_DEL"|"$_BS") # BACKSPACE
                if [ "$cur" -eq -1 ]; then
                    if [ -n "$cursor_prefix" ]; then
                        cursor_prefix="${cursor_prefix%?}"
                    else
                        [ "$count" -gt 0 ] && cur=0
                    fi
                elif [ "$cur" -ge 0 ]; then
                    cur=-1
                fi ;;
            "$_TAB") # TAB
                if [ "$cur" -eq -1 ]; then
                    [ -z "$cursor_prefix" ] && [ "$count" -gt 0 ] && cur=0
                else
                    _saved_cur=$cur
                    cur=-1
                fi ;;
            "?")
                _help_popup filtertable ;;
            "J")
                if [ "$cur" -ge 0 ]; then
                    cur=$((cur + data_height))
                    [ "$cur" -ge "$count" ] && cur=$((count - 1))
                elif [ "$cur" -eq -1 ]; then
                    cursor_prefix="${cursor_prefix}${KEY}"
                fi ;;
            "K")
                if [ "$cur" -ge 0 ]; then
                    cur=$((cur - data_height))
                    [ "$cur" -lt 0 ] && cur=0
                elif [ "$cur" -eq -1 ]; then
                    cursor_prefix="${cursor_prefix}${KEY}"
                fi ;;
            "g") [ "$cur" -ge 0 ] && cur=0 || { [ "$cur" -eq -1 ] && cursor_prefix="${cursor_prefix}${KEY}"; } ;;
            "G") [ "$cur" -ge 0 ] && cur=$((count - 1)) || { [ "$cur" -eq -1 ] && cursor_prefix="${cursor_prefix}${KEY}"; } ;;
            "q") if [ "$cur" -eq -1 ]; then cursor_prefix="${cursor_prefix}${KEY}"; else TUI_RESULT=''; return 1; fi ;;
            "/") [ "$cur" -ge 0 ] && cur=-1 ;;
            *)
                if [ "$cur" -eq -1 ]; then
                    case "$KEY" in [[:print:]])
                        cursor_prefix="${cursor_prefix}${KEY}"
                        top=0 ;;
                    esac
                fi ;;
        esac
    done
}

modal() {
    local _saved_backtitle="$BACKTITLE"
    local BACKTITLE=
    local _saved_bg_main="$BG_MAIN"
    local old_mode="$TUI_MODE"
    local old_modal="$TUI_MODAL"
    
    local _user_set_bg_modal="${BG_MODAL:+1}"

    if [ -n "$_user_set_bg_modal" ]; then
        local BG_MAIN="$BG_MODAL"
    elif [ "$old_mode" = "fullscreen" ]; then
        local BG_MAIN="${BG_MODAL:-50;50;50}"
    else
        local BG_MAIN="$_saved_bg_main"
    fi

    local target_mode="$TUI_MODE"
    if [ "$target_mode" = "fullscreen" ] || [ -z "$target_mode" ]; then
        target_mode="centered"
    fi
    
    TUI_MODE="$target_mode"
    TUI_MODAL="true"

    stty sane; stty -echo

    eval "$1"

    TUI_MODE="$old_mode"
    TUI_MODAL="$old_modal"
    
    BACKTITLE="$_saved_backtitle"
    BG_MAIN="$_saved_bg_main"
    _init_tui 
}

mainmenu() {
    local title=$1 msg="$2" dsl=$3
    local cur_side=$(( ${4:-1} - 1 ))
    
    local initial_table_idx=$5
    local cur_table=-1
    local focus=0

    if [[ -n "$initial_table_idx" ]]; then
        cur_table=$((initial_table_idx - 1))
        focus=1
    fi
    
    local last_side=-2 
    local last_query="INIT"
    local filter_query="" cursor_prefix="" cursor_suffix="" table_top=0 force_refilter=0
    local sort_col=-1 sort_asc=1 col_count=0

    local side_count=0
    while IFS=':' read -r lab desc fil; do
        [ -z "$lab" ] && continue
        eval "side_label_$side_count='$lab'"
        eval "side_msg_$side_count='$desc'"
        eval "side_file_$side_count='$fil'"
        side_count=$((side_count+1))
    done <<EOF
$dsl
EOF

    [[ $cur_side -ge $side_count ]] && cur_side=$((side_count - 1))
    [[ $cur_side -lt 0 ]] && cur_side=0

    TUI_MODE="fullscreen" 
    _init_tui 

    local side_w=$(( MAX_WIDTH * 25 / 100 ))
    local table_x=$(( side_w + 6 )) 
    local table_w=$(( MAX_WIDTH - table_x - 3 ))
    local absolute_table_x_esc="\e[$(( PADDING_LEFT + table_x ))G"

    while true; do
        filter_query="${cursor_prefix}${cursor_suffix}"
        # 3. DATA LOADER
        if [[ $cur_side -ne $last_side ]]; then
            eval "src=\$side_file_$cur_side"
            master_count=0; master_cmd_count=0; master_rd_count=0
            sort_col=-1; sort_asc=1

            if [[ -f "$src" ]]; then
                {
                    read -r header_line
                    old_ifs="$IFS"; IFS=','; set -- $header_line; IFS="$old_ifs"
                    col_count=$(($# - 1))
                    i=0; while [ "$i" -lt "$col_count" ]; do
                        eval "header_label_$i=\${$((i+1))}"
                        i=$((i+1))
                    done
                } < "$src"

                local widths=$(awk -F',' -v n=$col_count \
                    '{for(i=1;i<=n;i++){len=length($i);if(len>max[i])max[i]=len}}
                     END{for(i=1;i<=n;i++)printf "%d ",max[i]}' "$src")
                i=0; for w in $widths; do
                    [ -z "$w" ] && w=0
                    w=$((w+2))
                    eval "dw_$i=$w"
                    i=$((i+1))
                done

                {
                    read -r header_line

                    table_header=""
                    i=0; while [ "$i" -lt "$col_count" ]; do
                        eval "lbl=\$header_label_$i"
                        eval "w=\$dw_$i"
                        part=$(printf "%-${w}s" "$lbl")
                        table_header="${table_header}${part} "
                        i=$((i+1))
                    done
                    table_header="${table_header% }"

                    while IFS=',' read -r fields; do
                        old_ifs="$IFS"; IFS=','; set -- $fields; IFS="$old_ifs"
                        eval "cmd=\${$((col_count+1))}"
                        fmt=""
                        i=0; while [ "$i" -lt "$col_count" ]; do
                            eval "w=\$dw_$i"
                            eval "fv=\${$((i+1))}"
                            part=$(printf "%-${w}s" "$fv")
                            fmt="${fmt}${part} "
                            i=$((i+1))
                        done
                        fmt="${fmt% }"
                        eval "master_line_$master_count=\"\$fmt\""
                        eval "master_line_lc_$master_count=\"\$(_tolower \"\$fmt\")\""
                        _cmd_safe="$cmd"; eval "master_cmd_$master_cmd_count=\"\$_cmd_safe\""
                        rd=""
                        i=0; while [ "$i" -lt "$col_count" ]; do
                            eval "fv=\${$((i+1))}"
                            rd="${rd}${fv}"$'\t'
                            i=$((i+1))
                        done
                        eval "master_rd_$master_rd_count=\"\$rd\""
                        master_count=$((master_count+1))
                        master_cmd_count=$((master_cmd_count+1))
                        master_rd_count=$((master_rd_count+1))
                    done
                } < "$src"
            fi
            
            if [[ $last_side -ne -2 ]]; then
                [[ "$TUI_PERSISTENT_FILTERS" != "true" ]] && filter_query=""
                cur_table=-1
                table_top=0
            fi
            
            last_side=$cur_side
            force_refilter=$((force_refilter+1))
        fi

        # 4. CONDITIONAL FILTER
        if [[ "$filter_query" != "$last_query" || $force_refilter -gt 0 ]]; then
            filtered_count=0; filtered_cmd_count=0
            q_lower=$(_tolower "$filter_query")
            sp="*${q_lower}*"
            i=0; while [ "$i" -lt "$master_count" ]; do
                [ $i -ge $MAX_FILTER_ITEMS ] && break
                eval "ml=\$master_line_$i"
                if [ -z "$filter_query" ]; then
                    eval "filtered_line_$filtered_count=\$master_line_$i"
                    eval "filtered_cmd_$filtered_cmd_count=\$master_cmd_$i"
                    filtered_count=$((filtered_count+1))
                    filtered_cmd_count=$((filtered_cmd_count+1))
                else
                    eval "ml_lower=\"\$master_line_lc_$i\""
                    case "$ml_lower" in
                        $sp)
                            eval "filtered_line_$filtered_count=\$master_line_$i"
                            eval "filtered_cmd_$filtered_cmd_count=\$master_cmd_$i"
                            filtered_count=$((filtered_count+1))
                            filtered_cmd_count=$((filtered_cmd_count+1))
                            ;;
                    esac
                fi
                i=$((i+1))
            done
            f_count=$filtered_count
            
            [[ $cur_table -ge $f_count ]] && cur_table=$((f_count - 1))
            
            last_query="$filter_query"; force_refilter=0
        fi

        # 5. RENDERING
        local frame=""

        _draw_header "$title" "$msg"
        
        local list_top=$row
        
        local _fh=$FOOTER_HEIGHT; [ "${TUI_HIDE_FOOTER:-false}" = "true" ] && _fh=0
        local view_h=$(( MAX_HEIGHT - list_top - _fh ))
        [[ $view_h -lt 5 ]] && view_h=5
        
        local data_h=$(( view_h - 3 ))

        if [[ $cur_table -ge 0 ]]; then
            [[ $cur_table -lt $table_top ]] && table_top=$cur_table
            [[ $cur_table -ge $((table_top + data_h)) ]] && table_top=$((cur_table - data_h + 1))
        fi

        i=0; while [ "$i" -lt "$view_h" ]; do
            local draw_row=$((list_top + i))
            local row_content="\e[${draw_row};${PADDING_LEFT}H${BG_MAIN_ESC} "
            
            if [[ $i -lt $side_count ]]; then
                local style="${BG_WID_ESC}${FG_TEXT_ESC}"
                if [[ $i -eq $cur_side ]]; then
                    [[ $focus -eq 0 ]] && style=$HL_WHITE_BOLD || style="${BG_WID_ESC}${FG_TEXT_ESC}${BOLD}"
                fi
                eval "sl=\$side_label_$i"
                item=$(printf "${BG_MAIN_ESC} ${style} %-$((side_w - 2))s ${RESET}${BG_MAIN_ESC}" "$sl")
                row_content="$row_content$item"
            else 
                item=$(printf "${BG_MAIN_ESC} %$((side_w))s" "")
                row_content="$row_content$item"
            fi

            row_content="$row_content$absolute_table_x_esc"

            if [[ $i -eq 0 ]]; then
                local s_style=$BG_WID_ESC; [[ $focus -eq 1 && $cur_table -eq -1 ]] && s_style=$BG_INPUT_ESC
                local lbl_style=$([ "$focus" = "1" ] && [ "$cur_table" = "-1" ] && echo "${FG_BLUE_BOLD}" || echo "${FG_TEXT_ESC}")
                local _display="$filter_query" _vis_len=${#filter_query}
                if [[ $focus -eq 1 && $cur_table -eq -1 ]]; then
                    _render_cursor_display "$cursor_prefix" "$cursor_suffix"
                    _display="$_DISPLAY"
                    _vis_len=$_VIS_LEN
                fi
                local _pad=$((20 - _vis_len)); [ "$_pad" -lt 0 ] && _pad=0
                item=$(printf "${lbl_style}Filter: ${s_style}${lbl_style} > ${FG_INPUT_ESC}%s%${_pad}s ${RESET}${BG_MAIN_ESC}" "$_display" "")
                row_content="$row_content$item"
            elif [[ $i -eq 2 ]]; then
                item=$(printf "${BG_TABLE_HEADER_ESC}${BOLD} %-${table_w}s ${RESET}${BG_MAIN_ESC}" "$table_header")
                row_content="$row_content$item"
            elif [[ $i -ge 3 ]]; then
                local data_idx=$((i - 3 + table_top))
                if [[ $f_count -eq 0 ]]; then
                    if [[ $i -eq 3 ]]; then
                        row_content="${row_content}${FG_HINT_ESC}No matching items found...${RESET}${BG_MAIN_ESC}${CLR_EOL}"
                    else
                        row_content="${row_content}${BG_MAIN_ESC}${CLR_EOL}"
                    fi
                elif [[ $data_idx -lt $f_count ]]; then
                    local style="${BG_WID_ESC}${FG_TEXT_ESC}"; [[ $data_idx -eq $cur_table && $focus -eq 1 ]] && style=$HL_WHITE_BOLD
                    eval "fl=\$filtered_line_$data_idx"
                    item=$(printf "${style} %-${table_w}s ${RESET}${BG_MAIN_ESC}${CLR_EOL}" "$fl")
                    row_content="$row_content$item"
                else
                    row_content="${row_content}${CLR_EOL}"
                fi
            fi
            frame="$frame$row_content"
            i=$((i+1))
        done

        if [ "$_fh" -ne 0 ]; then
            local footer_row=$((list_top + view_h + 1))
            frame="${frame}\e[${footer_row};${PADDING_LEFT}H${FG_HINT_ESC}  ${SB}Arrows${SR} Navigate | ${SB}Enter${SR} Select | ${SB}Tab${SR} Switch | ${SB}1-9${SR} Sort | ${SB}q${SR} Quit | ${SB}?${SR} Help ${RESET}"
        fi

        LAST_FRAME="$frame"
        printf "%b" "$frame" >&2

        # 6. INPUT HANDLING
        _read_key key
        _handle_extra_keys "$key" && continue
        case "$key" in
            $'\t') focus=$((1 - focus)); continue ;;
            $'\033') _read_str_timeout 2 key
                case "$key" in
                    "[A"|"OA") [[ $focus -eq 0 ]] && { [[ $cur_side -gt 0 ]] && cur_side=$((cur_side-1)); } || { [[ $cur_table -gt -1 ]] && cur_table=$((cur_table-1)); } ;;
                    "[B"|"OB") [[ $focus -eq 0 ]] && { [[ $cur_side -lt $((side_count-1)) ]] && cur_side=$((cur_side+1)); } || { [[ $cur_table -lt $((f_count-1)) ]] && cur_table=$((cur_table+1)); } ;;
                    "[C"|"OC") if [[ $focus -eq 1 && $cur_table -eq -1 ]]; then _cursor_right cursor_prefix cursor_suffix; else focus=1; [[ $cur_table -lt 0 && $f_count -gt 0 ]] && cur_table=0; fi ;;
                    "[D"|"OD") if [[ $focus -eq 1 && $cur_table -eq -1 ]]; then _cursor_left cursor_prefix cursor_suffix; else focus=0; fi ;;
                    "[3") _read_str_timeout 1 _del_c
                        if [ "$_del_c" = "~" ] && [[ $focus -eq 1 && $cur_table -eq -1 ]] && [ -n "$cursor_suffix" ]; then
                            cursor_suffix="${cursor_suffix#?}"
                            filter_query="${cursor_prefix}${cursor_suffix}"
                        fi ;;
                    "[5"|"[5~")
                        if [[ $focus -eq 0 ]]; then
                            [[ $cur_side -gt 0 ]] && cur_side=0
                        elif [[ $cur_table -gt 0 ]]; then
                            local pg=$((cur_table - data_h)); [[ $pg -lt 0 ]] && pg=0; cur_table=$pg
                        fi ;;
                    "[6"|"[6~")
                        if [[ $focus -eq 0 ]]; then
                            [[ $cur_side -lt $((side_count-1)) ]] && cur_side=$((side_count-1))
                        elif [[ $cur_table -lt $((f_count-1)) ]]; then
                            local pg=$((cur_table + data_h)); [[ $pg -ge $f_count ]] && pg=$((f_count - 1)); cur_table=$pg
                        fi ;;
                    "[H")
                        if [[ $focus -eq 0 ]]; then cur_side=0
                        elif [[ $cur_table -ge 0 ]]; then cur_table=0
                        elif [[ $f_count -gt 0 ]]; then cur_table=0; fi ;;
                    "[F")
                        if [[ $focus -eq 0 ]]; then cur_side=$((side_count - 1))
                        elif [[ $cur_table -ge 0 ]]; then cur_table=$((f_count - 1))
                        elif [[ $f_count -gt 0 ]]; then cur_table=$((f_count - 1)); fi ;;
                esac
                continue ;;
        esac

        case "$key" in
            "/") 
                if [[ $focus -eq 1 && $cur_table -eq -1 ]]; then
                    cursor_prefix="${cursor_prefix}${key}"
                    filter_query="${cursor_prefix}${cursor_suffix}"
                else
                    focus=1
                    cur_table=-1
                fi
                ;;
            "?")
                _help_popup mainmenu ;;
            "q") if [[ $focus -eq 1 && $cur_table -eq -1 ]]; then cursor_prefix="${cursor_prefix}${key}"; filter_query="${cursor_prefix}${cursor_suffix}"; else TUI_RESULT=''; return 1; fi ;;
            "j"|"s") if [[ $focus -eq 1 && $cur_table -eq -1 ]]; then cursor_prefix="${cursor_prefix}${key}"; filter_query="${cursor_prefix}${cursor_suffix}"; elif [[ $focus -eq 0 ]]; then [[ $cur_side -lt $((side_count-1)) ]] && cur_side=$((cur_side+1)); else [[ $cur_table -lt $((f_count-1)) ]] && cur_table=$((cur_table+1)); fi ;;
            "k"|"w") if [[ $focus -eq 1 && $cur_table -eq -1 ]]; then cursor_prefix="${cursor_prefix}${key}"; filter_query="${cursor_prefix}${cursor_suffix}"; elif [[ $focus -eq 0 ]]; then [[ $cur_side -gt 0 ]] && cur_side=$((cur_side-1)); else [[ $cur_table -gt -1 ]] && cur_table=$((cur_table-1)); fi ;;
            "J") if [[ $focus -eq 1 && $cur_table -eq -1 ]]; then cursor_prefix="${cursor_prefix}${key}"; filter_query="${cursor_prefix}${cursor_suffix}"; elif [[ $focus -eq 0 ]]; then [[ $cur_side -lt $((side_count-1)) ]] && cur_side=$((side_count-1)); elif [[ $cur_table -lt $((f_count-1)) ]]; then local pg=$((cur_table + data_h)); [[ $pg -ge $f_count ]] && pg=$((f_count - 1)); cur_table=$pg; fi ;;
            "K") if [[ $focus -eq 1 && $cur_table -eq -1 ]]; then cursor_prefix="${cursor_prefix}${key}"; filter_query="${cursor_prefix}${cursor_suffix}"; elif [[ $focus -eq 0 ]]; then [[ $cur_side -gt 0 ]] && cur_side=0; elif [[ $cur_table -gt 0 ]]; then local pg=$((cur_table - data_h)); [[ $pg -lt 0 ]] && pg=0; cur_table=$pg; fi ;;
            "g") if [[ $focus -eq 1 && $cur_table -eq -1 ]]; then cursor_prefix="${cursor_prefix}${key}"; filter_query="${cursor_prefix}${cursor_suffix}"; elif [[ $focus -eq 0 ]]; then cur_side=0; elif [[ $cur_table -ge 0 ]]; then cur_table=0; elif [[ $f_count -gt 0 ]]; then cur_table=0; fi ;;
            "G") if [[ $focus -eq 1 && $cur_table -eq -1 ]]; then cursor_prefix="${cursor_prefix}${key}"; filter_query="${cursor_prefix}${cursor_suffix}"; elif [[ $focus -eq 0 ]]; then cur_side=$((side_count - 1)); elif [[ $cur_table -ge 0 ]]; then cur_table=$((f_count - 1)); elif [[ $f_count -gt 0 ]]; then cur_table=$((f_count - 1)); fi ;;
            "")  # Enter
                if [[ $focus -eq 0 ]]; then
                    focus=1; cur_table=-1
                elif [[ $cur_table -eq -1 ]]; then
                    [[ $f_count -gt 0 ]] && cur_table=0
                elif [[ $cur_table -ge 0 ]]; then
                    eval "cmd=\$filtered_cmd_$cur_table"
                    case "$cmd" in *"modal "*)
                        eval "$cmd"
                        if [[ -n "$TUI_RESULT" ]]; then
                            case "$cmd" in *"form "*) eval "$TUI_RESULT" ;; esac
                        fi
                        stty flush < /dev/tty 2>/dev/null || stty -echo echo
                        TUI_MODE="fullscreen"
                        _init_tui ;;
                    *)
                        TUI_RESULT="$cmd"
                        echo "$TUI_RESULT"
                        return 0 ;;
                    esac
                fi ;;
            [1-9])  if [[ $focus -eq 1 && $cur_table -eq -1 ]]; then
                        cursor_prefix="${cursor_prefix}${key}"
                        filter_query="${cursor_prefix}${cursor_suffix}"
                    elif [[ $focus -eq 1 && $col_count -gt 0 ]]; then
                        local col=$((key - 1))
                        if [[ $col -lt $col_count ]]; then
                            [[ $col -eq $sort_col ]] && sort_asc=$((1 - sort_asc)) || { sort_col=$col; sort_asc=1; }
                            tmp_sort="/tmp/tui_sort_$$.txt"
                            > "$tmp_sort"
                            i=0; while [ "$i" -lt "$master_count" ]; do
                                [ $i -ge $MAX_FILTER_ITEMS ] && break
                                eval "rd=\$master_rd_$i"
                                # extract column $col from tab-separated rd using shell PE (avoids awk fork)
                                local _sk_rem="$rd"
                                local _fi=1
                                while [ "$_fi" -le "$col" ]; do
                                    _sk_rem="${_sk_rem#*$'\t'}"
                                    _fi=$((_fi+1))
                                done
                                sk="${_sk_rem%%$'\t'*}"
                                echo "$sk|$i" >> "$tmp_sort"
                                i=$((i+1))
                            done
                            if [[ $sort_asc -eq 1 ]]; then
                                sorted=$(sort -t'|' -k1 "$tmp_sort" 2>/dev/null | cut -d'|' -f2)
                            else
                                sorted=$(sort -t'|' -k1r "$tmp_sort" 2>/dev/null | cut -d'|' -f2)
                            fi
                            rm -f "$tmp_sort"
                            new_count=0
                            for si in $sorted; do
                                eval "tmp_ml_$new_count=\"\$master_line_$si\""
                                eval "tmp_mlc_$new_count=\"\$master_line_lc_$si\""
                                eval "tmp_mc_$new_count=\"\$master_cmd_$si\""
                                eval "tmp_mr_$new_count=\"\$master_rd_$si\""
                                new_count=$((new_count+1))
                            done
                            i=0; while [ "$i" -lt "$new_count" ]; do
                                eval "master_line_$i=\"\$tmp_ml_$i\""
                                eval "master_line_lc_$i=\"\$tmp_mlc_$i\""
                                eval "master_cmd_$i=\"\$tmp_mc_$i\""
                                eval "master_rd_$i=\"\$tmp_mr_$i\""
                                i=$((i+1))
                            done
                            master_count=$new_count
                            master_cmd_count=$new_count
                            master_rd_count=$new_count
                            table_header=""
                            i=0; while [ "$i" -lt "$col_count" ]; do
                                eval "lbl=\$header_label_$i"
                                eval "w=\$dw_$i"
                                [[ $i -eq $sort_col ]] && { [[ $sort_asc -eq 1 ]] && lbl="^$lbl" || lbl="v$lbl"; }
                                part=$(printf "%-${w}s" "$lbl")
                                table_header="${table_header}${part} "
                                i=$((i+1))
                            done
                            table_header="${table_header% }"
                            force_refilter=1
                        fi
                    fi ;;
            $'\177'|$'\b')
                if [[ $focus -eq 1 && $cur_table -eq -1 ]]; then
                    if [ -n "$cursor_prefix" ]; then
                        cursor_prefix="${cursor_prefix%?}"
                        filter_query="${cursor_prefix}${cursor_suffix}"
                    elif [ $f_count -gt 0 ]; then
                        cur_table=0
                    fi
                elif [[ $focus -eq 1 ]]; then
                    if [ -n "$cursor_prefix" ]; then
                        cursor_prefix="${cursor_prefix%?}"
                        filter_query="${cursor_prefix}${cursor_suffix}"
                    fi
                    cur_table=-1
                fi ;;
            *) if [ $focus -eq 1 ]; then case "$key" in [[:print:]]) cursor_prefix="${cursor_prefix}${key}"; filter_query="${cursor_prefix}${cursor_suffix}"; cur_table=-1;; esac; fi ;;
        esac
    done
}

_execute_mode_action() {
    eval "current_node=\$raw_$cur"
    local current_path="${current_node%%|*}"
    local targets=""

    # 1. FORCE sync the local variable with the global prompt_buffer
    local cmd="$prompt_buffer"
    
    #msgbox "DEBUG" "Buffer was: [$cmd]"
    
    case "$cmd" in cd\ *|"cd..")
        local target_dir="${cmd#cd }"
        [[ "$cmd" == "cd.." ]] && target_dir=".."

        # Handle '~' expansion safely for Bash 3.2
        if [[ "${target_dir:0:1}" == "~" ]]; then
            target_dir="${HOME}${target_dir:1}"
        fi

        # 3. ROBUST PATH RESOLUTION
        # Resolve against the TUI's root_dir, not the script's launch dir
        local resolved="$target_dir"
        [[ "${target_dir:0:1}" != "/" ]] && resolved="$root_dir/$target_dir"

        if [[ -d "$resolved" ]]; then
            # Update the global root_dir
            root_dir=$(cd "$resolved" && pwd)
            
            # Reset UI state and force a re-scan of the new folder
            ui_mode="NAV"
            prompt_buffer=""
            prompt_pos=0
            rebuild=1
            cur=0
            last_dir="FORCE_REBUILD" 
            return 0
        else
            msgbox "Error" "Directory not found: $target_dir"
            return 1
        fi ;;
    esac

    # --- Standard Command Handling ---
    local tagged_count=0
    local si=0; while [ "$si" -lt "$sel_path_count" ]; do
        eval "item=\$selpath_$si"
        if [[ -n "$item" ]]; then
            targets="${targets}'${item}' "
            tagged_count=$((tagged_count+1))
        fi
        si=$((si+1))
    done
    [[ $tagged_count -eq 0 ]] && targets="'$current_path'"

    case "$ui_mode" in
        "CMD"|"SUDO_CMD")
            local final_cmd="${prompt_buffer//\{\}/$targets}"
            final_cmd="${final_cmd//sel/$targets}"
            
            # 1. Create a temporary file to capture output
            local out_tmp="/tmp/tui_out_$$.txt"
            
            if [[ "$ui_mode" == "SUDO_CMD" ]]; then
                # Run sudo and capture BOTH stdout and stderr to the temp file
                # Use 'tee' so the user sees output in real-time
                sudo sh -c "cd '$root_dir' && $final_cmd" 2>&1 | tee "$out_tmp"
            else
                # Run standard command and capture output
                ( cd "$root_dir" && eval "$final_cmd" ) 2>&1 | tee "$out_tmp"
            fi

            # 2. Check if the file is NOT empty
            if [[ -s "$out_tmp" ]]; then
                local _saved_title="$title"
                textbox "Command Output" "Executed: $final_cmd" "$out_tmp"
                title="$_saved_title"
            fi

            # 3. Clean up and restore TUI
            rm -f "$out_tmp"
            _hide_cursor
            prompt_buffer=""; prompt_pos=0; ui_mode="NAV"; rebuild=1
            ;;

        "RENAME")
            new_path="$root_dir/$prompt_buffer"
            mv "$current_path" "$new_path"
            
            # --- THE FIX: Make focus follow the renamed file ---
            last_path="$new_path"
            cur=-2
            
            ui_mode="NAV"
            sel_path_count=0
            ;;
        "NEW_F")
            new_path="$root_dir/$prompt_buffer"
            # Use touch to create the file
            touch "$new_path"
            # Set this so the sidebar snaps focus to the new file
            last_path="$new_path"
            cur=-2
            ;;
        "NEW_D")
            new_path="$root_dir/$prompt_buffer"
            # Create directory
            mkdir -p "$new_path"
            last_path="$new_path"
            cur=-2
            ;;
    esac
}

_get_prompt_msg() {
    local black_bg="${BG_INPUT_ESC}"
    local white_fg="\e[1;37m"
    local blue_fg="\e[1;38;2;${FG_INPUT}m"
    local red_fg="\e[1;38;2;${FG_INPUT_ROOT}m"
    local prompt_fg="$blue_fg"
    
    case "$ui_mode" in
        "CMD")       symbol=" $ ";        content="$prompt_buffer" ;; 
        "SUDO_CMD")  symbol=" # ";        content="$prompt_buffer" ;; 
        "SEARCH")    symbol="Search: > "; content=" $search_query" ;; 
        "RENAME")    symbol="Rename: ";   content=" $prompt_buffer" ;; 
        "NEW_F")     symbol="File name: ";     content=" $prompt_buffer" ;; 
        "NEW_D")     symbol="Dir name: ";      content=" $prompt_buffer" ;; 
    esac

    local total_w=$CONTENT_WIDTH_WIDE
    
    if [[ "$ui_mode" == "CMD" || "$ui_mode" == "SUDO_CMD" ]]; then
        if [[ "$ui_mode" == "SUDO_CMD" ]]; then
            prompt_fg="$red_fg"
        fi
        local colored_sym="${prompt_fg}${symbol}${white_fg}"
        header_msg=$(printf "${black_bg}${colored_sym}%-$((total_w - ${#symbol}))s${RESET}${BG_MAIN_ESC}" "$content")
    else
        local fill_w=$(( total_w - ${#symbol} ))
        header_msg=$(printf "${symbol}${black_bg}${white_fg}%-${fill_w}s${RESET}${BG_MAIN_ESC}" "$content")
    fi
}

_refresh_prompt() {
    _get_prompt_msg
    local p_row=$(( PADDING_TOP + $(_get_start_row) ))
    
    if [[ "$TUI_MODE" == "fullscreen" && "$BACKTITLE" != "" ]];then
        p_row=$(( PADDING_TOP + $(_get_start_row) + 1))
    fi

    # Just draw the text, don't move the cursor for typing yet
    printf "\e[${p_row};${PADDING_LEFT}H${BG_MAIN_ESC}  %b" "$header_msg" >&2
}

_refresh_sidebar_only() {
    local clean_query="${search_query# }" 
    local f_idx=0

    local lc_query=""
    [ -n "$clean_query" ] && lc_query=$(_tolower "$clean_query")

    local si=0; while [ "$si" -lt "$master_raw_count" ]; do
        eval "item=\$master_raw_$si"
        local name="${item#*|}"
        name="${name%|*}"
        
        # If query is empty, or name matches the glob pattern
        if [[ "$name" == ".." ]] || [[ -z "$clean_query" ]]; then
            eval "raw_$f_idx='$item'"
            f_idx=$((f_idx+1))
        else
            eval "lc_name=\"\$raw_lc_$si\""
            case "$lc_name" in
                *"$lc_query"*)
                    eval "raw_$f_idx='$item'"
                    f_idx=$((f_idx+1))
                    ;;
            esac
        fi
        si=$((si+1))
    done

    raw_count=$f_idx
    cur=0; top=0

    local list_top=$(( PADDING_TOP + row ))
    
    local _fh=$FOOTER_HEIGHT; [ "${TUI_HIDE_FOOTER:-false}" = "true" ] && _fh=0
    local height=${1:-$(( MAX_HEIGHT - row - _fh ))}
    [[ $height -lt 1 ]] && height=1 

    i=0; while [ "$i" -lt "$height" ]; do
        local v_idx=$((top + i))
        local current_row=$((list_top + i))
        
        [[ $current_row -ge $((PADDING_TOP + MAX_HEIGHT - 1)) ]] && break
        
        printf "\e[${current_row};${PADDING_LEFT}H${BG_MAIN_ESC}  " >&2
        
        if [[ $v_idx -lt $raw_count ]]; then
            eval "node=\$raw_$v_idx"
            local path="${node%%|*}"
            local remain="${node#*|}"
            local label="${remain%|*}"
            local is_dir="${remain##*|}"
            
            local is_cur=0; [[ $v_idx -eq $cur ]] && is_cur=1
            local style=$BG_WID_ESC
            [[ $is_cur -eq 1 ]] && style=$HL_WHITE_BOLD
            
            local color=$FG_TEXT_ESC
            if [[ "$is_dir" == "true" ]]; then
                color="\e[1;34m" 
            elif [[ -x "$path" ]]; then
                color="\e[1;32m"
            elif [[ "${label:0:1}" == "." ]]; then
                        color="${FG_TEXT_ESC}\e[2m"
            fi

            printf "${style}${color} %-${menu_w}s ${RESET}${BG_MAIN_ESC}" "${label:0:$menu_w}" >&2
        else
            printf "%$((menu_w + 2))s" "" >&2
        fi
        i=$((i+1))
    done
}

_update_display_path() {
    display_path="$root_dir"
    # Home replacement
    case "$display_path" in "$HOME"*) display_path="~${display_path#$HOME}" ;; esac

    local filter_suffix=""
    # Use the search_query variable. 
    # If your search query has the leading UI space, strip it.
    local clean_q="${search_query# }"
    if [[ -n "$clean_q" ]]; then
        filter_suffix=" (Filter: $clean_q)"
    fi
    
    # Calculate width and truncate as we did before...
    local avail_w=$(( MAX_WIDTH - 10 - ${#filter_suffix} ))
    [[ $avail_w -lt 10 ]] && avail_w=10

    if [[ ${#display_path} -gt $avail_w ]]; then
        local offset=$(( ${#display_path} - avail_w + 3 ))
        display_path="...${display_path:$offset}"
    fi
    
    # Set the global header_msg
    header_msg="Path: ${display_path}${filter_suffix}"
}

_get_tab_completion() {
    local current_input="$prompt_buffer"
    local prefix="" last_word=""
    
    # 1. Split command into prefix (cd ) and the word being completed (dir/foo)
    case "$current_input" in *" "*)
        prefix="${current_input% *} "
        last_word="${current_input##* }" ;;
    *)
        prefix=""
        last_word="$current_input" ;;
    esac

    # --- THE FIX FOR #3: FORCE RESET ON NEW PATH INPUT ---
    # If the user typed anything after the last completion (like a '/' or 'f')
    # and it no longer matches the cycle, we reset the index.
    if [[ -n "$last_completion_base" && "$current_input" != "$last_completion_base" ]]; then
        completion_idx=-1
    fi

    # --- RESET CYCLE ON NEW DEPTH ---
    # If the user just added a "/", reset cycling to scan the new subfolder
    case "$current_input" in */) completion_idx=-1 ;; esac

    # --- CYCLING LOGIC ---
    if [[ $completion_idx -ge 0 ]]; then
        case "$current_input" in "$last_completion_base"*) ;; *) return ;; esac
        completion_idx=$((completion_idx+1))
        [[ $completion_idx -ge $comp_match_count ]] && completion_idx=0
        
        eval "prompt_buffer=\"\${prefix}\${comp_match_$completion_idx}\""
        prompt_pos=${#prompt_buffer}
        last_completion_base="$prompt_buffer"
        return
    fi

    # --- PATH-AWARE SEARCH ---
    comp_match_count=0
    completion_idx=-1
    
    local dir_part="" partial=""
    case "$last_word" in *"/"*)
        dir_part="${last_word%/*}/"
        partial="${last_word##*/}" ;;
    *)
        dir_part=""
        partial="$last_word" ;;
    esac

    # Resolve scan directory
    local scan_root="$root_dir"
    [[ "${dir_part:0:1}" == "/" ]] && scan_root="" 
    local real_scan_dir=$(cd "${scan_root}/${dir_part}" 2>/dev/null && pwd)
    
    if [[ -d "$real_scan_dir" ]]; then
        ls_pattern=$(echo "$partial" | sed 's/[][\.*^$(){}|+?]/\\&/g')
        # Loop through directory contents
        for f in "$real_scan_dir"/* "$real_scan_dir"/.*; do
            [ ! -e "$f" ] && continue
            local name="${f##*/}"
            [[ "$name" == "." || "$name" == ".." ]] && continue
            # Check for hidden files: only match if partial starts with "."
            [[ "${name:0:1}" == "." && "${partial:0:1}" != "." ]] && continue
            # Check pattern match
            case "$name" in
                $partial*)
                    eval "comp_match_$comp_match_count='${dir_part}${name}'"
                    comp_match_count=$((comp_match_count+1))
                    ;;
            esac
        done
        # Sort dirs first, then files
        if [[ $comp_match_count -gt 0 ]]; then
            local sorted=""
            local tmp_sorted=""
            # Dirs first
            local si=0; while [ "$si" -lt "$comp_match_count" ]; do
                eval "val=\$comp_match_$si"
                local full_path="${real_scan_dir}/${val#${dir_part}}"
                if [[ -d "$full_path" ]]; then
                    sorted="${sorted}${val}"$'\n'
                else
                    tmp_sorted="${tmp_sorted}${val}"$'\n'
                fi
                si=$((si+1))
            done
            sorted="${sorted}${tmp_sorted}"
            # Rebuild comp_match
            comp_match_count=0
            for val in $sorted; do
                eval "comp_match_$comp_match_count='$val'"
                comp_match_count=$((comp_match_count+1))
            done
        fi
    fi

    # --- APPLY FIRST MATCH ---
    if [[ $comp_match_count -gt 0 ]]; then
        completion_idx=0
        eval "prompt_buffer=\"\${prefix}\${comp_match_0}\""
        prompt_pos=${#prompt_buffer}
        last_completion_base="$prompt_buffer"
    else
        printf "\a" >&2
    fi
}

filemanager() {
    local show_help=0
    local show_details=0
    local cmd_hist_count=0
    local hist_ptr=-1
    # Load persistent command history
    if [ -f "$hist_file" ]; then
        while IFS= read -r line; do
            [ -n "$line" ] && eval "cmd_hist_${cmd_hist_count}='$line'" && cmd_hist_count=$((cmd_hist_count+1))
        done < "$hist_file"
    fi
    local comp_match_count=0
    local completion_idx=-1
    local last_completion_base=""
    local show_ignored=0  # 0 = hide, 1 = show
    local show_hidden=0   # 0 = hide, 1 = show

    local hist_file="/tmp/tui_fm_history.txt"
    local help_file="/tmp/tui_help_$$.txt"
    cat << EOF > "$help_file"
[Arrows]  Navigate (and [w/a/s/d])
[ENTER]   Open / Select
[TAB]     Toggle selection (sel/{})
[.]       Toggle hidden files
[,]       Toggle detailed list
[i]       Toggle ignored (.gitignore)
[/]       Search filter
[:/!]     Shell prompt (! for root)
[sel/{}]  Current selection in prompt
[e]       Edit file in \$EDITOR
[f/F]     New file (f) or folder (F)
[r]       Rename item
[x/c/v]   Cut/copy/paste
[h/j/k/l] Left/down/up/right (vim)
[J/K/g/G] PageDown/PageUp/top/bottom
[q/ESC]   Exit / Cancel
EOF

    # Ensure the file is removed when the widget exits
    trap "rm -f '$help_file'; cleanup" 0

    # 1. SETUP & STATE
    local title=$1 root_dir=${2:-.}
    local cur=${3:-0} top=0 menu_w=30 
    local preview_x=$(( menu_w + 8 )) 
    local preview_offset=0
    local last_cur=-1 last_dir="INIT" rebuild=1
    local prompt_pos=0

    # Mode State: NAV (default), CMD (!), SEARCH (/), RENAME (r), NEW_F (f), NEW_D (d)
    local ui_mode="NAV"
    local prompt_buffer=""
    local clipboard_count=0
    local clipboard_op="" # "CUT" or "COPY"
    local search_query=""
    local sel_path_count=0
    local _saved_cur=0 _saved_top=0
    
    local dir_col="\e[1;34m" hid_col="\e[2m" exe_col="\e[1;32m"
    root_dir=$(cd "$root_dir" && pwd)

    while true; do
        # 2. DATA REBUILD
        if [[ "$root_dir" != "$last_dir" || $rebuild -eq 1 ]]; then
            raw_count=0; detail_count=0
            local l_query=$(_tolower "$search_query")

            # --- THE FINAL SURGICAL FIX: IGNORE CACHE ---
            local ignored_cache="|"
            if [[ $show_ignored -eq 0 ]]; then
                if type git >/dev/null 2>&1; then
                    # We use 'ls -A1' to get EVERYTHING (hidden and visible)
                    # and pipe it into 'git check-ignore --stdin'
                    # This is the most accurate way to ask Git: "Of these files, what is ignored?"
                    local raw_ignored
                    raw_ignored=$(cd "$root_dir" && ls -A1 2>/dev/null | git check-ignore --stdin 2>/dev/null)
                    
                    if [[ -n "$raw_ignored" ]]; then
                        # Safe conversion to pipe-delimited string
                        local old_ifs="$IFS"; IFS=$'\n'
                        for line in $raw_ignored; do
                            # Strip any trailing slashes Git might add to directories
                            local clean_name="${line%/}"
                            ignored_cache="${ignored_cache}${clean_name}|"
                        done
                        IFS="$old_ifs"
                    fi
                fi
            fi

            # --- PRO MOVE: Fetch all metadata in ONE fork ---
            if [[ $show_details -eq 1 ]]; then
                local meta_tmp="/tmp/tui_meta_$$.txt"
                find "$root_dir" -maxdepth 1 -mindepth 1 -exec ls -lAnhd {} + 2>/dev/null > "$meta_tmp"
                while read -r v1 v2 v3 v4 v5 v6 v7 v8 name; do
                    [[ "$v1" == "total" || -z "$name" ]] && continue
                    [[ ${#v1} -eq 10 ]] && v1="${v1} "
                    [[ ${#v6} -eq 1 ]] && v6=" $v6"
                    local clean_name="${name##*/}"
                    [[ "$clean_name" == "." || "$clean_name" == ".." ]] && continue
                    local safe_name="${clean_name//[^a-zA-Z0-9_]/_}"
                    local v3_pad=$(printf "%5s" "$v3")
                    local v4_pad=$(printf "%5s" "$v4")
                    local v5_pad=$(printf "%5s" "$v5")
                    local v6_pad=$(printf "%-3s" "$v6")
                    local v7_pad=$(printf "%2s" "$v7")
                    local v8_pad=$(printf "%5s" "$v8")
                    eval "META_F_${safe_name}=\"\$v1 \$v3_pad \$v4_pad \$v5_pad \$v6_pad \$v7_pad \$v8_pad\""
                done < "$meta_tmp"
                rm -f "$meta_tmp"
            fi
            # 1. Add Parent Dir
            if [[ "$root_dir" != "/" ]]; then
                raw_0="${root_dir%/*}|..|true"
                raw_count=1
            else
                raw_count=0
            fi

            # 2. List all entries with one find call (avoids ARG_MAX from shell glob)
            local _fm_tmpf=$(mktemp /tmp/tui_fm.XXXXXX)
            find "$root_dir" -maxdepth 1 -mindepth 1 | sort > "$_fm_tmpf"

            # Visible directories
            while IFS= read -r _entry; do
                [ ! -d "$_entry" ] && continue
                local name="${_entry##*/}"
                case "$name" in .*) continue ;; esac

                if [[ $show_ignored -eq 0 && ${#ignored_cache} -gt 1 ]]; then
                    case "$ignored_cache" in *"|$name|"*) continue ;; esac
                fi

if [[ -n "$search_query" ]]; then
                        local l_name=$(_tolower "$name")
                        case "$l_name" in *"$l_query"*) ;; *) continue ;; esac
                    fi

                    eval "raw_$raw_count='$_entry|$name|true'"
                    eval "raw_lc_$raw_count='$(_tolower "$name")'"
                    raw_count=$((raw_count+1))

                    if [[ $show_details -eq 1 ]]; then
                        local safe_lookup="${name//[^a-zA-Z0-9_]/_}"
                        local varname="META_F_$safe_lookup"
                        eval "detail_$((raw_count-1))=\${$varname}"
                    fi
                done < "$_fm_tmpf"

            # Hidden directories
            if [[ $show_hidden -eq 1 ]]; then
                while IFS= read -r _entry; do
                    [ ! -d "$_entry" ] && continue
                    local name="${_entry##*/}"
                    [[ "$name" == "." || "$name" == ".." ]] && continue
                    case "$name" in .*) ;; *) continue ;; esac

                    if [[ $show_ignored -eq 0 && ${#ignored_cache} -gt 1 ]]; then
                        case "$ignored_cache" in *"|$name|"*) continue ;; esac
                    fi

                    if [[ -n "$search_query" ]]; then
                        local l_name=$(_tolower "$name")
                        case "$l_name" in *"$l_query"*) ;; *) continue ;; esac
                    fi

                    eval "raw_$raw_count='$_entry|$name|true'"
                    eval "raw_lc_$raw_count='$(_tolower "$name")'"
                    raw_count=$((raw_count+1))

                    if [[ $show_details -eq 1 ]]; then
                        local safe_lookup="${name//[^a-zA-Z0-9_]/_}"
                        local varname="META_F_$safe_lookup"
                        eval "detail_$((raw_count-1))=\${$varname}"
                    fi
                done < "$_fm_tmpf"
            fi

            # Visible files
            while IFS= read -r _entry; do
                [ ! -f "$_entry" ] && continue
                local name="${_entry##*/}"
                case "$name" in .*) continue ;; esac

                if [[ $show_ignored -eq 0 && ${#ignored_cache} -gt 1 ]]; then
                    case "$ignored_cache" in *"|$name|"*) continue ;; esac
                fi

                if [[ -n "$search_query" ]]; then
                    local l_name=$(_tolower "$name")
                    case "$l_name" in *"$l_query"*) ;; *) continue ;; esac
                fi

                eval "raw_$raw_count='$_entry|$name|false'"
                eval "raw_lc_$raw_count='$(_tolower "$name")'"
                raw_count=$((raw_count+1))

                if [[ $show_details -eq 1 ]]; then
                    local safe_lookup="${name//[^a-zA-Z0-9_]/_}"
                    local varname="META_F_$safe_lookup"
                    eval "detail_$((raw_count-1))=\${$varname}"
                fi
            done < "$_fm_tmpf"

            # Hidden files
            if [[ $show_hidden -eq 1 ]]; then
                while IFS= read -r _entry; do
                    [ ! -f "$_entry" ] && continue
                    local name="${_entry##*/}"
                    [[ "$name" == "." || "$name" == ".." ]] && continue
                    case "$name" in .*) ;; *) continue ;; esac

                    if [[ $show_ignored -eq 0 && ${#ignored_cache} -gt 1 ]]; then
                        case "$ignored_cache" in *"|$name|"*) continue ;; esac
                    fi

                    if [[ -n "$search_query" ]]; then
                        local l_name=$(_tolower "$name")
                        case "$l_name" in *"$l_query"*) ;; *) continue ;; esac
                    fi

                    eval "raw_$raw_count='$_entry|$name|false'"
                    eval "raw_lc_$raw_count='$(_tolower "$name")'"
                    raw_count=$((raw_count+1))

                    if [[ $show_details -eq 1 ]]; then
                        local safe_lookup="${name//[^a-zA-Z0-9_]/_}"
                        local varname="META_F_$safe_lookup"
                        eval "detail_$((raw_count-1))=\${$varname}"
                    fi
                done < "$_fm_tmpf"
            fi

            rm -f "$_fm_tmpf"

            if [[ $show_details -eq 1 ]]; then :; fi
            
            master_raw_count=$raw_count
            local si=0; while [ "$si" -lt "$raw_count" ]; do
                eval "master_raw_$si=\$raw_$si"
                si=$((si+1))
            done

            if [[ -n "$search_query" ]]; then
                _refresh_sidebar_only
            fi

            if [[ $cur -eq -2 ]]; then
                cur=0
                local idx=0; while [ "$idx" -lt "$raw_count" ]; do
                    eval "val=\$raw_$idx"
                    if [[ "${val%%|*}" == "$last_path" ]]; then
                        cur=$idx
                        break
                    fi
                    idx=$((idx+1))
                done
            elif [[ -n "$search_query" ]]; then
                cur=0
            fi
            [[ $cur -ge $raw_count ]] && cur=$((raw_count - 1))
            [[ $cur -lt 0 ]] && cur=0

            _update_display_path
            
            last_dir="$root_dir"; rebuild=0; 
            
            _init_tui # This clears the screen
            
            # NOW: Explicitly draw the header with the msg we just updated
            _draw_header "$title" "$header_msg"
        fi

        # Construct the final header string
        local header_msg="Path: ${display_path}${filter_suffix}"

        case "$ui_mode" in
            "CMD"|"SUDO_CMD")
                local sym="$ "; [[ "$ui_mode" == "SUDO_CMD" ]] && sym="# "
                local fill_w=$CONTENT_WIDTH_WIDE
                header_msg=$(printf "${BG_INPUT_ESC}\e[1;37m%-${fill_w}s${RESET}${BG_MAIN_ESC}" "${sym}${prompt_buffer}")
                ;;
            "SEARCH"|"RENAME"|"NEW_F"|"NEW_D")
                local sym="Search: > "; [[ "$ui_mode" == "RENAME" ]] && sym="Rename: "
                [[ "$ui_mode" == "NEW_F" ]] && sym="File name: "; [[ "$ui_mode" == "NEW_D" ]] && sym="Dir name: "
                local fill_w=$(( CONTENT_WIDTH_WIDE - ${#sym} ))
                header_msg=$(printf "${sym}${BG_INPUT_ESC}\e[1;37m%-${fill_w}s${RESET}${BG_MAIN_ESC}" "$prompt_buffer")
                ;;
            "SUDO_PASS") 
                local masked="${prompt_buffer//?/*}"
                header_msg="${FG_INPUT_ROOT}Password: > ${masked}${RESET}" ;;
        esac

        if [[ "$ui_mode" == "NAV" ]]; then
            _draw_header "$title" "Path: $display_path"
        else
            # 1. Manually draw ONLY the Title line (Row 1)
            #local title_row=$(( PADDING_TOP + 2 ))
            #_draw_header "$title" "" 
            # 2. Let the surgical redraw handle the Prompt line (Row 3)
            _refresh_prompt
        fi

        # Position physical cursor for the prompt
        if [[ "$ui_mode" != "NAV" ]]; then
            # Header row is PADDING_TOP + _get_start_row
            local prompt_row=$(( PADDING_TOP + $(_get_start_row) + 1))
            if [[ "$TUI_MODE" == "fullscreen" && "$BACKTITLE" != "" ]];then
                prompt_row=$(( PADDING_TOP + $(_get_start_row) + 2))
            fi
            # Calculate offset: "Path: " or "$ " length
            local offset=4 
            [[ "$ui_mode" == "CMD" || "$ui_mode" == "SUDO_CMD" ]] && offset=2
            # Hacky fix for modes with no padding outside the BG_MAIN box
            local cursor_marker_shift=0
            [[ "$TUI_MODE" == "fullscreen" ]] && cursor_marker_shift=1
            printf "\e[${prompt_row};$(( PADDING_LEFT + offset + prompt_pos + cursor_marker_shift ))H" >&2
            _show_cursor
        fi

        # 4. SIDEBAR RENDER
        local list_top=$row
        
        # --- FIX 1: SIDEBAR WIDTH LOGIC ---
        # Only widen if details are ON AND help is OFF.
        local active_menu_w=$menu_w
        if [[ $show_details -eq 1 && $show_help -eq 0 ]]; then
            active_menu_w=$CONTENT_WIDTH
        fi

        # --- NEW: Dynamic Filename Column Width ---
        local active_name_w=$(( active_menu_w - 43 ))
        [ $active_name_w -lt 8 ] && active_name_w=8
        [ $active_name_w -gt 50 ] && active_name_w=50

        local _fh=$FOOTER_HEIGHT; [ "${TUI_HIDE_FOOTER:-false}" = "true" ] && _fh=0
        local height=$(( MAX_HEIGHT - list_top - _fh ))
        [[ $cur -lt $top ]] && top=$cur
        [[ $cur -ge $((top + height)) ]] && top=$((cur - height + 1))

        i=0; while [ "$i" -lt "$height" ]; do
            local v_idx=$((top + i))
            local current_row=$((list_top + i))
            _draw_at "$current_row"
            printf "$INDENT" >&2 

            # --- FIX 2: FULL-SCREEN HELP SAFETY ---
            if [[ $show_help -eq 1 && $show_details -eq 1 ]]; then
                :
            elif [[ $v_idx -lt $raw_count ]]; then
                eval "node=\$raw_$v_idx"
                local path="${node%%|*}"
                local remain="${node#*|}"
                local label="${remain%|*}"
                local is_dir="${remain##*|}"
                local is_cur=0; [[ $v_idx -eq $cur ]] && is_cur=1
                
                # --- FIX 3: PATH-BASED TAGGING ---
                local is_tag=0
                local si=0; while [ "$si" -lt "$sel_path_count" ]; do
                    eval "s_path=\$selpath_$si"
                    [[ "$s_path" == "$path" ]] && is_tag=1 && break
                    si=$((si+1))
                done

                local display_name="$label"
                if [[ $show_details -eq 1 ]]; then
                    if [[ "$label" == ".." ]]; then
                        display_name=".."
                    else
                        local lbl="$label"
                        [[ "$is_dir" == "true" ]] && lbl="${label}/"
                        
                        local short_name="${lbl:0:$active_name_w}"
                        eval "detail=\$detail_$v_idx"
                        display_name=$(printf "%-${active_name_w}s %s" "$short_name" "$detail")
                     fi
                else
                    [[ "$is_dir" == "true" && "$label" != ".." ]] && display_name="${label}/"
                fi

                local visible_name="${display_name:0:$active_menu_w}"

                local style="" color=""
                
                if [[ $is_cur -eq 1 ]]; then
                    style="$HL_WHITE_BOLD"
                    color="" 
                elif [[ $is_tag -eq 1 ]]; then
                    style="${BG_WID_ESC}"
                    color="\e[1;33m"
                else
                    style="${BG_WID_ESC}"
                    if [[ "$is_dir" == "true" ]]; then
                        color="\e[1;34m"
                    elif [[ -x "$path" ]]; then
                        color="\e[1;32m"
                    elif _match "$label" ".*"; then
                color="${FG_TEXT_ESC}\e[2m"
                    else
                        color="$FG_TEXT_ESC"
                    fi
                fi

                local is_in_clipboard=0
                local ci=0; while [ "$ci" -lt "$clipboard_count" ]; do
                    eval "cb_item=\$clipboard_$ci"
                    [[ "$cb_item" == "$path" ]] && is_in_clipboard=1 && break
                    ci=$((ci+1))
                done

                local extra_style=""
                [[ $is_in_clipboard -eq 1 ]] && extra_style="\e[3;2m" 

                local final_color="$color"
                [[ $is_in_clipboard -eq 1 ]] && final_color="" 

                printf "${style}${extra_style}${color} %-${active_menu_w}s ${RESET}${BG_MAIN_ESC}" "${display_name:0:$active_menu_w}" >&2
            else
                printf "%$((active_menu_w + 2))s" "" >&2
            fi
            _draw_line "" "$current_row"
            i=$((i+1))
        done

        # 5. PREVIEW OR HELP
        if [[ $show_help -eq 1 ]]; then
            # --- THE FLICKER PREVENTION FIX ---
            # Only run the wipe and preview if we haven't locked the help screen yet
            if [[ $last_cur -ne -3 ]]; then
                # 1. DYNAMIC WIPE
                local wipe_x=$preview_x
                local total_wipe_w=$(( MAX_WIDTH - preview_x - 1 ))
                
                if [[ $show_details -eq 1 ]]; then
                    wipe_x=2
                    total_wipe_w=$CONTENT_WIDTH_WIDE
                fi

                # 2. THE CLEAN SLATE
                local h_row=$list_top
                while [[ $h_row -lt $((list_top + height)) ]]; do
                    _draw_at "$h_row" "$wipe_x"
                    printf "%${total_wipe_w}s" "" >&2
                    h_row=$((h_row+1))
                done

                # 3. DRAW HELP
                local help_x=$preview_x
                [[ $show_details -eq 1 ]] && help_x=5
                preview "$help_file" "$list_top" "$height" "$help_x" 0

                # LOCK STATE: Set to -3 so navigation doesn't trigger a re-draw
                last_cur=-3
            fi
        elif [[ $show_details -eq 0 && "$ui_mode" == "NAV" ]]; then
            # Standard preview only runs if help is OFF
            if [[ $cur -ne $last_cur ]]; then
                eval "node=\$raw_$cur"
                local p="${node%%|*}"

                local preview_file="/tmp/tui_pv_$$.txt"

                if [[ "${node##*|}" == "false" ]]; then
                    preview "$p" "$list_top" "$height" "$preview_x" "$preview_offset"
                else
                    { ls -1Ap "$p" | grep '/$'; ls -1Ap "$p" | grep -v '/$'; } 2>/dev/null | head -"$height" > "$preview_file"
                    preview "$preview_file" "$list_top" "$height" "$preview_x" 0
                fi
                last_cur=$cur
            fi
        fi

        row=$((list_top + height))
        if [ "$_fh" -ne 0 ]; then
            _draw_spacer
            _draw_controls " ${SB}~${SR} Home | ${SB}Tab${SR} Mark | ${SB}x${SR}/${SB}c${SR}/${SB}v${SR} Cut/Copy/Paste | ${SB}r${SR} Rename | ${SB}q${SR} Quit | ${SB}?${SR} Help"
        fi
        _draw_footer
        _hide_cursor

        # IF in a prompt mode, MOVE cursor back to the prompt line
        if [[ "$ui_mode" != "NAV" ]]; then
            _refresh_prompt # Re-draws the colored input bar
            
            # Re-calculate position
            local p_row=$(( PADDING_TOP + $(_get_start_row) ))
            if [[ "$TUI_MODE" == "fullscreen" && "$BACKTITLE" != "" ]];then
                p_row=$(( PADDING_TOP + $(_get_start_row) + 1))
            fi
            local sym_len=2
            case "$ui_mode" in
                "CMD"|"SUDO_CMD") sym_len=3 ;;
                "SEARCH")         sym_len=11 ;;
                "RENAME")         sym_len=9 ;;
                "NEW_F")          sym_len=12 ;;
                "NEW_D")          sym_len=11 ;;
            esac
            # Hacky fix for modes with no padding outside the BG_MAIN box
            local cursor_marker_shift=0
            [[ "$TUI_MODE" == "fullscreen" ]] && cursor_marker_shift=1
            # Position cursor EXACTLY where the user is typing
            printf "\e[${p_row};$(( PADDING_LEFT + 2 + sym_len + prompt_pos + cursor_marker_shift))H" >&2
            _show_cursor
        fi

        # --- SELECTION HANDLER ---
        # Returns: 0 = Continue Loop, 2 = Exit Success (File/Marked Selected)
        _handle_selection() {
            eval "node=\$raw_$cur"
            local p="${node%%|*}"
            local is_d="${node##*|}"

            if [[ "$is_d" == "true" ]]; then
                root_dir=$(cd "$p" && pwd); cur=0; rebuild=1; _init_tui
                [ -n "$TUI_CD_FILE" ] && echo "cd \"$root_dir\"" > "$TUI_CD_FILE"
                return 0
            fi

            local results=""
            local si=0; while [ "$si" -lt "$sel_path_count" ]; do
                eval "sp_val=\$selpath_$si"
                [[ -n "$sp_val" ]] && results="${results}${sp_val}"$'\n'
                si=$((si+1))
            done

            if [[ -n "$results" ]]; then
                TUI_RESULT="$results"
                printf "%b" "$results"
                return 2
            fi

            TUI_RESULT="$p"
            echo "$p"
            return 2
        }

        # 6. INPUT HANDLING
        _read_key key || { TUI_RESULT=''; break; }
        _handle_extra_keys "$key" && continue

        # --- A. Escape Sequence Handler (Arrows / ESC) ---
        case "$key" in
            $'\033')
        local next_chars; _read_str_timeout 2 next_chars
            
            if [[ -z "$next_chars" ]]; then
                if [[ "$ui_mode" == "SEARCH" ]]; then
                    cur=$_saved_cur; top=$_saved_top
                    search_query=""; prompt_pos=0; ui_mode="NAV"
                    rebuild=1; _init_tui
                elif [[ "$ui_mode" != "NAV" ]]; then
                    # Handle other modes (CMD, RENAME, etc)
                    cur=$_saved_cur; top=$_saved_top
                    ui_mode="NAV"; prompt_buffer=""; prompt_pos=0; rebuild=1
                else 
                    TUI_RESULT=''; return 1 # Exit filemanager if already in NAV mode
                fi
            else
                case "$next_chars" in
                    "[D"|"OD") # Left Arrow
                        preview_offset=0
                        if [[ "$ui_mode" != "NAV" ]]; then
                            [ "$prompt_pos" -gt 0 ] && prompt_pos=$((prompt_pos-1))
                        else
                            # NAV MODE: Back to parent
                            last_path="$root_dir"; root_dir=$(cd "$root_dir/.." && pwd); rebuild=1; cur=-2
                        fi ;;
                    "[C"|"OC") # Right Arrow
                        preview_offset=0
                        if [[ "$ui_mode" != "NAV" ]]; then
                            local buf="$prompt_buffer"; [[ "$ui_mode" == "SEARCH" ]] && buf="$search_query"
                            [ "$prompt_pos" -lt "${#buf}" ] && prompt_pos=$((prompt_pos+1))
                        else
                            _handle_selection; [[ $? -eq 2 ]] && return 0
                        fi ;;
                    "[3") # DELETE key (3-char seq: \033[3~)
                        _read_str_timeout 1 _del_c
                        if [ "$_del_c" = "~" ] && [ "$ui_mode" != "NAV" ]; then
                            local _buf="$prompt_buffer"; [ "$ui_mode" = "SEARCH" ] && _buf="$search_query"
                            if [ "$prompt_pos" -lt "${#_buf}" ]; then
                                if [ "$ui_mode" = "SEARCH" ]; then
                                    search_query="${_buf:0:prompt_pos}${_buf:$((prompt_pos+1))}"
                                else
                                    prompt_buffer="${_buf:0:prompt_pos}${_buf:$((prompt_pos+1))}"
                                fi
                                _refresh_prompt
                            fi
                        fi ;;
                    "[A"|"[B"|"OA"|"OB") # Up/Down
                        preview_offset=0
                        if [[ "$ui_mode" == "CMD" || "$ui_mode" == "SUDO_CMD" ]]; then
                            if [[ "$next_chars" == "[A" || "$next_chars" == "OA" ]]; then # UP (Older)
                                if [[ $hist_ptr -lt $((cmd_hist_count - 1)) ]]; then
                                    hist_ptr=$((hist_ptr+1))
                                    eval "prompt_buffer=\$cmd_hist_$hist_ptr"
                                    prompt_pos=${#prompt_buffer}
                                fi
                            else # DOWN (Newer)
                                if [[ $hist_ptr -gt 0 ]]; then
                                    hist_ptr=$((hist_ptr-1))
                                    eval "prompt_buffer=\$cmd_hist_$hist_ptr"
                                    prompt_pos=${#prompt_buffer}
                                elif [[ $hist_ptr -eq 0 ]]; then
                                    hist_ptr=-1
                                    prompt_buffer=""
                                    prompt_pos=0
                                fi
                            fi
                            # Use your surgical redraw to show the recalled command
                            _refresh_prompt
                            continue
                        fi

                        if [[ "$ui_mode" == "NAV" ]]; then
                            [[ "$next_chars" == "[A" || "$next_chars" == "OA" ]] && { [[ $cur -gt 0 ]] && cur=$((cur-1)); }
                            [[ "$next_chars" == "[B" || "$next_chars" == "OB" ]] && { [[ $cur -lt $((raw_count-1)) ]] && cur=$((cur+1)); }
                        fi ;;
                    "[5"|"[5~")
                        if [[ "$ui_mode" == "NAV" ]]; then
                            cur=$((cur - height)); [ "$cur" -lt 0 ] && cur=0
                            preview_offset=0
                        fi
                        case "$next_chars" in "[5"|"[6") _read_str_timeout 1 _ ;; esac ;;
                    "[6"|"[6~")
                        if [[ "$ui_mode" == "NAV" ]]; then
                            cur=$((cur + height)); [ "$cur" -ge "$raw_count" ] && cur=$((raw_count - 1))
                            preview_offset=0
                        fi
                        case "$next_chars" in "[5"|"[6") _read_str_timeout 1 _ ;; esac ;;
                    "[H")
                        if [[ "$ui_mode" == "NAV" ]]; then cur=0; preview_offset=0; fi ;;
                    "[F")
                        if [[ "$ui_mode" == "NAV" ]]; then cur=$((raw_count - 1)); preview_offset=0; fi ;;
                esac
            fi
            continue
            ;;
        esac

        # --- B. PROMPT MODE (Search/Cmd/Sudo/Rename/New) ---
        if [[ "$ui_mode" != "NAV" ]]; then
            case "$key" in
                "") # ENTER in SEARCH mode
                    if [[ "$ui_mode" == "SEARCH" ]]; then
                        # --- THE SURGICAL FIX: Check if query is empty ---
                        # We strip the leading space if it exists
                        local check_q="${search_query# }"
                        
                        if [[ -z "$check_q" ]]; then
                            # EMPTY PROMPT: Behave exactly like ESCAPE
                            cur=$_saved_cur; top=$_saved_top
                            search_query=""; prompt_pos=0; ui_mode="NAV"
                            rebuild=1
                            _init_tui
                            continue
                        else
                            # NON-EMPTY: Standard confirm filter logic
                            ui_mode="NAV"
                            _update_display_path
                            local p_row=$(( PADDING_TOP + 3 ))

                            # adjustments needed to prompt placement in fullscreen mode
                            [[ -n "$BACKTITLE" && "$TUI_MODE" == 'fullscreen' ]] && p_row=$(( PADDING_TOP + 4 ))
                            
                            rebuild=1
                            continue
                        fi
                    
                    elif [[ -z "$prompt_buffer" ]]; then
                        # Empty prompt: return to NAV
                        cur=$_saved_cur; top=$_saved_top
                        ui_mode="NAV"; prompt_pos=0; rebuild=1
                        continue
                    
                    elif [[ "$ui_mode" == "CMD" || "$ui_mode" == "SUDO_CMD" ]]; then
                        # --- SAVE TO HISTORY ---
                        if [[ -n "$prompt_buffer" ]]; then
                            # Add to start of history (most recent first)
                            local hi=$cmd_hist_count; while [ "$hi" -gt 0 ]; do
                                hi2=$((hi-1))
                                eval "cmd_hist_$hi=\$cmd_hist_$hi2"
                                hi=$hi2
                            done
                            eval "cmd_hist_0='$prompt_buffer'"
                            cmd_hist_count=$((cmd_hist_count+1))
                            # Limit history size to 50 items
                            [[ $cmd_hist_count -gt 50 ]] && cmd_hist_count=50
                            # Save to persistent history file
                            : > "$hist_file"
                            local hi=0; while [ "$hi" -lt "$cmd_hist_count" ]; do
                                eval "echo \"\$cmd_hist_$hi\"" >> "$hist_file"
                                hi=$((hi+1))
                            done
                        fi
                        _execute_mode_action
                        cur=$_saved_cur; top=$_saved_top
                        prompt_buffer=""; prompt_pos=0; hist_ptr=-1 # Reset pointer
                        _init_tui
                        continue 
                    
                    elif [[ "$ui_mode" == "NEW_F" || "$ui_mode" == "NEW_D" || "$ui_mode" == "RENAME" ]]; then
                        # 1. RUN ACTION (mv, touch, or mkdir)
                        _execute_mode_action
                        
                        # 2. RESET STATE (Don't exit the script!)
                        cur=$_saved_cur; top=$_saved_top
                        ui_mode="NAV"
                        prompt_buffer=""
                        prompt_pos=0
                        
                        # 3. REBUILD LIST
                        # This ensures the new file/folder shows up in the sidebar
                        rebuild=1
                        _init_tui
                        
                        # 4. SKIP NAV LOGIC
                        continue
                    fi
                    ;;
                $'\t') # TAB
                    if [[ "$ui_mode" == "SEARCH" ]]; then
                        cur=$_saved_cur; top=$_saved_top
                        ui_mode="NAV"; prompt_pos=0; rebuild=1
                        continue
                    elif [[ "$ui_mode" == "CMD" || "$ui_mode" == "SUDO_CMD" ]]; then
                        if [[ -n "$prompt_buffer" ]]; then
                            # 2. NEW FEATURE: Completion (Only if there is text)
                            _get_tab_completion
                            _refresh_prompt
                            continue
                        else
                            # 3. Existing CMD Logic: Exit if empty
                            cur=$_saved_cur; top=$_saved_top
                            ui_mode="NAV"; prompt_pos=0; rebuild=1
                            continue
                        fi
                    elif [[ -z "$prompt_buffer" ]]; then
                        # 4. Fallback for other modes (RENAME, etc)
                        ui_mode="NAV"; prompt_pos=0; rebuild=1
                    fi
                    ;;

                $'\033') # Arrows
                    case "$next_chars" in
                        "[D"|"OD") [[ $prompt_pos -gt 0 ]] && prompt_pos=$((prompt_pos-1)) ;;
                        "[C"|"OC") 
                            local limit=$([[ "$ui_mode" == "SEARCH" ]] && echo ${#search_query} || echo ${#prompt_buffer})
                            [[ $prompt_pos -lt $limit ]] && prompt_pos=$((prompt_pos+1)) 
                            ;;
                    esac ;;

                $'\177'|$'\b') # Backspace
                    if [[ $prompt_pos -gt 0 ]]; then
                        if [[ "$ui_mode" == "SEARCH" ]]; then
                            search_query="${search_query:0:prompt_pos-1}${search_query:prompt_pos}"
                            prompt_pos=$((prompt_pos-1))

                            # 2. FAST SURGICAL UPDATES
                            _get_prompt_msg
                            _refresh_prompt
                            row=$(( $(_get_start_row) + 2)) 
                            if [[ "$TUI_MODE" == "fullscreen" && -n "$BACKTITLE" ]];then
                                row=$(( $(_get_start_row) + 3)) 
                            fi                            
                            list_top=$row

                            local max_vh=$(( MAX_HEIGHT - row - _fh ))
                            [[ $max_vh -lt 1 ]] && max_vh=1
                            _refresh_sidebar_only "$max_vh"
                            continue
                        else
                            prompt_buffer="${prompt_buffer:0:prompt_pos-1}${prompt_buffer:prompt_pos}"
                            prompt_pos=$((prompt_pos-1))
                            _refresh_prompt
                            continue
                        fi
                    else
                        # --- THE FIX: Close prompt if empty ---
                        cur=$_saved_cur; top=$_saved_top
                        ui_mode="NAV"
                        prompt_buffer=""
                        prompt_pos=0
                        rebuild=1
                        continue
                    fi ;;

                *) # Character Input
                    if case "$key" in [[:print:]]) true;; *) false;; esac; then
                        if [[ "$ui_mode" == "SEARCH" ]]; then
                            # 1. Update query
                            search_query="${search_query:0:prompt_pos}${key}${search_query:prompt_pos}"
                            prompt_pos=$((prompt_pos+1))

                            # 2. SURGICAL UPDATES (Do not use rebuild=1)
                            _get_prompt_msg       # Update the header string
                            _refresh_prompt       # Draw the black bar immediately
                            # --- THE FIX ---
                            # Capture the current row, move it up 2 lines, 
                            # and sync list_top so the sidebar redraws higher.
                            row=$(( $(_get_start_row) + 2)) 
                            if [[ "$TUI_MODE" == "fullscreen" && -n "$BACKTITLE" ]];then
                                row=$(( $(_get_start_row) + 3)) 
                            fi                            
                            list_top=$row

                            # This prevents the sidebar from breaking out of the box
                            # We subtract the header rows and the 2 footer/control rows
                            local max_vh=$(( MAX_HEIGHT - row - _fh ))
                            [[ $max_vh -lt 1 ]] && max_vh=1

                            # Pass the explicit height to your sidebar refresher
                            _refresh_sidebar_only "$max_vh"

                            continue # Skip Nav logic
                        else
                            prompt_buffer="${prompt_buffer:0:prompt_pos}${key}${prompt_buffer:prompt_pos}"
                            prompt_pos=$((prompt_pos+1))
                            _refresh_prompt
                            continue
                        fi
                    fi
                    completion_idx=-1 # Reset completion cycle when user types
                    ;;

            esac

            # --- SURGICAL REDRAW ---
            if [[ "$ui_mode" != "NAV" ]]; then
                _refresh_prompt
                
                if [[ "$ui_mode" == "SEARCH" ]]; then
                    # We only want to rebuild the list if the user hasn't typed 
                    # in the last few milliseconds, OR we do a shallow filter
                    # To keep it 100% lag-free, let's just refresh the prompt 
                    # and only filter the sidebar every 2nd or 3rd keystroke, 
                    # or simply accept a slightly slower filter for a faster cursor.
                    
                    row=$(( $(_get_start_row) + 2)) 
                    list_top=$row
                    # For Bash 3.2, the best balance is:
                    _refresh_sidebar_only # A function that only draws the filenames
                fi
                
                [[ "$ui_mode" != "SEARCH" ]] && continue
            fi
        fi

        # --- C. NAV MODE HOTKEYS ---
        case "$key" in
            "q") TUI_RESULT=''; return 1 ;; # Now "q" will exit correctly
            "") # ENTER key
                if [[ "$ui_mode" != "NAV" ]]; then
                    # We are in a prompt (SEARCH, CMD, etc.)
                    _execute_mode_action
                    continue
                else
                    _handle_selection; [[ $? -eq 2 ]] && return 0
                fi
                ;;
            $'\t') # TAB: Toggle Tag by Path
                eval "node=\$raw_$cur"
                local path="${node%%|*}"
                local label="${node#*|}"
                label="${label%|*}"
                
                if [[ "$label" != ".." ]]; then
                    local found=-1
                    local si=0; while [ "$si" -lt "$sel_path_count" ]; do
                        eval "sp_val=\$selpath_$si"
                        [[ "$sp_val" == "$path" ]] && found=$si && break
                        si=$((si+1))
                    done

                    if [[ $found -ge 0 ]]; then
                        local ti=$found; while [ "$ti" -lt "$((sel_path_count-1))" ]; do
                            ti2=$((ti+1))
                            eval "selpath_$ti=\$selpath_$ti2"
                            ti=$((ti+1))
                        done
                        sel_path_count=$((sel_path_count-1))
                    else
                        eval "selpath_$sel_path_count='$path'"
                        sel_path_count=$((sel_path_count+1))
                    fi
                fi
                [[ $cur -lt $((raw_count - 1)) ]] && cur=$((cur+1))
                ;;

            "e") # Instant Edit
                eval "node=\$raw_$cur"
                local p="${node%%|*}"
                [[ "${node##*|}" == "false" ]] && {
                    _show_cursor; stty sane; printf "\e[0m\e[H\e[J" >&2
                    ${EDITOR:-vi} "$p"
                    stty -echo; _init_tui; _hide_cursor; rebuild=1
                } ;;

            ",") # Toggle Detailed List View (comma)
                show_details=$(( 1 - show_details ))
                show_help=0; rebuild=1; _init_tui ;;

            "?") # Toggle Help
                show_help=$(( 1 - show_help ))
                last_cur=-1; rebuild=0 ;;

            "~") root_dir="$HOME"; rebuild=1; cur=0 ;;

            "!") _saved_cur=$cur; _saved_top=$top
                 ui_mode="SUDO_CMD"; prompt_buffer=""; prompt_pos=0; rebuild=0; show_help=0
                 _refresh_prompt; continue ;;
                  
            ":") _saved_cur=$cur; _saved_top=$top
                 ui_mode="CMD"; prompt_buffer=""; prompt_pos=0; rebuild=0; show_help=0
                 _refresh_prompt; continue ;;

            "/") _saved_cur=$cur; _saved_top=$top
                 ui_mode="SEARCH"; search_query=""; prompt_pos=0; rebuild=0; show_help=0
                 _refresh_prompt; continue ;;

            "f") _saved_cur=$cur; _saved_top=$top
                 ui_mode="NEW_F"; search_query=""; prompt_pos=0; rebuild=0; show_help=0
                 _refresh_prompt; continue ;;

            "F") _saved_cur=$cur; _saved_top=$top
                 ui_mode="NEW_D"; search_query=""; prompt_pos=0; rebuild=0; show_help=0
                 _refresh_prompt; continue ;;
            
            "r") # Rename
                 _saved_cur=$cur; _saved_top=$top
                 ui_mode="RENAME"
                 eval "node=\$raw_$cur"
                 local n="${node#*|}"
                 prompt_buffer="${n%|*}"
                 prompt_pos=${#prompt_buffer}
                 
                 # NEW: Don't wait for the loop to redraw
                 rebuild=0
                 show_help=0
                 _refresh_prompt
                 continue ;;

            "x"|"c") # Toggle Cut/Copy
                local op=$([[ "$key" == "x" ]] && echo "CUT" || echo "COPY")
                
                # Process tags or focus
                if [[ $sel_path_count -gt 0 ]]; then
                    local si=0; while [ "$si" -lt "$sel_path_count" ]; do
                        eval "sp=\$selpath_$si"
                        # Toggle in/out of clipboard
                        local found=-1
                        local ci=0; while [ "$ci" -lt "$clipboard_count" ]; do
                            eval "cb=\$clipboard_$ci"
                            [[ "$cb" == "$sp" ]] && found=$ci && break
                            ci=$((ci+1))
                        done
                        if [[ $found -ge 0 ]]; then
                            local ci2=$found; while [ "$ci2" -lt "$((clipboard_count-1))" ]; do
                                ci3=$((ci2+1))
                                eval "clipboard_$ci2=\$clipboard_$ci3"
                                ci2=$((ci2+1))
                            done
                            clipboard_count=$((clipboard_count-1))
                        else
                            eval "clipboard_$clipboard_count='$sp'"
                            clipboard_count=$((clipboard_count+1))
                            clipboard_op="$op"
                        fi
                        si=$((si+1))
                    done
                    sel_path_count=0
                else
                    eval "node=\$raw_$cur"
                    local p="${node%%|*}"
                    local found=-1
                    local ci=0; while [ "$ci" -lt "$clipboard_count" ]; do
                        eval "cb=\$clipboard_$ci"
                        [[ "$cb" == "$p" ]] && found=$ci && break
                        ci=$((ci+1))
                    done
                    if [[ $found -ge 0 ]]; then
                        local ci2=$found; while [ "$ci2" -lt "$((clipboard_count-1))" ]; do
                            ci3=$((ci2+1))
                            eval "clipboard_$ci2=\$clipboard_$ci3"
                            ci2=$((ci2+1))
                        done
                        clipboard_count=$((clipboard_count-1))
                    else
                        eval "clipboard_$clipboard_count='$p'"
                        clipboard_count=$((clipboard_count+1))
                        clipboard_op="$op"
                    fi
                    [[ $cur -lt $((raw_count - 1)) ]] && cur=$((cur+1))
                fi
                ;;

            "v") # Paste
                [[ $clipboard_count -eq 0 ]] && continue
                local ci=0; while [ "$ci" -lt "$clipboard_count" ]; do
                    eval "item=\$clipboard_$ci"
                    [[ ! -e "$item" ]] && continue
                    local name="${item##*/}"; local target="$root_dir/$name"
                    if [[ -e "$target" ]]; then
                        local base="${name%.*}"; local ext="${name##*.}"
                        [[ "$base" == "$ext" ]] && ext="" || ext=".$ext"
                        local j=1
                        while [[ -e "$root_dir/${base}_${j}${ext}" ]]; do j=$((j+1)); done
                        target="$root_dir/${base}_${j}${ext}"
                    fi
                    [[ "$clipboard_op" == "CUT" ]] && mv -f "$item" "$target" || cp -rf "$item" "$target"
                    ci=$((ci+1))
                done
                [[ "$clipboard_op" == "CUT" ]] && clipboard_count=0
                rebuild=1; _init_tui ;;

            "h"|"a") # Move Left (Back to parent)
                if [[ "$root_dir" != "/" ]]; then
                    last_path="$root_dir"
                    root_dir=$(cd "$root_dir/.." && pwd)
                    rebuild=1; cur=-2
                fi ;;
            "j"|"s") # Move Down
                [[ $cur -lt $((raw_count - 1)) ]] && cur=$((cur+1))
                rebuild=0; continue ;;

            "k"|"w") # Move Up
                [[ $cur -gt 0 ]] && cur=$((cur-1))
                rebuild=0; continue ;;

            "l"|"d") # Move Right (Enter directory or select file)
                _handle_selection; [[ $? -eq 2 ]] && return 0 ;;

            "g") # HOME: Jump to top
                cur=0; rebuild=0; continue ;;

            "G") # END: Jump to bottom
                cur=$((raw_count - 1)); rebuild=0; continue ;;

            "J") # PAGE DOWN: Move down by half the height
                cur=$((cur + height / 2))
                [[ $cur -ge $raw_count ]] && cur=$((raw_count - 1))
                rebuild=0; continue ;;

            "K") # PAGE UP: Move up by half the height
                cur=$((cur - height / 2))
                [[ $cur -lt 0 ]] && cur=0
                rebuild=0; continue ;;

            "i") # Toggle Ignored Files
                show_ignored=$(( 1 - show_ignored ))
                last_dir="FORCE_REFRESH" 
                rebuild=1
                ;;

            "[") # Page Up (file preview)
                preview_offset=$((preview_offset - height))
                [[ $preview_offset -lt 0 ]] && preview_offset=0
                last_cur=-3
                rebuild=0; continue ;;

            "]") # Page Down (file preview)
                preview_offset=$((preview_offset + height))
                last_cur=-3
                rebuild=0; continue ;;

            '.') # Toggle Hidden
                show_hidden=$(( 1 - show_hidden ))
                show_help=0
                eval "node=\$raw_$cur"
                last_path="${node%%|*}"; cur=-2; rebuild=1 ;;
        esac
    done
}


_get_fm() {
    local key="$2" val=""
    while IFS= read -r line; do
        case "$line" in "$key:"*) val="${line#*: }"; echo "${val//\"/}"; return ;; esac
    done < "$1"
}

_set_fm() {
    local file="$1" key="$2" new_v="$3" tmp="$1.tmp"
    while IFS= read -r line; do
        case "$line" in "$key:"*) echo "$key: $new_v" ;; *) echo "$line" ;; esac
    done < "$file" > "$tmp" && mv "$tmp" "$file"
}

# Usage: _get_simple_date "yyyy-mm-dd-hh:mm:ss" "yyyy-mm-dd"
_get_simple_date() {
    local input="$1" now="$2"
    [[ -z "$input" || "$input" == "0000-00-00-00:00:00" ]] && echo "Never" && return

    local in_date="${input:0:10}"
    local now_date="${now:0:10}"

    # If it's not today, show only the date (no time)
    if [[ "$in_date" != "$now_date" ]]; then
        echo "$in_date"
        return
    fi

    # Parse hours and minutes (slicing is faster than IFS)
    local ih=${input:11:2} im=${input:14:2}
    local nh=${now:11:2}   nm=${now:14:2}

    # Strip leading zeros to prevent octal errors
    ih=${ih#0} im=${im#0} nh=${nh#0} nm=${nm#0}

    # Total minutes from start of day
    local in_total=$(( (ih * 60) + im ))
    local now_total=$(( (nh * 60) + nm ))
    local diff=$(( now_total - in_total ))

    # 1. Less than 1 hour ago -> "X mins ago"
    if [ "$diff" -lt 60 ]; then
        if [ "$diff" -lt 4 ]; then echo "just now"; else echo "${diff} mins ago"; fi
    # 2. Less than 9 hours ago -> "X hours ago"
    elif [ "$diff" -lt 540 ]; then
        echo "$(( diff / 60 )) hours ago"
    # 3. Same day but > 9 hours -> "hh:mm" (truncated seconds)
    else
        echo "${input:11:5}"
    fi
}


kanban() {
    local title=$1
    local msg=$2
    local dir="$3" config="$dir/.project-config"
    dir=$(cd "$dir" && pwd)
    config="$dir/.project-config"
    [[ ! -d "$dir" ]] && { msgbox "Error" "Project dir not found"; return 1; }

    local content="" kanban_cols_count=0
    if [[ -f "$config" ]]; then
        content=$(cat "$config")
        local old_ifs="$IFS"; IFS=','; set -- $content; IFS="$old_ifs"
        kanban_cols_count=0
        for col_name; do
            eval "kanban_cols_$kanban_cols_count='$col_name'"
            kanban_cols_count=$((kanban_cols_count+1))
        done
    fi
    if [[ $kanban_cols_count -eq 0 ]]; then
        for col_name in "Backlog" "Todo" "Doing" "Done"; do
            eval "kanban_cols_$kanban_cols_count='$col_name'"
            kanban_cols_count=$((kanban_cols_count+1))
        done
    fi

    _init_tui && _hide_cursor

    local num_cols=$kanban_cols_count
    local usable_w=$CONTENT_WIDTH_WIDE

    local pad_w=$(( col_w - 3 )) 
    local sel_c=$((${4:-1} - 1)) sel_r=$((${5:-1} - 1))
    [ "$sel_c" -lt 0 ] && sel_c=0
    [ "$sel_r" -lt 0 ] && sel_r=0
    local c=0; while [ "$c" -lt "$num_cols" ]; do
        eval "col_top_$c=0"
        c=$((c+1))
    done

    local undo_dir="$dir/.undo" redo_dir="$dir/.redo"
    local sort_mode="rank" sort_rev=false
    mkdir -p "$undo_dir" "$redo_dir"

    _save_undo() { rm -rf "$undo_dir"/*; cp "$dir"/*.md "$undo_dir/" 2>/dev/null; }
    _save_redo() { rm -rf "$redo_dir"/*; cp "$dir"/*.md "$redo_dir/" 2>/dev/null; }

    while true; do
        # --- 1. Map Files to Columns ---
        c=0; while [ "$c" -lt "$num_cols" ]; do
            eval "count_$c=0"
            c=$((c+1))
        done

        local rev_flag=""
        [[ "$sort_rev" == "true" ]] && rev_flag="r"

        # List .md files via find (avoids ARG_MAX from shell glob) and cache metadata once
        local _kb_tmpf=$(mktemp /tmp/tui_kb.XXXXXX)
        find "$dir" -maxdepth 1 -name '*.md' | sort > "$_kb_tmpf"

        # Read paths into numbered vars first (avoids stdin-consumption from $(...) subshells in while read loop)
        local _pcount=0
        while IFS= read -r _p; do
            eval "kb_path_$_pcount='$_p'"
            _pcount=$((_pcount+1))
        done < "$_kb_tmpf"
        rm -f "$_kb_tmpf"

        local _kb_idx=0
        local _kb_manifest=""
        local _pi=0; while [ "$_pi" -lt "$_pcount" ]; do
            eval "_fpath=\"\$kb_path_$_pi\""
            [ ! -f "$_fpath" ] && { _pi=$((_pi+1)); continue; }
            local _fname="${_fpath##*/}"
            local _sort_val=$(_get_fm "$_fpath" "$sort_mode")
            local _status=$(_get_fm "$_fpath" "status")
            local _title=$(_get_fm "$_fpath" "title")
            : ${_title:=${_fname%.md}}
            if [[ "$sort_mode" == "rank" ]]; then
                [[ -z "$_sort_val" ]] && _sort_val="100"
                _sv="000${_sort_val}"
                _sv="${_sv: -3}"
                _kb_manifest="${_kb_manifest}${_sv}|${_fname}"$'\n'
            else
                [[ -z "$_sort_val" ]] && _sort_val="0000-00-00-00:00:00"
                _kb_manifest="${_kb_manifest}${_sort_val}|${_fname}"$'\n'
            fi
            eval "kb_status_$_kb_idx='$_status'"
            eval "kb_title_$_kb_idx='$_title'"
            eval "kb_fname_$_kb_idx='$_fname'"
            _kb_idx=$((_kb_idx+1))
            _pi=$((_pi+1))
        done
        local _kb_total=$_kb_idx

        # Sort manifest directly to temp file (avoids $(...) subshell dropping last line)
        local _kb_mftmp=$(mktemp /tmp/tui_kbm.XXXXXX)
        printf "%s" "$_kb_manifest" > "$_kb_mftmp"
        sort -t '|' -k1$( [[ "$sort_rev" == "true" ]] && echo "r" ) -o "$_kb_mftmp" "$_kb_mftmp"

        local _entry_idx=0
        while IFS= read -r _entry; do
            [ -z "$_entry" ] && continue
            local fname="${_entry#*|}"
            local fpath="$dir/$fname"

            local f_title=""
            local f_status=""
            # look up cached metadata by filename
            local _fi=0; while [ "$_fi" -lt "$_kb_total" ]; do
                eval "_tf=\"\$kb_fname_$_fi\""
                if [[ "$_tf" == "$fname" ]]; then
                    eval "f_status=\"\$kb_status_$_fi\""
                    eval "f_title=\"\$kb_title_$_fi\""
                    break
                fi
                _fi=$((_fi+1))
            done
            : ${f_title:=${fname%.md}}

            c=0; while [ "$c" -lt "$num_cols" ]; do
                eval "kc=\$kanban_cols_$c"
                if [[ "$f_status" == "$kc" ]]; then
                    eval "idx=\$count_$c"
                    eval "files_${c}_${idx}=\"\$fname\""
                    eval "titles_${c}_${idx}=\"\$f_title\""
                    eval "count_$c=$((idx + 1))"
                    
                    if [[ -n "$target_filename" && "$fname" == "$target_filename" ]]; then
                        sel_c=$c; sel_r=$idx; target_filename=""
                    fi
                    break
                fi
                c=$((c+1))
            done
        done < "$_kb_mftmp"
        rm -f "$_kb_mftmp"

        eval "first_max=\$count_$sel_c"
        [ "$sel_c" -ge "$num_cols" ] && sel_c=0
        [ "$sel_r" -ge "${first_max:-0}" ] && sel_r=0

        row=2
        [[ $PADDING_TOP -eq 0 && -n "$BACKTITLE" ]] && row=3
        _draw_header "$title" "$msg"
        local list_top=$row
        
        local _fh=$FOOTER_HEIGHT; [ "${TUI_HIDE_FOOTER:-false}" = "true" ] && _fh=0
        local view_h=$(( MAX_HEIGHT - list_top - 1 - _fh ))
        [[ $view_h -lt $MIN_CONTENT_HEIGHT ]] && view_h=$MIN_CONTENT_HEIGHT

        # --- 2. PRE-CALCULATE DYNAMIC WIDTHS ---
        local num_cols=$kanban_cols_count
        local total_gap_space=$(( num_cols - 1 ))
        local usable_w=$(( CONTENT_WIDTH_WIDE - total_gap_space ))
        
        local base_col_w=$(( usable_w / num_cols ))
        local remainder=$(( usable_w % num_cols ))

        # --- RENDER GRID ---
        c=0; while [ "$c" -lt "$num_cols" ]; do
            local item_w=$((base_col_w - 1))
            [[ $c -eq $((num_cols - 1)) ]] && item_w=$((item_w + remainder))

            local x=2
            [[ "$TUI_MODE" == "fullscreen" ]] && x=3
            local prev=0; while [ "$prev" -lt "$c" ]; do 
                x=$((x + base_col_w + 1))
                prev=$((prev+1))
            done
            
            eval "c_len=\$count_$c"
            eval "col_top=\$col_top_$c"
            local top=$col_top

            # 1. STICKY HEADER
            local h_style="${BG_TABLE_HEADER_ESC}"
            [[ $sel_c -eq $c ]] && h_style="${BG_TABLE_HEADER_ESC}${SB}${BOLD}"
            
            eval "kc=\$kanban_cols_$c"
            _draw_at "$list_top" "$x"
            printf "${h_style}%-${item_w}.${item_w}s${RESET}${BG_MAIN_ESC}" " $kc" >&2
            
            # 2. SCROLLABLE VIEWPORT
            i=0; while [ "$i" -lt "$view_h" ]; do
                local r=$((list_top + i + 1))
                local idx=$((top + i))
                _draw_at "$r" "$x"
                
                if [[ $idx -lt $c_len ]]; then
                    local style=$([[ $sel_c -eq $c && $sel_r -eq $idx ]] && echo "${HL_WHITE_BOLD}" || echo "${BG_WID_ESC}${FG_TEXT_ESC}")
                    
                    eval "d_name=\$titles_${c}_${idx}"
                    [[ -z "$d_name" ]] && eval "d_name=\$files_${c}_${idx}"

                    if [[ ${#d_name} -gt $item_w ]]; then
                        d_name="${d_name:0:$((item_w - 3))}..."
                    fi
                    
                    printf "${style}%-${item_w}.${item_w}s${RESET}${BG_MAIN_ESC}" " $d_name" >&2
                else
                    printf "${BG_MAIN_ESC}%-${item_w}s" "" >&2
                fi
                i=$((i+1))
            done
            c=$((c+1))
        done

        if [ "$_fh" -ne 0 ]; then
            row=$CONTROLS_ROW
            _draw_footer
            local sort_dir="▲"
            [[ "$sort_rev" == "true" ]] && sort_dir="▼"
            _draw_controls " ${SB}Arrows${SR} Navigate | ${SB}WASD${SR} Move | ${SB}o${SR}/${SB}O${SR} Sort: $sort_mode $sort_dir | ${SB}z${SR}/${SB}Z${SR} Undo | ${SB}?${SR} Help"
        fi
        printf "\e[1;1H" >&2

        # 5. Input Handling
        _read_key key
        _handle_extra_keys "$key" && continue
        
        case "$key" in
            $'\033')
            local next_chars=""
            _read_str_timeout 2 next_chars
            
            if [[ -z "$next_chars" ]]; then TUI_RESULT=''; return 1; fi
            
            case "$next_chars" in
                "[A"|"OA") key="k" ;; "[B"|"OB") key="j" ;; "[C"|"OC") key="l" ;; "[D"|"OD") key="h" ;;
                "[5"|"[5~")
                    sel_r=$((sel_r - view_h)); [ "$sel_r" -lt 0 ] && sel_r=0
                    eval "col_top_$sel_c=$sel_r"
                    continue ;;
                "[6"|"[6~")
                    sel_r=$((sel_r + view_h))
                    eval "c_max=\$count_$sel_c"; c_max=$((c_max - 1)); [ "$c_max" -lt 0 ] && c_max=0
                    [ "$sel_r" -gt "$c_max" ] && sel_r=$c_max
                    eval "col_top=\$col_top_$sel_c"
                    [[ $sel_r -ge $((col_top + view_h)) ]] && eval "col_top_$sel_c=$((sel_r - view_h + 1))"
                    continue ;;
                "[H") sel_r=0; eval "col_top_$sel_c=0"; continue ;;
                "[F")
                    eval "c_len=\$count_$sel_c"
                    sel_r=$((c_len - 1)); [ "$sel_r" -lt 0 ] && sel_r=0
                    eval "col_top_$sel_c=$((sel_r - view_h + 1))"
                    continue ;;
                *) : ;;
            esac
            ;;
        esac

        local target="" cur_file=""
        if [[ "$key" != "q" ]]; then
            eval "cur_file=\$files_${sel_c}_${sel_r}"
            [[ -n "$cur_file" ]] && target="$dir/$cur_file"
        fi

        case "$key" in
            "q") TUI_RESULT=''; cleanup; return 1 ;;

            "/") 
                 local NOW_FULL=$(date +%Y-%m-%d-%H:%M:%S)

                local filter_csv="/tmp/pm_filter_$$.csv"
                local old_ifs="$IFS"; IFS=$'\n'
                
                local rev_flag=""; [[ "$sort_rev" == "true" ]] && rev_flag="r"
                local sorted_files=$(for f in "$dir"/*.md; do
                    [[ ! -f "$f" ]] && continue
                    local val
                    if [[ "$sort_mode" == "modified" ]]; then
                        val=$(date -r $(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null) +%Y-%m-%d-%H:%M:%S)
                    else
                        val=$(_get_fm "$f" "$sort_mode")
                    fi
                    
                    if [[ "$sort_mode" == "rank" ]]; then
                        printf "%03d|%s\n" "${val:-100}" "${f##*/}"
                    else
                        echo "${val:-0000-00-00-00:00:00}|${f##*/}"
                    fi
                done | sort -t '|' -k1${rev_flag})

                echo "Title,Tags,Author,Created,Modified,Due,Command" > "$filter_csv"
                
                for entry in $sorted_files; do
                    local fname="${entry#*|}"
                    local f="$dir/$fname"
                    
local r_title=$(_get_fm "$f" "title")
                    local r_tags=$(_get_fm "$f" "tags")
                    local r_auth=$(_get_fm "$f" "author")
                    local r_cre=$(_get_fm "$f" "created")
                    local r_due=$(_get_fm "$f" "due")

                    local r_mod=$(date -r $(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null) +%Y-%m-%d-%H:%M:%S)

                    local display_cre=$(_get_simple_date "$r_cre" "$NOW_FULL")
                    local display_mod=$(_get_simple_date "$r_mod" "$NOW_FULL")
                    local display_due=$(_get_simple_date "$r_due" "$NOW_FULL")

                    echo "${r_title//,/;},${r_tags//,/;},$r_auth,$display_cre,$display_mod,$display_due,$f" >> "$filter_csv"
                done
                IFS="$old_ifs"

                local chosen_file
                chosen_file=$(filtertable "Project search" "Type to filter..." "$filter_csv" 1)
                local exit_status=$?

                rm -f "$filter_csv"

                if [[ $exit_status -eq 0 && -n "$chosen_file" ]]; then
                    if [[ -f "$chosen_file" ]]; then
                        ${EDITOR:-vi} "$chosen_file"
                    fi
                fi
                
                _init_tui
                ;;

            "k"|"w") 
                if [[ $sel_r -gt 0 ]]; then
                    sel_r=$((sel_r-1))
                    eval "col_top=\$col_top_$sel_c"
                    [[ $sel_r -lt $col_top ]] && eval "col_top_$sel_c=$sel_r"
                fi ;;
            "j"|"s") 
                eval "c_len=\$count_$sel_c"
                if [[ $sel_r -lt $((c_len - 1)) ]]; then
                    sel_r=$((sel_r+1))
                    eval "col_top=\$col_top_$sel_c"
                    [[ $sel_r -ge $((col_top + view_h)) ]] && eval "col_top_$sel_c=$((sel_r - view_h + 1))"
                fi ;;

            "h"|"a") 
                local prev_c=$((sel_c - 1))
                while [[ $prev_c -ge 0 ]]; do
                    eval "c_len=\$count_$prev_c"
                    if [[ $c_len -gt 0 ]]; then
                        sel_c=$prev_c
                        eval "new_max=\$count_$sel_c"
                        [[ $sel_r -ge $new_max ]] && sel_r=$((new_max - 1))
                        [[ $sel_r -lt 0 ]] && sel_r=0
                        eval "col_top=\$col_top_$sel_c"
                        [[ $sel_r -lt $col_top ]] && eval "col_top_$sel_c=$sel_r"
                        [[ $sel_r -ge $((col_top + view_h)) ]] && eval "col_top_$sel_c=$((sel_r - view_h + 1))"
                        break
                    fi
                    prev_c=$((prev_c-1))
                done ;;

            "l"|"d") 
                local next_c=$((sel_c + 1))
                while [[ $next_c -lt $num_cols ]]; do
                    eval "c_len=\$count_$next_c"
                    if [[ $c_len -gt 0 ]]; then
                        sel_c=$next_c
                        eval "new_max=\$count_$sel_c"
                        [[ $sel_r -ge $new_max ]] && sel_r=$((new_max - 1))
                        [[ $sel_r -lt 0 ]] && sel_r=0
                        eval "col_top=\$col_top_$sel_c"
                        [[ $sel_r -lt $col_top ]] && eval "col_top_$sel_c=$sel_r"
                        [[ $sel_r -ge $((col_top + view_h)) ]] && eval "col_top_$sel_c=$((sel_r - view_h + 1))"
                        break
                    fi
                    next_c=$((next_c+1))
                done ;;
            
            "L"|"D") 
                if [[ $sel_c -lt $((num_cols-1)) && -n "$cur_file" ]]; then
                    _save_undo; local moving_file="$cur_file"
                    local target_col=$((sel_c + 1))
                    eval "target_status=\$kanban_cols_$target_col"

                    _set_fm "$target" "status" "$target_status"
                    [[ $target_col -eq $((num_cols - 1)) ]] && _set_fm "$target" "completed" "$(date +%Y-%m-%d-%H:%M:%S)"

                    sel_c=$target_col
                    c=0; while [ "$c" -lt "$num_cols" ]; do eval "count_$c=0"; c=$((c+1)); done
                    local old_ifs="$IFS"; IFS=$'\n'
                    local manifest=$(for f in "$dir"/*.md; do
                        [[ ! -f "$f" ]] && continue
                        local val
                        if [[ "$sort_mode" == "modified" ]]; then
                            val=$(date -r $(stat -f %m "$f") +%Y-%m-%d-%H:%M:%S 2>/dev/null)
                            [[ -z "$val" ]] && val=$(date -r "$f" +%Y-%m-%d-%H:%M:%S 2>/dev/null)
                        else
                            val=$(_get_fm "$f" "$sort_mode")
                        fi
                        if [[ "$sort_mode" == "rank" ]]; then
                            [[ -z "$val" ]] && val="100"
                            printf "%03d|%s\n" "$val" "${f##*/}"
                        else
                            [[ -z "$val" ]] && val="0000-00-00-00:00:00"
                            echo "${val}|${f##*/}"
                        fi
                    done | sort -t '|' -k1$( [[ "$sort_rev" == "true" ]] && echo "r" ))
                    for entry in $manifest; do
                        local fname="${entry#*|}"
                        local s=$(_get_fm "$dir/$fname" "status")
                        c=0; while [ "$c" -lt "$num_cols" ]; do
                            eval "kc=\$kanban_cols_$c"
                            if [[ "$s" == "$kc" ]]; then
                                eval "c_idx=\$count_$c"
                                eval "files_${c}_${c_idx}=\"\$fname\""
                                eval "count_$c=$((c_idx + 1))"
                                [[ "$fname" == "$moving_file" && $c -eq $sel_c ]] && sel_r=$c_idx
                            fi
                            c=$((c+1))
                        done
                    done
                    IFS="$old_ifs"
                fi ;;

            "H"|"A")
                if [[ $sel_c -gt 0 && -n "$cur_file" ]]; then
                    _save_undo; local moving_file="$cur_file"
                    local target_col=$((sel_c - 1))
                    eval "kc=\$kanban_cols_$target_col"
                    _set_fm "$target" "status" "$kc"
                    [[ $sel_c -eq $((num_cols - 1)) ]] && _set_fm "$target" "completed" ""

                    sel_c=$target_col
                    c=0; while [ "$c" -lt "$num_cols" ]; do eval "count_$c=0"; c=$((c+1)); done
                    local old_ifs="$IFS"; IFS=$'\n'
                    local manifest=$(for f in "$dir"/*.md; do
                        [[ ! -f "$f" ]] && continue
                        local val=$(_get_fm "$f" "$sort_mode")
                        printf "%03d|%s\n" "${val:-500}" "${f##*/}"
                    done | sort -t '|' -k1$( [[ "$sort_rev" == "true" ]] && echo "r" ))
                    for entry in $manifest; do
                        local fname="${entry#*|}"
                        local s=$(_get_fm "$dir/$fname" "status")
                        c=0; while [ "$c" -lt "$num_cols" ]; do
                            eval "kc=\$kanban_cols_$c"
                            if [[ "$s" == "$kc" ]]; then
                                local c_idx=$(eval "echo \$count_$c")
                                eval "files_${c}_${c_idx}=\"\$fname\""; eval "count_$c=$((c_idx + 1))"
                                [[ "$fname" == "$moving_file" && $c -eq $sel_c ]] && sel_r=$c_idx
                            fi
                            c=$((c+1))
                        done
                    done
                    IFS="$old_ifs"
                fi ;;

            "K"|"W") # MOVE UP
                if [[ -n "$cur_file" && $sel_r -gt 0 ]]; then
                    _save_undo; sort_mode="rank"; sort_rev=false
                    eval "prev_f=\$files_${sel_c}_$((sel_r - 1))"
                    local cur_p=$(_get_fm "$target" "rank"); : ${cur_p:=500}
                    local pre_p=$(_get_fm "$dir/$prev_f" "rank"); : ${pre_p:=500}

                    if [[ "$cur_p" -eq "$pre_p" ]]; then
                        pre_p=$((cur_p - 1))
                    fi

                    _set_fm "$target" "rank" "$pre_p"
                    _set_fm "$dir/$prev_f" "rank" "$cur_p"
                    sel_r=$((sel_r-1))
                    eval "col_top=\$col_top_$sel_c"
                    [[ $sel_r -lt $col_top ]] && eval "col_top_$sel_c=$sel_r"
                fi ;;

            "J"|"S") # MOVE DOWN
                eval "c_len=\$count_$sel_c"
                if [[ -n "$cur_file" && $sel_r -lt $((c_len - 1)) ]]; then
                    _save_undo; sort_mode="rank"; sort_rev=false
                    eval "next_f=\$files_${sel_c}_$((sel_r + 1))"
                    local cur_p=$(_get_fm "$target" "rank"); : ${cur_p:=500}
                    local nxt_p=$(_get_fm "$dir/$next_f" "rank"); : ${nxt_p:=500}

                    if [[ "$cur_p" -eq "$nxt_p" ]]; then
                        nxt_p=$((cur_p + 1))
                    fi

                    _set_fm "$target" "rank" "$nxt_p"
                    _set_fm "$dir/$next_f" "rank" "$cur_p"
                    sel_r=$((sel_r+1))
                    eval "col_top=\$col_top_$sel_c"
                    [[ $sel_r -ge $((col_top + view_h)) ]] && eval "col_top_$sel_c=$((sel_r - view_h + 1))"
                fi ;;

            "o") case "$sort_mode" in "rank") sort_mode="modified" ;; "modified") sort_mode="created" ;; "created") sort_mode="completed" ;; "completed") sort_mode="due" ;; *) sort_mode="rank" ;; esac ;;
            "O") [[ "$sort_rev" == "true" ]] && sort_rev="false" || sort_rev="true" ;;
            "e"|"") [[ -n "$cur_file" ]] && { ${EDITOR:-vi} "$target"; _init_tui; } ;;
            "n") 
                name=$(inputbox "New Note" "Filename (no extension):")
                name="${name//\//-}"
                if [[ -n "$name" ]]; then
                    _save_undo
                    local d=$(date +%Y-%m-%d-%H:%M:%S)
                    eval "kc=\$kanban_cols_$sel_c"
                    printf "title: %s\ncreated: %s\ncompleted: \ndue: \nstatus: %s\nrank: 0\ntags: \nauthor: %s\nowner: %s\n" \
                           "$name" "$d" "$kc" "$USER" "$USER" > "$dir/${name}.md"
                fi 
                _init_tui 
                ;;
            "t") [[ -n "$cur_file" ]] && { tag=$(inputbox "Tag" "Add tag:"); _set_fm "$target" "tags" "$(_get_fm "$target" "tags") $tag"; } ;;
            "z") _save_redo; cp "$undo_dir"/*.md "$dir/" 2>/dev/null ;;
            "Z") cp "$redo_dir"/*.md "$dir/" 2>/dev/null ;;
            "?") 
                _help_popup kanban ;;
        esac

        eval "max_r=\$count_$sel_c"
        if [ "$max_r" = "0" ] || [ -z "$max_r" ]; then 
            sel_r=0
        elif [ "$sel_r" -ge "$max_r" ]; then 
            sel_r=$((max_r - 1))
        fi
        [ "$sel_r" -lt 0 ] 2>/dev/null && sel_r=0 || true
    done
}
