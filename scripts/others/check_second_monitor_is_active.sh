#!/usr/bin/env bash

# Identifica os monitores do equipamento
HDMI_DEVICE=$(xrandr -q | grep "HDMI" | awk '{print $1}')
EDP_DEVICE=$(xrandr -q | grep "eDP" | awk '{print $1}')
VIRTUAL_DEVICE=$(xrandr -q | grep "Virtual" | awk '{print $1}')

# Verifica se eles estão conectados
monitor=$(xrandr | grep "$HDMI_DEVICE connected" -ci | cut -c 1-16 )
virtual1=$(xrandr | grep "$VIRTUAL_DEVICE connected" -ci | cut -c 1-16)

# Caso o HDMI esteja conectado
if [ $monitor -eq 1  ]
then
	xrandr --output $HDMI_DEVICE --auto --rotate normal --dpi 96 --rate 60 --output $EDP_DEVICE --primary --mode 1920x1080 --rotate normal --left-of $HDMI_DEVICE --dpi 96 --rate 60
else
   xrandr --output $EDP_DEVICE --primary --mode 1920x1080 --rotate normal --dpi 96 --rate 60
fi

 # Caso seja um virtual
if [ $virtual1 -eq 1 ]
then
   xrandr --output $VIRTUAL_DEVICE --primary --mode 1920x1080 --rotate normal --dpi 96 --rate 60
else
   # Apenas o monitor do laptop
   xrandr --output $EDP_DEVICE --primary --mode 1920x1080 --rotate normal --dpi 96 --rate 60
fi
