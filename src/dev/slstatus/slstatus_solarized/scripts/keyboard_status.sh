#!/usr/bin/env bash

layout=$(setxkbmap -query | grep layout | awk '{print$2}')
layout_atual="^c#2aa198^󰌌 ^c#93a1a1^$(setxkbmap -query | grep layout | awk '{print$2}')"

# Verifique o estado atual do Caps Lock
CAPS_STATE=$(xset q | grep "Caps Lock:" | awk '{print $4}')

if [ "$CAPS_STATE" == "on" ]; then
    caps="^c#2aa198^󰪛"
else
    caps=""
fi

# Verificar o estado atual do Num Lock
NUMLOCK_STATE=$(xset q | grep "Num Lock:" | awk '{print $8}')

if [ "$NUMLOCK_STATE" == "on" ]; then
    num="^c#2aa198^󰎠"
else
    num=""
fi

# Logica para visualizacao
if [[ ! -z "$caps" ]] then
   if [[ ! -z "$num" ]] then
      echo "$layout_atual $caps $num"
   else
       echo "$layout_atual $caps"
   fi
else
   if [[ ! -z "$num" ]] then
      echo "$layout_atual $num"
   else
       echo "$layout_atual"
   fi
fi
