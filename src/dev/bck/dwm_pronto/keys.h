#ifndef KEYS_H_
#define KEYS_H_
/*imports*/
#include <X11/XF86keysym.h>

static const Key keys[] = {
	/* modifier                     key            function                argument */
    { MODKEY,                       XK_p,          spawn,                  {.v = dmenucmd } },
	{ MODKEY|ShiftMask,             XK_Return,     spawn,                  {.v = termcmd } },
	{ MODKEY|ShiftMask,             XK_b,          togglebar,              {0} },

    /*Modimentacao das janelas*/
	{ MODKEY,                       XK_Right,     focusstack,              {.i = +1 } },
	{ MODKEY,                       XK_Left,      focusstack,              {.i = -1 } },

    /*Adiciona e remove janelas da mastes para a lateral*/
	{ MODKEY|ShiftMask,             XK_equal,     incnmaster,              {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_minus,     incnmaster,              {.i = -1 } },

    /*Altera o tamanho das janelas horizontal*/
    { MODKEY|ShiftMask,             XK_Right,      setmfact,                {.f = +0.05} },
	{ MODKEY|ShiftMask,             XK_Left,       setmfact,                {.f = -0.05} },

    /*altera tamanho janelas na vertical*/
    { MODKEY|ShiftMask,             XK_Up,          setcfact,               {.f = +0.25} },
	{ MODKEY|ShiftMask,             XK_Down,        setcfact,               {.f = -0.25} },
	{ MODKEY|ShiftMask,             XK_o,          setcfact,               {0} },

    /*Altera tamanho da janela em modo floating, sem usar mouse*/
	{ MODKEY|ControlMask|ShiftMask, XK_e,          aspectresize,           {.i = +24} },
	{ MODKEY|ControlMask|ShiftMask, XK_r,          aspectresize,           {.i = -24} },

	{ MODKEY,                       XK_Return,    zoom,                    {0} },
	{ Mod1Mask,                     XK_Tab,        alttabstart,            {0} },

    /*Gaps*/
	{ ControlMask|Mod1Mask,              XK_1,          incrgaps,               {.i = +1 } },
	{ ControlMask|Mod1Mask|ShiftMask,    XK_1,          incrgaps,               {.i = -1 } },
	{ ControlMask|Mod1Mask,              XK_2,          incrigaps,              {.i = +1 } },
	{ ControlMask|Mod1Mask|ShiftMask,    XK_2,          incrigaps,              {.i = -1 } },
	{ ControlMask|Mod1Mask,              XK_3,          incrogaps,              {.i = +1 } },
	{ ControlMask|Mod1Mask|ShiftMask,    XK_3,          incrogaps,              {.i = -1 } },
	{ ControlMask|Mod1Mask,              XK_4,          incrihgaps,             {.i = +1 } },
	{ ControlMask|Mod1Mask|ShiftMask,    XK_4,          incrihgaps,             {.i = -1 } },
	{ ControlMask|Mod1Mask,              XK_5,          incrivgaps,             {.i = +1 } },
	{ ControlMask|Mod1Mask|ShiftMask,    XK_5,          incrivgaps,             {.i = -1 } },
	{ ControlMask|Mod1Mask,              XK_6,          incrohgaps,             {.i = +1 } },
	{ ControlMask|Mod1Mask|ShiftMask,    XK_6,          incrohgaps,             {.i = -1 } },
	{ ControlMask|Mod1Mask,              XK_7,          incrovgaps,             {.i = +1 } },
	{ ControlMask|Mod1Mask|ShiftMask,    XK_7,          incrovgaps,             {.i = -1 } },
	{ ControlMask|Mod1Mask,              XK_0,          togglegaps,             {0} },
	{ ControlMask|Mod1Mask|ShiftMask,    XK_0,          defaultgaps,            {0} },

    { MODKEY|ControlMask,           XK_z,          showhideclient,         {0} },
	{ MODKEY|ShiftMask,             XK_c,          killclient,             {0} },
	{ MODKEY|ShiftMask,             XK_q,          quit,                   {0} }, //exit dwm
	{ MODKEY|ShiftMask,             XK_r,          quit,                   {1} }, //restart dwm
    { MODKEY,                       XK_o,          winview,                {0} },

    //Layouts
	{ MODKEY,                       XK_F1,         setlayout,      {.v = &layouts[0]} },
	{ MODKEY,                       XK_F2,         setlayout,      {.v = &layouts[1]} },
	{ MODKEY,                       XK_F3,      setlayout,      {.v = &layouts[2]} },
	{ MODKEY,                       XK_F4,      setlayout,      {.v = &layouts[3]} },
	{ MODKEY,                       XK_F5,      setlayout,      {.v = &layouts[4]} },
	{ MODKEY,                       XK_F6,      setlayout,      {.v = &layouts[5]} },
	{ MODKEY,                       XK_F7,      setlayout,      {.v = &layouts[6]} },
	{ MODKEY,                       XK_F8,      setlayout,      {.v = &layouts[7]} },
	{ MODKEY,                       XK_F9,      setlayout,      {.v = &layouts[8]} },
	{ MODKEY,                       XK_F10,     setlayout,      {.v = &layouts[9]} },
	{ MODKEY,                       XK_F11,     setlayout,      {.v = &layouts[10]} },
	{ MODKEY,                       XK_F12,     setlayout,      {.v = &layouts[11]} },
	{ MODKEY|ShiftMask,             XK_F1,      setlayout,      {.v = &layouts[12]} },
	{ MODKEY|ShiftMask,             XK_F2,      setlayout,      {.v = &layouts[13]} },
    { MODKEY|ShiftMask,             XK_F3,      setlayout,      {.v = &layouts[14]} },
	{ MODKEY|ShiftMask,             XK_F4,      setlayout,      {.v = &layouts[15]} },

    /*Scratpads*/
	{ MODKEY,                       XK_s,      togglescratch,  {.ui = 0 } },
	{ MODKEY|ShiftMask,             XK_f,      togglescratch,  {.ui = 1 } },  //desabilitei para testar o fullscreen
	{ MODKEY,                       XK_b,      togglescratch,  {.ui = 2 } },
	{ MODKEY,                       XK_a,      togglescratch,  {.ui = 3 } },
	{ MODKEY|ShiftMask,             XK_h,      togglescratch,  {.ui = 4 } },
	{ MODKEY,                       XK_n,      togglescratch,  {.ui = 5 } },
	{ MODKEY,                       XK_m,      togglescratch,  {.ui = 6 } },
	{ MODKEY,                       XK_c,      togglescratch,  {.ui = 7 } },
	{ MODKEY,                       XK_y,      togglescratch,  {.ui = 8 } },
	{ MODKEY,                       XK_q,      togglescratch,  {.ui = 9 } },

	/*Floating*/
	{ MODKEY,                       XK_space,  setlayout,              {0} },
	{ MODKEY|ShiftMask,             XK_space,  togglefloating,         {0} },

    /*Mudar de monitor*/
	{ MODKEY|ControlMask,           XK_grave,      setscratch,             {.ui = 0 } },
	{ MODKEY|ShiftMask,             XK_grave,      removescratch,          {.ui = 0 } },
	{ MODKEY,                       XK_0,          view,                   {.ui = ~SPTAGMASK } },
	{ MODKEY|ShiftMask,             XK_0,          tag,                    {.ui = ~SPTAGMASK } },
	{ MODKEY,                       XK_comma,      focusmon,               {.i = -1 } },
	{ MODKEY,                       XK_period,     focusmon,               {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_comma,      tagmon,                 {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_period,     tagmon,                 {.i = +1 } },
    { ControlMask|Mod1Mask,    XK_comma,      tagallmon,              {.i = +1 } }, //new
	{ ControlMask|Mod1Mask,    XK_period,     tagallmon,              {.i = -1 } }, //new
    
	TAGKEYS(                        XK_1,                                  0)
	TAGKEYS(                        XK_2,                                  1)
	TAGKEYS(                        XK_3,                                  2)
	TAGKEYS(                        XK_4,                                  3)
	TAGKEYS(                        XK_5,                                  4)
	TAGKEYS(                        XK_6,                                  5)
	TAGKEYS(                        XK_7,                                  6)
	TAGKEYS(                        XK_8,                                  7)
	TAGKEYS(                        XK_9,                                  8)

	/*Meus atalhos*/
	{ ControlMask|Mod1Mask,         XK_l,                           spawn,          SHCMD("~/.local/bin/dwm/slock_personalizado") },
	{ 0,					        XK_Caps_Lock,                   spawn,          SHCMD("~/.local/bin/dwm/som_capslock_numlock") },
	{ 0,					        XK_Num_Lock,                    spawn,          SHCMD("~/.local/bin/dwm/som_capslock_numlock") },
	{ 0,					        XK_Scroll_Lock,                 spawn,          SHCMD("~/.local/bin/dwm/som_capslock_numlock") },
	{ MODKEY,			            XK_k,                           spawn,          SHCMD("~/.local/bin/dwm/altera-layout-teclado") },

	/*volume pulseaudio*/
	{ 0,                            XF86XK_AudioLowerVolume,        spawn,          SHCMD("~/.local/bin/dwm/diminui_volume") },
	{ 0,                            XF86XK_AudioRaiseVolume,        spawn,          SHCMD("~/.local/bin/dwm/aumenta_volume") },
	{ 0,                            XF86XK_AudioMute,               spawn,          SHCMD("~/.local/bin/dwm/muta_volume") },

	/*Volume Microfone Pulseaudio*/
	{ ControlMask,                  XF86XK_AudioRaiseVolume,        spawn,          SHCMD("~/.local/bin/dwm/aumenta_volume_microfone") },
	{ ControlMask,                  XF86XK_AudioLowerVolume,        spawn,          SHCMD("~/.local/bin/dwm/diminui_volume_microfone") },
	{ ControlMask,                  XF86XK_AudioMute,               spawn,          SHCMD("~/.local/bin/dwm/muta_microfone") },

	/*Player de musica*/
	{ 0,                            XF86XK_AudioPlay,               spawn,          SHCMD("~/.local/bin/dwm/playerctl_play") },
	{ 0,                            XF86XK_AudioStop,               spawn,          SHCMD("~/.local/bin/dwm/playerctl_stop") },
	{ 0,                            XF86XK_AudioPrev,               spawn,          SHCMD("~/.local/bin/dwm/playerctl_prev") },
	{ 0,                            XF86XK_AudioNext,               spawn,          SHCMD("~/.local/bin/dwm/playerctl_next") },

	/*Outros atalhos teclado*/
	{ 0,                            XF86XK_HomePage,                spawn,          SHCMD("~/.local/bin/dwm/homepage_program") },
	{ 0,                            XF86XK_Mail,                    spawn,          SHCMD("~/.local/bin/dwm/mail_program") },
	{ 0,                            XF86XK_Search,                  spawn,          SHCMD("~/.local/bin/dwm/search_program") },
	{ 0,                            XF86XK_Calculator,              spawn,          SHCMD("~/.local/bin/dwm/calculator_program") },

	/*Printscreen*/
	{ MODKEY|ShiftMask,             XK_s,                           spawn,          SHCMD("~/.local/bin/dwm/print_edita") },
	{ 0,                            XK_Print,                       spawn,          SHCMD("~/.local/bin/dwm/print_copia") },

	/*Brilho tela notebook*/
	{ 0,							XF86XK_MonBrightnessUp,		spawn,          SHCMD("~/.local/bin/dwm/brilho_tela_aumenta") },
	{ 0,							XF86XK_MonBrightnessDown,		spawn,          SHCMD("~/.local/bin/dwm/brilho_tela_diminui") },

	/*Dmenus*/
	{ MODKEY|ShiftMask,             XK_e,                           spawn,          SHCMD("~/.local/bin/dmenu/dmenu-saida-sistema" ) },
	{ ControlMask|Mod1Mask,         XK_p,                           spawn,          SHCMD("~/.local/bin/dmenu/dmenu-pass" ) },
	{ MODKEY|ShiftMask,             XK_d,                           spawn,          SHCMD("~/.local/bin/dmenu/dmenu-docker" ) },
	{ MODKEY|ShiftMask,			XK_w,	     					spawn,		SHCMD("~/.local/bin/dmenu/dmenu-controle-monitor" ) },
	{ MODKEY|ShiftMask,             XK_a,                           spawn,          SHCMD("~/.local/bin/dmenu/dmenu-controle-som") },
//	{ MODKEY|ShiftMask,             XK_y,                           spawn,          SHCMD("~/.local/bin/dmenu/dmenu-youtube") },
	{ MODKEY|ShiftMask,             XK_t,                           spawn,          SHCMD("~/.local/bin/dmenu/dmenu-tema") },
	{ MODKEY|ShiftMask,             XK_v,                           spawn,          SHCMD("~/.local/bin/dmenu/dmenu-vpn") },
	{ MODKEY|ShiftMask,	        XK_m,                           spawn,          SHCMD("~/.local/bin/dmenu/dmenu-powertop") },

	/*Rofi menus*/
	{ MODKEY,						XK_d,	  						spawn,          SHCMD("~/.local/bin/dwm/roficmd") },

	/*Lancamento Programas*/
	{ MODKEY,						XK_w,							spawn,			SHCMD("google-chrome" ) },
	{ MODKEY,						XK_e,							spawn,			SHCMD("emacsclient -c -a 'emacs'" ) },
	{ MODKEY,						XK_f,							spawn,			SHCMD("thunar" ) }
};

#endif // KEYS_H_
