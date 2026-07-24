#!/usr/bin/env sh

CONFIG_DIR="$HOME/.config/suckless"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

die() { echo -e "${RED}ERROR: $*${NC}" >&2; exit 1; }
warn() { echo -e "${YELLOW}WARNING: $*${NC}" >&2; }
msg() { echo -e "${CYAN}$*${NC}"; }


# Build suckless tools
msg "Building suckless tools..."
for tool in dwm dmenu dwmblocks-async slock st tabbed ; do
    cd "$CONFIG_DIR/src/$tool" || die "Cannot find $tool"
    rm config.h && make && sudo make install || die "Failed to build $tool"
done
