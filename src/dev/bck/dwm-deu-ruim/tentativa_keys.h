#ifndef KEYS_H_
#define KEYS_H_
/*imports*/
#include <X11/XF86keysym.h>

// Atalho para chamar os scripts
#define PATH(name) "$HOME/.config/suckless/scripts/"name

static const Key keys[] = {
	/* modifier                     key            function                argument */
    { MODKEY,                       XK_p,          spawn,                  {.v = dmenucmd } },
	{ MODKEY,                       XK_Return,     spawn,                  {.v = termcmd } },
	{ MODKEY,                       XK_x,          togglebar,              {0} },
	{ MODKEY|ShiftMask,             XK_x,          toggletopbar,           {0} },

	/*Modifica o tamanho da tela dos programas*/
	{ MODKEY|ControlMask,           XK_p,          riospawnsync,           {.v = dmenucmd } },
	{ MODKEY|ControlMask,           XK_Return,     riospawn,               {.v = termcmd } },
	{ MODKEY|ControlMask,           XK_r,          rioresize,              {0} },

    /*Modimentacao das janelas*/
	{ MODKEY,              			XK_Right,     focusstack,              {.i = +1 } },
	{ MODKEY,              			XK_Left,      focusstack,              {.i = -1 } },

    /*Adiciona e remove janelas da mastes para a lateral*/
	{ MODKEY|ShiftMask,             XK_equal,     incnmaster,              {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_minus,     incnmaster,              {.i = -1 } },

    /*Altera o tamanho das janelas horizontal*/
    { MODKEY|ShiftMask,             XK_Right,      setmfact,                {.f = +0.05} },
	{ MODKEY|ShiftMask,             XK_Left,       setmfact,                {.f = -0.05} },

    /*altera tamanho janelas na vertical*/
    { MODKEY|ShiftMask,             XK_Up,         setcfact,               {.f = +0.25} },
	{ MODKEY|ShiftMask,             XK_Down,       setcfact,               {.f = -0.25} },
	{ MODKEY|ShiftMask,             XK_o,          setcfact,               {0} },

	/*Move a janela de posicao na stack*/ //new
	{ MODKEY,             			XK_Up,          movestack,              {.i = -1 } },
	{ MODKEY,             			XK_Down,        movestack,              {.i = +1 } },

	/*Troca de tag*/
	{ ControlMask|Mod1Mask,         XK_Right,      shiftview,              { .i = +1 } },  //new
	{ ControlMask|Mod1Mask,         XK_Left,       shiftview,              { .i = -1 } },  //new

    /*Altera tamanho da janela em modo floating, sem usar mouse*/
	{ MODKEY|ControlMask|ShiftMask, XK_e,          aspectresize,           {.i = +24} },
	{ MODKEY|ControlMask|ShiftMask, XK_r,          aspectresize,           {.i = -24} },

	{ MODKEY|ShiftMask,             XK_Return,     zoom,                    {0} },
//	{ Mod1Mask,                     XK_Tab,        alttabstart,            {0} },

	/*Muda as tags*/
//	{ ControlMask|Mod1Mask,         XK_t,          togglealttag,           {0} },

	/*Renomeia a tag*/
//	{ MODKEY|ShiftMask,             XK_n,          nametag,                {0} },

	/*Reorganiza as Tags*/
//	{ MODKEY|ControlMask,           XK_r,          reorganizetags,         {0} },

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

    { MODKEY|ShiftMask,             XK_z,          showhideclient,         {0} },
	{ MODKEY,                       XK_c,          killclient,             {0} },
	{ MODKEY|ShiftMask,             XK_q,          quit,                   {0} }, //exit dwm
	{ MODKEY|ShiftMask,             XK_r,          quit,                   {1} }, //restart dwm
    { MODKEY|ShiftMask,             XK_o,          winview,                {0} },

    //Layouts
	{ MODKEY,                       XK_F1,      setlayout,      {.v = &layouts[0]} },
	{ MODKEY,                       XK_F2,      setlayout,      {.v = &layouts[1]} },
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

    /*Scratpads*/
	{ MODKEY|ControlMask,           XK_grave,  setscratch,     {.ui = 0 } }, //nao uso
	{ MODKEY|ControlMask,           XK_grave,  removescratch,  {.ui = 0 } }, //nao uso
	{ MODKEY|ControlMask,           XK_s,      togglescratch,  {.ui = 0 } },
	{ MODKEY|ControlMask,           XK_f,      togglescratch,  {.ui = 1 } },
	{ MODKEY|ControlMask,           XK_b,      togglescratch,  {.ui = 2 } },
	{ MODKEY|ControlMask,           XK_a,      togglescratch,  {.ui = 3 } },
	{ MODKEY|ControlMask,           XK_h,      togglescratch,  {.ui = 4 } },
	{ MODKEY|ControlMask,           XK_n,      togglescratch,  {.ui = 5 } },
	{ MODKEY|ControlMask,           XK_m,      togglescratch,  {.ui = 6 } },
	{ MODKEY|ControlMask,           XK_c,      togglescratch,  {.ui = 7 } },
	{ MODKEY|ControlMask,           XK_y,      togglescratch,  {.ui = 8 } },
	{ MODKEY|ControlMask,           XK_q,      togglescratch,  {.ui = 9 } },
	{ MODKEY|ControlMask,           XK_t,      togglescratch,  {.ui = 10 } },
	{ MODKEY|ControlMask,           XK_g,      togglescratch,  {.ui = 11 } },

	/*Floating*/
	{ MODKEY,                       XK_space,  setlayout,      {.v = &layouts[0]} },
	{ MODKEY|ShiftMask,             XK_space,  togglefloating,         {0} },

	/*Da zoom nas janelas*/
	{ MODKEY|ControlMask|ShiftMask, XK_h,          togglehorizontalmax,    {0} },
	{ MODKEY|ControlMask|ShiftMask, XK_l,          togglehorizontalmax,    {0} },
	{ MODKEY|ControlMask|ShiftMask, XK_j,          toggleverticalmax,      {0} },
	{ MODKEY|ControlMask|ShiftMask, XK_k,          toggleverticalmax,      {0} },
	{ MODKEY|ControlMask,           XK_m,          togglemax,              {0} },

	{ MODKEY|ControlMask|Mod1Mask,  XK_Up,          toggleverticalmax,    {0} },
	{ MODKEY|ControlMask|Mod1Mask,  XK_Down,        toggleverticalmax,    {0} },
	{ MODKEY|ControlMask|Mod1Mask,  XK_Right,       togglehorizontalmax,  {0} },
	{ MODKEY|ControlMask|Mod1Mask,  XK_Left,        togglehorizontalmax,  {0} },
	{ MODKEY|ControlMask|Mod1Mask,  XK_space,       togglemax,            {0} },

    /*Mudar de monitor*/
	{ MODKEY,                       XK_0,          view,                   {.ui = ~SPTAGMASK } },
	{ MODKEY|ShiftMask,             XK_0,          tag,                    {.ui = ~SPTAGMASK } },

	/*Troca de foco entre monitores*/
	{ MODKEY,                       XK_comma,      focusmon,               {.i = -1 } },
	{ MODKEY,                       XK_period,     focusmon,               {.i = +1 } },

	/*Envia o aplicativo selecionado para o outro monitor*/
	{ MODKEY|ShiftMask,             XK_comma,      tagmon,                 {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_period,     tagmon,                 {.i = +1 } },

	/*Move todas as janelas para o outro monitor*/
    { ControlMask|Mod1Mask,         XK_comma,      tagallmon,              {.i = +1 } }, //new
	{ ControlMask|Mod1Mask,         XK_period,     tagallmon,              {.i = -1 } }, //new

	/*Troca a tag aberta entre monitores*/
	{ MODKEY|Mod1Mask|ControlMask,  XK_comma,      tagswapmon,             {.i = +1 } }, //new
	{ MODKEY|Mod1Mask|ControlMask,  XK_period,     tagswapmon,             {.i = -1 } }, //new

	/*Layout ciclico*/
	{ MODKEY,          				XK_minus,      cyclelayout,            {.i = -1 } }, //new
	{ MODKEY,                       XK_equal,      cyclelayout,            {.i = +1 } }, //new

	/*Full screen falso*/
	//{ MODKEY|ShiftMask,                       XK_y,          togglefullscreen,       {0} },
	{ MODKEY|ShiftMask,             XK_F5,         xrdb,                   {.v = NULL } },

	TAGKEYS(                        XK_1,                                  0)
	TAGKEYS(                        XK_2,                                  1)
	TAGKEYS(                        XK_3,                                  2)
	TAGKEYS(                        XK_4,                                  3)
	TAGKEYS(                        XK_5,                                  4)
	TAGKEYS(                        XK_6,                                  5)
/*	TAGKEYS(                        XK_7,                                  6)
	TAGKEYS(                        XK_8,                                  7)
	TAGKEYS(                        XK_9,                                  8)
*/
	/*Meus atalhos*/
	{ ControlMask|Mod1Mask,         XK_l,                           spawn,          SHCMD(PATH("dwm/dwm-slock-personalizado")) },
	{ 0,					        XK_Caps_Lock,                   spawn,          SHCMD(PATH("dwm/dwm-capslock-indicator")) },
	{ 0,					        XK_Num_Lock,                    spawn,          SHCMD(PATH("dwm/dwm-numlock-indicator")) },
	{ 0,					        XK_Scroll_Lock,                 spawn,          SHCMD(PATH("dwm/dwm-som-capslock-numlock")) },
	{ MODKEY,			            XK_k,                           spawn,          SHCMD(PATH("dwm/dwm-altera-layout-teclado")) },
	{ MODKEY,			            XK_l,                           spawn,          SHCMD(PATH("dwm/dwm-conky-toggle")) },

	/*volume pulseaudio*/
	{ 0,                            XF86XK_AudioLowerVolume,        spawn,          SHCMD(PATH("dwm/dwm-diminui-volume")) },
	{ 0,                            XF86XK_AudioRaiseVolume,        spawn,          SHCMD(PATH("dwm/dwm-aumenta-volume")) },
	{ 0,                            XF86XK_AudioMute,               spawn,          SHCMD(PATH("dwm/dwm-muta-volume")) },

	/*Volume Microfone Pulseaudio*/
	{ ControlMask,                  XF86XK_AudioRaiseVolume,        spawn,          SHCMD(PATH("dwm/dwm-aumenta-volume-microfone")) },
	{ ControlMask,                  XF86XK_AudioLowerVolume,        spawn,          SHCMD(PATH("dwm/dwm-diminui-volume-microfone")) },
	{ ControlMask,                  XF86XK_AudioMute,               spawn,          SHCMD(PATH("dwm/dwm-muta-microfone")) },

	/*Player de musidwm-ca*/
	{ 0,                            XF86XK_AudioPlay,               spawn,          SHCMD(PATH("dwm/dwm-playerctl-play")) },
	{ 0,                            XF86XK_AudioStop,               spawn,          SHCMD(PATH("dwm/dwm-playerctl-stop")) },
	{ 0,                            XF86XK_AudioPrev,               spawn,          SHCMD(PATH("dwm/dwm-playerctl-prev")) },
	{ 0,                            XF86XK_AudioNext,               spawn,          SHCMD(PATH("dwm/dwm-playerctl-next")) },

	/*Outros atalhosdwm- teclado*/
	{ 0,                            XF86XK_HomePage,                spawn,          SHCMD(PATH("dwm/dwm-homepage-program")) },
	{ 0,                            XF86XK_Mail,                    spawn,          SHCMD(PATH("dwm/dwm-mail-program")) },
	{ 0,                            XF86XK_Search,                  spawn,          SHCMD(PATH("dwm/dwm-search-program")) },
	{ 0,                            XF86XK_Calculator,              spawn,          SHCMD(PATH("dwm/dwm-calculator-program")) },

	/*Printscreen*/
	{ MODKEY|ShiftMask,             XK_s,                           spawn,          SHCMD(PATH("dwm/dwm-print-edita")) },
	{ 0,                            XK_Print,                       spawn,          SHCMD(PATH("dwm/dwm-print-copia")) },

	/*Brilho tela notebook*/
	{ 0,							XF86XK_MonBrightnessUp,		    spawn,          SHCMD(PATH("dwm/dwm-brilho-tela-aumenta")) },
	{ 0,							XF86XK_MonBrightnessDown,		spawn,          SHCMD(PATH("dwm/dwm-brilho-tela-diminui")) },

	/*Dmenus*/
	{ MODKEY|ShiftMask,             XK_e,                           spawn,          SHCMD(PATH("dmenu/dmenu-saida-sistema" )) },
	{ ControlMask|Mod1Mask,         XK_p,                           spawn,          SHCMD(PATH("dmenu/dmenu-pass" )) },
	{ MODKEY|ShiftMask,             XK_i,                           spawn,          SHCMD(PATH("dmenu/dmenu-wallpaper" )) },
	{ MODKEY|ShiftMask,			    XK_w,	     					spawn,			SHCMD(PATH("dmenu/dmenu-controle-monitor" )) },
	{ MODKEY|ShiftMask,             XK_a,                           spawn,          SHCMD(PATH("dmenu/dmenu-controle-som")) },
	{ MODKEY|ShiftMask,             XK_l,                           spawn,          SHCMD(PATH("dmenu/dmenu-layouts-dwm")) },
	{ MODKEY|ShiftMask,             XK_t,                           spawn,          SHCMD(PATH("dmenu/dmenu-tema")) },
	{ MODKEY|ShiftMask,             XK_v,                           spawn,          SHCMD(PATH("dmenu/dmenu-vpn")) },
	{ MODKEY|ShiftMask,	            XK_m,                           spawn,          SHCMD(PATH("dmenu/dmenu-powertop")) },
	{ MODKEY|ShiftMask,	            XK_n,                           spawn,          SHCMD(PATH("dmenu/dmenu-nvidia-switch")) },
	{ MODKEY|ShiftMask,	            XK_k,                           spawn,          SHCMD(PATH("dmenu/dmenu-close-programs")) },
	{ MODKEY|ControlMask,	        XK_l,                           spawn,          SHCMD(PATH("dmenu/dmenu-live-wallpaper")) },
	{ MODKEY|ShiftMask,	            XK_p,                           spawn,          SHCMD(PATH("dmenu/dmenu-player")) },
	{ MODKEY|ShiftMask,	            XK_r,                           spawn,          SHCMD(PATH("dmenu/dmenu-rec")) },
	{ MODKEY|ShiftMask,	            XK_h,                           spawn,          SHCMD(PATH("dmenu/dmenu-homelab")) },
	{ MODKEY|ShiftMask,	            XK_g,                           spawn,          SHCMD(PATH("dmenu/dmenu-pomodoro")) },
	{ MODKEY|ShiftMask,	            XK_d,                           spawn,          SHCMD(PATH("dmenu/dmenu-dwmblocks-operation")) },
	{ MODKEY|ShiftMask,	            XK_c,                           spawn,          SHCMD(PATH("dmenu/dmenu-docker")) },
	{ MODKEY|ShiftMask,	            XK_b,                           spawn,          SHCMD(PATH("dmenu/dmenu-bookmark")) },
	{ Mod1Mask|ShiftMask,	        XK_b,                           spawn,          SHCMD(PATH("dmenu/dmenu-bookmark private")) },
	{ MODKEY|ControlMask,	        XK_b,                           spawn,          SHCMD(PATH("dmenu/dmenu-bookmark add")) },
	{ MODKEY|ControlMask|ShiftMask,	XK_b,                           spawn,          SHCMD(PATH("dmenu/dmenu-bookmark del")) },

	/* Grava area selecionada */
	{ MODKEY,			            XK_r,                           spawn,          SHCMD(PATH("dwm/dwm-rec-area")) },

	/*Rofi menus*/
	{ MODKEY,						XK_d,	  						spawn,          SHCMD(PATH("dwm/dwm-roficmd")) },
	{ MODKEY,						XK_b,	  						spawn,          SHCMD(PATH("dwm/dwm-bitwarden-rofi")) },

	/*Lancamento Programas*/
	{ MODKEY,						XK_w,							spawn,			SHCMD("/opt/google/chrome/google-chrome --enable-feactures=PlataformHEVCDecoderSupport") },
//	{ MODKEY,						XK_w,							spawn,			SHCMD("firefox") },
	{ MODKEY,						XK_e,							spawn,			SHCMD("emacsclient -c -a 'emacs'" ) },
	{ MODKEY,						XK_f,							spawn,			SHCMD("thunar" ) },
	{ ControlMask|Mod1Mask,         XK_d,                           spawn,			SHCMD("killall dwmblocks ; dwmblocks" ) }
};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static const Button buttons[] = {
	/* click                event mask           button          function        argument */
	{ ClkButton,            0,                   Button1,        spawn,          SHCMD(PATH("dwm/dwm-roficmd")) },  //abre rofi
	{ ClkButton,            0,                   Button3,        spawn,          SHCMD(PATH("dwm/dwm-timeshiftcmd")) },  //abre timeshift

	{ ClkLtSymbol,          0,                   Button1,        spawn,          SHCMD(PATH("dmenu/dmenu-layouts-dwm")) },  //abre dmenu de layouts
	{ ClkLtSymbol,          0,                   Button3,        setlayout,      {.v = &layouts[0]} },  //retorna ao layout padrao
	{ ClkLtSymbol,          0,                   Button4,        cyclelayout,    {.i = +1 } },  //avanca para o proximo layout
	{ ClkLtSymbol,          0,                   Button5,        cyclelayout,    {.i = -1 } },  //retorna para o layout anterior

	{ ClkWinTitle,          0,                   Button1,        togglewin,      {0} },
	{ ClkWinTitle,          0,                   Button3,        showhideclient, {0} },
	{ ClkWinTitle,          0,                   Button2,        zoom,           {0} },
	{ ClkWinTitle,          0,                   Button4,        focusstack,     {.i = +1 } },  //avanca o foco para a proxima janela
	{ ClkWinTitle,          0,                   Button5,        focusstack,     {.i = -1 } },  //o foco retona para a janela anterior

	{ ClkStatusText,        0,                   Button1,        sigstatusbar,   {.i = 1 } },
	{ ClkStatusText,        0,                   Button2,        sigstatusbar,   {.i = 2 } },
	{ ClkStatusText,        0,                   Button3,        sigstatusbar,   {.i = 3 } },
	{ ClkStatusText,        0,                   Button4,        sigstatusbar,   {.i = 4 } },
	{ ClkStatusText,        0,                   Button5,        sigstatusbar,   {.i = 5 } },
	{ ClkStatusText,        ShiftMask,           Button1,        sigstatusbar,   {.i = 6 } },
	{ ClkStatusText,        ShiftMask,           Button2,        sigstatusbar,   {.i = 7 } },
	{ ClkStatusText,        ShiftMask,           Button3,        sigstatusbar,   {.i = 8 } },
	{ ClkStatusText,        ShiftMask,           Button4,        sigstatusbar,   {.i = 9 } },
	{ ClkStatusText,        ShiftMask,           Button5,        sigstatusbar,   {.i = 10 } },
	/* placemouse options, choose which feels more natural:
	 *    0 - tiled position is relative to mouse cursor
	 *    1 - tiled postiion is relative to window center
	 *    2 - mouse pointer warps to window center
	 *
	 * The moveorplace uses movemouse or placemouse depending on the floating state
	 * of the selected client. Set up individual keybindings for the two if you want
	 * to control these separately (i.e. to retain the feature to move a tiled window
	 * into a floating position).
	 */
	{ ClkClientWin,         MODKEY,              Button1,        moveorplace,    {.i = 1} },
	{ ClkClientWin,         MODKEY,              Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,              Button3,        resizemouse,    {0} },

	{ ClkClientWin,         MODKEY,              Button4,        resizemousescroll, {.v = &scrollargs[1]} },
	{ ClkClientWin,         MODKEY,              Button5,        resizemousescroll, {.v = &scrollargs[0]} },
	{ ClkClientWin,         MODKEY,              Button6,        resizemousescroll, {.v = &scrollargs[3]} },
	{ ClkClientWin,         MODKEY,              Button7,        resizemousescroll, {.v = &scrollargs[2]} },

	{ ClkClientWin,         MODKEY|ShiftMask,    Button3,        dragcfact,      {0} },
	{ ClkClientWin,         MODKEY|ShiftMask,    Button1,        dragmfact,      {0} },

	{ ClkTagBar,            0,                   Button1,        view,           {0} },
	{ ClkTagBar,            0,                   Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,              Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,              Button3,        toggletag,      {0} },
	{ ClkTagBar,            0,   		         Button4,        shiftview,     {.i = +1 } },  //avanca para a proxima tag
	{ ClkTagBar,            0,                   Button5,        shiftview,     {.i = -1 } },  //retorna para a tag anterior
};

#endif // KEYS_H_
