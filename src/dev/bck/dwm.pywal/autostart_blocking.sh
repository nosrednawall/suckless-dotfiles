#!/usr/bin/env bash

# para a nvidia
xrandr --setprovideroutputsource modesetting NVIDIA-0
xrandr --auto

# JAVA Bug
if which wmname; then
  wmname LG3D
fi
export AWT_TOOLKIT="MToolkit"
export _JAVA_AWT_WM_NONREPARENTING="1"
export _JAVA_OPTIONS="-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true"

# Para o virt manager
export LIBVIRT_DEFAULT_URI='qemu:///system'
