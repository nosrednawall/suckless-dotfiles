/* See LICENSE file for copyright and license details. */

/* Helper macros for spawning commands */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }
#define CMD(...)   { .v = (const char*[]){ __VA_ARGS__, NULL } }

/* appearance */
static const unsigned int borderpx       = 4;   /* border pixel of windows */

/* This allows the bar border size to be explicitly set separately from borderpx.
 * If left as 0 then it will default to the borderpx value of the monitor and will
 * automatically update with setborderpx. */
static const unsigned int barborderpx    = 4;  /* border pixel of bar */
static const unsigned int snap           = 32;  /* snap pixel */
static const int swallowfloating         = 0;   /* 1 means swallow floating windows by default */
static const unsigned int gappih         = 10;  /* horiz inner gap between windows */
static const unsigned int gappiv         = 10;  /* vert inner gap between windows */
static const unsigned int gappoh         = 10;  /* horiz outer gap between windows and screen edge */
static const unsigned int gappov         = 10;  /* vert outer gap between windows and screen edge */
static const int smartgaps_fact          = 1;   /* gap factor when there is only one client; 0 = no gaps, 3 = 3x outer gaps */
static const char autostartblocksh[]     = "autostart_blocking.sh";
static const char autostartsh[]          = "autostart.sh";
static const char dwmdir[]               = "dwm";
static const char localshare[]           = ".config/suckless";
static const int showbar                 = 1;   /* 0 means no bar */
static const int topbar                  = 1;   /* 0 means bottom bar */
static const int bar_height              = 0;   /* 0 means derive from font, >= 1 explicit height */
static const int vertpad                 = 10;  /* vertical padding of bar */
static const int sidepad                 = 10;  /* horizontal padding of bar */
#define ICONSIZE 20    /* icon size */
#define ICONSPACING 5  /* space between icon and title */

/* Status is to be shown on: -1 (all monitors), 0 (a specific monitor by index), 'A' (active monitor) */
static const int statusmon               = -1;
static const char buttonbar[]            = "  ";
static const unsigned int systrayspacing = 2;   /* systray spacing */
static const int showsystray             = 1;   /* 0 means no systray */
static const unsigned int ulinepad = 1;         /* horizontal padding between the underline and tag */
static const unsigned int ulinestroke  = 2;     /* thickness / height of the underline */
static const unsigned int ulinevoffset = -3;     /* how far above the bottom of the bar the line should appear */
static const int ulineall = 0;                  /* 1 to show underline on all tags, 0 for just the active ones */

/* Indicators: see patch/bar_indicators.h for options */
static int tagindicatortype              = INDICATOR_TOP_LEFT_SQUARE;
static int tiledindicatortype            = INDICATOR_NONE;
static int floatindicatortype            = INDICATOR_NONE;
static const char *fonts[]          	 = {
	"Iosevka Term:pixelsize=15",
    "Symbols Nerd Font:style=Bold:antialias=true:pixelsize=16",  //for dwmblocks
	"Font Awesome 6 Free Solid:style=Bold:pixelsize=16",  // for weather in dwmblocks
};
static const char dmenufont[]            = "Caskaydia Mono Nerd Font:size=16:style=Regular:antialias=true:pixelsize=17";
#include "themes/solarized_dark.h"

static char *colors[][ColCount] = {
	/*                       fg                bg                border                float */
	[SchemeNorm]         = { normfgcolor,      normbgcolor,      normbordercolor,      normfloatcolor },
	[SchemeSel]          = { selfgcolor,       selbgcolor,       selbordercolor,       selfloatcolor },
	[SchemeTitleNorm]    = { titlenormfgcolor, titlenormbgcolor, titlenormbordercolor, titlenormfloatcolor },
	[SchemeTitleSel]     = { titleselfgcolor,  titleselbgcolor,  titleselbordercolor,  titleselfloatcolor },
	[SchemeTagsNorm]     = { tagsnormfgcolor,  tagsnormbgcolor,  tagsnormbordercolor,  tagsnormfloatcolor },
	[SchemeTagsSel]      = { tagsselfgcolor,   tagsselbgcolor,   tagsselbordercolor,   tagsselfloatcolor },
	[SchemeHidNorm]      = { hidnormfgcolor,   hidnormbgcolor,   c000000,              c000000 },
	[SchemeHidSel]       = { hidselfgcolor,    hidselbgcolor,    c000000,              c000000 },
	[SchemeUrg]          = { urgfgcolor,       urgbgcolor,       urgbordercolor,       urgfloatcolor },
	[SchemeTagsUnused]   = { tagsunusedfgcolor, tagsunusedbgcolor, tagsunusedbordercolor, tagsunusedfloatcolor }, // Novo esquema
	[SchemeLtSymbol]     = { ltsymbolfgcolor,  ltsymbolbgcolor,  c000000,              c000000 },
};

const char *spcmd1[]  = {"st", "-n", "spterm", "-g", "120x34", NULL };
const char *spcmd2[]  = {"flatpak", "run", "com.bitwarden.desktop", NULL };
const char *spcmd3[]  = {"st", "-n", "spnmtui", "-g", "100x34", "-e", "nmtui", NULL };
const char *spcmd4[]  = {"st", "-n", "sprmpc", "-g", "100x34", "-e", "rmpc", NULL };
const char *spcmd5[]  = {"/usr/bin/firefoxpwa", "site", "launch", "01K04YSNWVWAC0G6TD61VN9ZPV",  NULL };

static Sp scratchpads[] = {
   /* name          cmd  */
	{"spterm",      		spcmd1},
	{"bitwarden",   		spcmd2},
	{"spnmtui",     		spcmd3},
	{"sprmpc",   		    spcmd4},
	{"whatsapp-firefox",	spcmd5}
};

/* Tags
 * In a traditional dwm the number of tags in use can be changed simply by changing the number
 * of strings in the tags array. This build does things a bit different which has some added
 * benefits. If you need to change the number of tags here then change the NUMTAGS macro in dwm.c.
 *
 * Examples:
 *
 *  1) static char *tagicons[][NUMTAGS*2] = {
 *         [DEFAULT_TAGS] = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G", "H", "I" },
 *     }
 *
 *  2) static char *tagicons[][1] = {
 *         [DEFAULT_TAGS] = { "•" },
 *     }
 *
 * The first example would result in the tags on the first monitor to be 1 through 9, while the
 * tags for the second monitor would be named A through I. A third monitor would start again at
 * 1 through 9 while the tags on a fourth monitor would also be named A through I. Note the tags
 * count of NUMTAGS*2 in the array initialiser which defines how many tag text / icon exists in
 * the array. This can be changed to *3 to add separate icons for a third monitor.
 *
 * For the second example each tag would be represented as a bullet point. Both cases work the
 * same from a technical standpoint - the icon index is derived from the tag index and the monitor
 * index. If the icon index is is greater than the number of tag icons then it will wrap around
 * until it an icon matches. Similarly if there are two tag icons then it would alternate between
 * them. This works seamlessly with alternative tags and alttagsdecoration patches.
 */
/*
static char *tagicons[][NUMTAGS] =
{
	[DEFAULT_TAGS]        = { "1", "2", "3", "4", "5", "6", "7", "8", "9" },
	[ALTERNATIVE_TAGS]    = { "A", "B", "C", "D", "E", "F", "G", "H", "I" },
	[ALT_TAGS_DECORATION] = { "1", "<2>", "<3>", "<4>", "<5>", "<6>", "<7>", "<8>", "<9>" },
};
*/
static char *tagicons[][NUMTAGS] =
{
	[DEFAULT_TAGS]        = { "1", "2", "3", "4", "5", "6" },
	[ALTERNATIVE_TAGS]    = { "A", "B", "C", "D", "E", "F" },
	[ALT_TAGS_DECORATION] = { "1", "<2>", "<3>", "<4>", "<5>", "<6>" },
};

/* There are two options when it comes to per-client rules:
 *  - a typical struct table or
 *  - using the RULE macro
 *
 * A traditional struct table looks like this:
 *    // class      instance  title  wintype  tags mask  isfloating  monitor
 *    { "Gimp",     NULL,     NULL,  NULL,    1 << 4,    0,          -1 },
 *    { "Firefox",  NULL,     NULL,  NULL,    1 << 7,    0,          -1 },
 *
 * The RULE macro has the default values set for each field allowing you to only
 * specify the values that are relevant for your rule, e.g.
 *
 *    RULE(.class = "Gimp", .tags = 1 << 4)
 *    RULE(.class = "Firefox", .tags = 1 << 7)
 *
 * Refer to the Rule struct definition for the list of available fields depending on
 * the patches you enable.
 */
static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 *	WM_WINDOW_ROLE(STRING) = role
	 *	_NET_WM_WINDOW_TYPE(ATOM) = wintype
	 */
	RULE(.wintype = WTYPE "DIALOG", .isfloating = 1)
	RULE(.wintype = WTYPE "UTILITY", .isfloating = 1)
	RULE(.wintype = WTYPE "TOOLBAR", .isfloating = 1)
	RULE(.wintype = WTYPE "SPLASH", .isfloating = 1)

	// Swallow windows terminal
	RULE(.class = "st-256color" TERMINAL)

	// Apresentation office
	RULE(.class = "Soffice", .instance = "soffice", .title = NULL, .monitor = 0, .tags = 0, .isfloating = 0)
	RULE(.class = "Soffice", .instance = "soffice", .title = "Presenting:", .monitor = 1, .tags = 0, .isfloating = 0)
	RULE(.class = "Soffice", .instance = "soffice", .title = "Apresentando", .monitor = 1, .tags = 0, .isfloating = 0)

	// Floating windows
	RULE(.class = "copyq", .tags = 0, .isfloating = 1)
	RULE(.class = "Sxiv", .tags = 0, .isfloating = 1)
	RULE(.class = "Qalculate-gtk", .tags = 0, .isfloating = 1)
    RULE(.class = "Nm-connection-editor", .tags = 0, .isfloating = 1)

	// Scratchpads
	RULE(.instance = "spterm", .tags = SPTAG(0), .isfloating = 1)
	RULE(.instance = "bitwarden",  .tags = SPTAG(1), .isfloating = 1)
	RULE(.instance = "spnmtui" ,  .tags = SPTAG(2), .isfloating = 1)
	RULE(.instance = "sprmpc",  .tags = SPTAG(3), .isfloating = 1)
	RULE(.instance = "FFPWA-01K04YSNWVWAC0G6TD61VN9ZPV",  .tags = SPTAG(4), .isfloating = 1)

};

static const MonitorRule monrules[] = {
	/* monitor  tag   layout  mfact  nmaster  showbar  topbar */
	{  1,       -1,   5,      -1,    -1,      -1,      -1     }, // use a different layout for the second monitor
	{  -1,      -1,   8,      -1,    -1,      -1,      -1     }, // default
};

/* Bar rules allow you to configure what is shown where on the bar, as well as
 * introducing your own bar modules.
 *
 *    monitor:
 *      -1  show on all monitors
 *       0  show on monitor 0
 *      'A' show on active monitor (i.e. focused / selected) (or just -1 for active?)
 *    bar - bar index, 0 is default, 1 is extrabar
 *    alignment - how the module is aligned compared to other modules
 *    widthfunc, drawfunc, clickfunc - providing bar module width, draw and click functions
 *    name - does nothing, intended for visual clue and for logging / debugging
 */
static const BarRule barrules[] = {
	/* monitor   bar    alignment         widthfunc                 drawfunc                clickfunc                hoverfunc                name */
	{ -1,        0,     BAR_ALIGN_LEFT,   width_stbutton,           draw_stbutton,          click_stbutton,          NULL,                    "statusbutton" },
	{ -1,        0,     BAR_ALIGN_LEFT,   width_tags,               draw_tags,              click_tags,              hover_tags,              "tags" },
	{  0,        0,     BAR_ALIGN_RIGHT,  width_systray,            draw_systray,           click_systray,           NULL,                    "systray" },
	{ -1,        0,     BAR_ALIGN_LEFT,   width_ltsymbol,           draw_ltsymbol,          click_ltsymbol,          NULL,                    "layout" },
	{ statusmon, 0,     BAR_ALIGN_RIGHT,  width_status2d,           draw_status2d,          click_statuscmd,         NULL,                    "status2d" },
	{ -1,        0,     BAR_ALIGN_NONE,   width_wintitle,           draw_wintitle,          click_wintitle,          NULL,                    "wintitle" },
};

/* layout(s) */
static const float mfact     = 0.5; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 0;    /* 1 means respect size hints in tiled resizals */
static const int lockfullscreen = 1; /* 1 will force focus on the fullscreen window */

#define FORCE_VSPLIT 1

/* mouse scroll resize */
static const int scrollsensetivity = 30; /* 1 means resize window by 1 pixel for each scroll event */
/* resizemousescroll direction argument list */
static const int scrollargs[][2] = {
	/* width change         height change */
	{ +scrollsensetivity,	0 },
	{ -scrollsensetivity,	0 },
	{ 0, 				  	+scrollsensetivity },
	{ 0, 					-scrollsensetivity },
};

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },    /* first entry is default */
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ "[M]",      monocle },
	{ "TTT",      bstack },
	{ "===",      bstackhoriz },
	{ "|M|",      centeredmaster },
	{ ">M>",      centeredfloatingmaster },
	{ "|||",      col },
	{ "[D]",      deck },
	{ "(@)",      spiral },
	{ "[\\]",     dwindle },
	{ "HHH",      grid },
	{ "---",      horizgrid },
	{ ":::",      gaplessgrid },
	{ "###",      nrowgrid },
};

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG)                                                                                               \
       &((Keychord){1, {{MODKEY, KEY}},                                        view,           {.ui = 1 << TAG} }), \
       &((Keychord){1, {{MODKEY|ControlMask, KEY}},                            toggleview,     {.ui = 1 << TAG} }), \
       &((Keychord){1, {{MODKEY|ShiftMask, KEY}},                              tag,            {.ui = 1 << TAG} }), \
       &((Keychord){1, {{MODKEY|ControlMask|ShiftMask, KEY}},                  toggletag,      {.ui = 1 << TAG} }),


/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[] = {
	"dmenu_run",
	"-m", dmenumon,
	"-fn", dmenufont,
	"-nb", normbgcolor,
	"-nf", normfgcolor,
	"-sb", selbgcolor,
//  "-sf", selfgcolor,
	"-sf", normbgcolor,
	NULL
};

static const char *termcmd[]  = { "st", NULL };

/* This defines the name of the executable that handles the bar (used for signalling purposes) */
#define STATUSBAR "dwmblocks"
#include <X11/XF86keysym.h>
// Atalho para chamar os scripts
#define PATH(name) "$HOME/.config/suckless/scripts/"name

static Keychord *keychords[] = {
    /* modifier                     key            function                argument */
    &((Keychord){1, {{MODKEY, XK_p}}, spawn, {.v = dmenucmd } }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_Return}}, spawn, {.v = termcmd } }),
    &((Keychord){1, {{MODKEY, XK_b}}, togglebar, {0} }),
	&((Keychord){2, {{MODKEY, XK_i}, {MODKEY, XK_i}},                       spawn,          {.v = termcmd } }),

    /* Window navigation */
    &((Keychord){1, {{MODKEY, XK_Right}}, focusstack, {.i = +1 } }),
    &((Keychord){1, {{MODKEY, XK_Left}}, focusstack, {.i = -1 } }),
    &((Keychord){1, {{ControlMask|Mod1Mask, XK_Right}}, shiftview, {.i = +1 } }),
    &((Keychord){1, {{ControlMask|Mod1Mask, XK_Left}}, shiftview, {.i = -1 } }),

    /* Add/remove windows from master area */
    &((Keychord){1, {{MODKEY|ShiftMask, XK_equal}}, incnmaster, {.i = +1 } }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_minus}}, incnmaster, {.i = -1 } }),

    /* Horizontal window size adjustment */
    &((Keychord){1, {{MODKEY|ShiftMask, XK_Right}}, setmfact, {.f = +0.05} }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_Left}}, setmfact, {.f = -0.05} }),

    /* Vertical window size adjustment */
    &((Keychord){1, {{MODKEY|ShiftMask, XK_Up}}, setcfact, {.f = +0.25} }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_Down}}, setcfact, {.f = -0.25} }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_o}}, setcfact, {0} }),
    &((Keychord){1, {{MODKEY, XK_Return}}, zoom, {0} }),

    /* Gaps */
    &((Keychord){1, {{ControlMask|Mod1Mask, XK_1}}, incrgaps, {.i = +1 } }),
    &((Keychord){1, {{ControlMask|Mod1Mask|ShiftMask, XK_1}}, incrgaps, {.i = -1 } }),
    &((Keychord){1, {{ControlMask|Mod1Mask, XK_2}}, incrigaps, {.i = +1 } }),
    &((Keychord){1, {{ControlMask|Mod1Mask|ShiftMask, XK_2}}, incrigaps, {.i = -1 } }),
    &((Keychord){1, {{ControlMask|Mod1Mask, XK_3}}, incrogaps, {.i = +1 } }),
    &((Keychord){1, {{ControlMask|Mod1Mask|ShiftMask, XK_3}}, incrogaps, {.i = -1 } }),
    &((Keychord){1, {{ControlMask|Mod1Mask, XK_4}}, incrihgaps, {.i = +1 } }),
    &((Keychord){1, {{ControlMask|Mod1Mask|ShiftMask, XK_4}}, incrihgaps, {.i = -1 } }),
    &((Keychord){1, {{ControlMask|Mod1Mask, XK_5}}, incrivgaps, {.i = +1 } }),
    &((Keychord){1, {{ControlMask|Mod1Mask|ShiftMask, XK_5}}, incrivgaps, {.i = -1 } }),
    &((Keychord){1, {{ControlMask|Mod1Mask, XK_6}}, incrohgaps, {.i = +1 } }),
    &((Keychord){1, {{ControlMask|Mod1Mask|ShiftMask, XK_6}}, incrohgaps, {.i = -1 } }),
    &((Keychord){1, {{ControlMask|Mod1Mask, XK_7}}, incrovgaps, {.i = +1 } }),
    &((Keychord){1, {{ControlMask|Mod1Mask|ShiftMask, XK_7}}, incrovgaps, {.i = -1 } }),
    &((Keychord){1, {{ControlMask|Mod1Mask, XK_0}}, togglegaps, {0} }),
    &((Keychord){1, {{ControlMask|Mod1Mask|ShiftMask, XK_0}}, defaultgaps, {0} }),

    &((Keychord){1, {{MODKEY, XK_Tab}}, view, {0} }),
    &((Keychord){1, {{ControlMask|Mod1Mask, XK_c}}, killclient, {0} }),
    &((Keychord){1, {{ControlMask|Mod1Mask, XK_q}}, quit, {0} }), //exit
    &((Keychord){1, {{ControlMask|Mod1Mask, XK_r}}, quit, {1} }), //restart
    &((Keychord){1, {{MODKEY|ShiftMask, XK_F5}}, xrdb, {.v = NULL } }),

    // Layouts
    &((Keychord){1, {{MODKEY, XK_F1}}, setlayout, {.v = &layouts[0]} }),
    &((Keychord){1, {{MODKEY, XK_F2}}, setlayout, {.v = &layouts[1]} }),
    &((Keychord){1, {{MODKEY, XK_F3}}, setlayout, {.v = &layouts[2]} }),
    &((Keychord){1, {{MODKEY, XK_F4}}, setlayout, {.v = &layouts[3]} }),
    &((Keychord){1, {{MODKEY, XK_F5}}, setlayout, {.v = &layouts[4]} }),
    &((Keychord){1, {{MODKEY, XK_F6}}, setlayout, {.v = &layouts[5]} }),
    &((Keychord){1, {{MODKEY, XK_F7}}, setlayout, {.v = &layouts[6]} }),
    &((Keychord){1, {{MODKEY, XK_F8}}, setlayout, {.v = &layouts[7]} }),
    &((Keychord){1, {{MODKEY, XK_F9}}, setlayout, {.v = &layouts[8]} }),
    &((Keychord){1, {{MODKEY, XK_F10}}, setlayout, {.v = &layouts[9]} }),
    &((Keychord){1, {{MODKEY, XK_F11}}, setlayout, {.v = &layouts[10]} }),
    &((Keychord){1, {{MODKEY, XK_F12}}, setlayout, {.v = &layouts[11]} }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_F1}}, setlayout, {.v = &layouts[12]} }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_F2}}, setlayout, {.v = &layouts[13]} }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_F3}}, setlayout, {.v = &layouts[14]} }),

    &((Keychord){1, {{MODKEY, XK_space}}, setlayout, {0} }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_space}}, togglefloating, {0} }),

    &((Keychord){1, {{MODKEY, XK_0}}, view, {.ui = ~SPTAGMASK } }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_0}}, tag, {.ui = ~SPTAGMASK } }),
    &((Keychord){1, {{MODKEY, XK_comma}}, focusmon, {.i = -1 } }),
    &((Keychord){1, {{MODKEY, XK_period}}, focusmon, {.i = +1 } }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_comma}}, tagmon, {.i = -1 } }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_period}}, tagmon, {.i = +1 } }),
    /* Layout cycling */
    &((Keychord){1, {{MODKEY, XK_minus}}, cyclelayout, {.i = -1 } }),
    &((Keychord){1, {{MODKEY, XK_equal}}, cyclelayout, {.i = +1 } }),

    /* Scratchpads */
    &((Keychord){1, {{MODKEY|ControlMask, XK_grave}}, setscratch, {.ui = 0 } }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_grave}}, removescratch, {.ui = 0 } }),
    &((Keychord){2, {{MODKEY, XK_s}, {0, XK_s}}, togglescratch, {.ui = 0 } }),
    &((Keychord){2, {{MODKEY, XK_s}, {0, XK_b}}, togglescratch, {.ui = 1 } }),
    &((Keychord){2, {{MODKEY, XK_s}, {0, XK_n}}, togglescratch, {.ui = 2 } }),
    &((Keychord){2, {{MODKEY, XK_s}, {0, XK_m}}, togglescratch, {.ui = 3 } }),
    &((Keychord){2, {{MODKEY, XK_s}, {0, XK_c}}, togglescratch, {.ui = 4 } }),

    /* Custom shortcuts */
    &((Keychord){1, {{ControlMask|Mod1Mask, XK_l}}, spawn, SHCMD(PATH("dwm/dwm-slock-personalizado")) }),
    &((Keychord){1, {{0, XK_Caps_Lock}}, spawn, SHCMD(PATH("dwm/dwm-capslock-indicator")) }),
    &((Keychord){1, {{0, XK_Num_Lock}}, spawn, SHCMD(PATH("dwm/dwm-numlock-indicator")) }),
    &((Keychord){1, {{0, XK_Scroll_Lock}}, spawn, SHCMD(PATH("dwm/dwm-som-capslock-numlock")) }),
    &((Keychord){1, {{MODKEY, XK_k}}, spawn, SHCMD(PATH("dwm/dwm-altera-layout-teclado")) }),
    &((Keychord){1, {{MODKEY, XK_l}}, spawn, SHCMD(PATH("dwm/dwm-conky-toggle")) }),

    /* Pulseaudio volume */
    &((Keychord){1, {{0, XF86XK_AudioLowerVolume}}, spawn, SHCMD(PATH("dwm/dwm-diminui-volume")) }),
    &((Keychord){1, {{0, XF86XK_AudioRaiseVolume}}, spawn, SHCMD(PATH("dwm/dwm-aumenta-volume")) }),
    &((Keychord){1, {{0, XF86XK_AudioMute}}, spawn, SHCMD(PATH("dwm/dwm-muta-volume")) }),

    /* Microphone volume */
    &((Keychord){1, {{ControlMask, XF86XK_AudioRaiseVolume}}, spawn, SHCMD(PATH("dwm/dwm-aumenta-volume-microfone")) }),
    &((Keychord){1, {{ControlMask, XF86XK_AudioLowerVolume}}, spawn, SHCMD(PATH("dwm/dwm-diminui-volume-microfone")) }),
    &((Keychord){1, {{ControlMask, XF86XK_AudioMute}}, spawn, SHCMD(PATH("dwm/dwm-muta-microfone")) }),

    /* Music player */
    &((Keychord){1, {{0, XF86XK_AudioPlay}}, spawn, SHCMD(PATH("dwm/dwm-playerctl-play")) }),
    &((Keychord){1, {{0, XF86XK_AudioStop}}, spawn, SHCMD(PATH("dwm/dwm-playerctl-stop")) }),
    &((Keychord){1, {{0, XF86XK_AudioPrev}}, spawn, SHCMD(PATH("dwm/dwm-playerctl-prev")) }),
    &((Keychord){1, {{0, XF86XK_AudioNext}}, spawn, SHCMD(PATH("dwm/dwm-playerctl-next")) }),

    /* Other keyboard shortcuts */
    &((Keychord){1, {{0, XF86XK_HomePage}}, spawn, SHCMD(PATH("dwm/dwm-homepage-program")) }),
    &((Keychord){1, {{0, XF86XK_Mail}}, spawn, SHCMD(PATH("dwm/dwm-mail-program")) }),
    &((Keychord){1, {{0, XF86XK_Search}}, spawn, SHCMD(PATH("dwm/dwm-search-program")) }),
    &((Keychord){1, {{0, XF86XK_Calculator}}, spawn, SHCMD(PATH("dwm/dwm-calculator-program")) }),

    /* Screenshot */
    &((Keychord){1, {{MODKEY|ShiftMask, XK_s}}, spawn, SHCMD(PATH("dwm/dwm-print-edita")) }),
    &((Keychord){1, {{0, XK_Print}}, spawn, SHCMD(PATH("dwm/dwm-print-copia")) }),

    /* Screen brightness */
    &((Keychord){1, {{0, XF86XK_MonBrightnessUp}}, spawn, SHCMD(PATH("dwm/dwm-brilho-tela-aumenta")) }),
    &((Keychord){1, {{0, XF86XK_MonBrightnessDown}}, spawn, SHCMD(PATH("dwm/dwm-brilho-tela-diminui")) }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_F9}}, spawn, SHCMD(PATH("dwm/dwm-redshift-aumenta.sh")) }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_F8}}, spawn, SHCMD(PATH("dwm/dwm-redshift-diminui.sh")) }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_F7}}, spawn, SHCMD(PATH("dwm/dwm-toggle-redshift.sh")) }),

    /* Dmenus */
    &((Keychord){1, {{MODKEY|ShiftMask, XK_e}}, spawn, SHCMD(PATH("dmenu/dmenu-saida-sistema")) }),
    &((Keychord){1, {{ControlMask|Mod1Mask, XK_p}}, spawn, SHCMD(PATH("dmenu/dmenu-pass")) }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_i}}, spawn, SHCMD(PATH("dmenu/dmenu-wallpaper")) }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_w}}, spawn, SHCMD(PATH("dmenu/dmenu-controle-monitor")) }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_a}}, spawn, SHCMD(PATH("dmenu/dmenu-controle-som")) }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_l}}, spawn, SHCMD(PATH("dmenu/dmenu-layouts-dwm")) }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_t}}, spawn, SHCMD(PATH("dmenu/dmenu-tema")) }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_v}}, spawn, SHCMD(PATH("dmenu/dmenu-vpn")) }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_m}}, spawn, SHCMD(PATH("dmenu/dmenu-powertop")) }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_n}}, spawn, SHCMD(PATH("dmenu/dmenu-nvidia-switch")) }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_k}}, spawn, SHCMD(PATH("dmenu/dmenu-close-programs")) }),
    &((Keychord){1, {{MODKEY|ControlMask, XK_l}}, spawn, SHCMD(PATH("dmenu/dmenu-live-wallpaper")) }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_p}}, spawn, SHCMD(PATH("dmenu/dmenu-player")) }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_r}}, spawn, SHCMD(PATH("dmenu/dmenu-rec")) }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_h}}, spawn, SHCMD(PATH("dmenu/dmenu-homelab")) }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_g}}, spawn, SHCMD(PATH("dmenu/dmenu-pomodoro")) }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_d}}, spawn, SHCMD(PATH("dmenu/dmenu-dwmblocks-operation")) }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_c}}, spawn, SHCMD(PATH("dmenu/dmenu-docker")) }),
    &((Keychord){1, {{MODKEY|ShiftMask, XK_b}}, spawn, SHCMD(PATH("dmenu/dmenu-bookmark")) }),
    &((Keychord){1, {{Mod1Mask|ShiftMask, XK_b}}, spawn, SHCMD(PATH("dmenu/dmenu-bookmark private")) }),
    &((Keychord){1, {{MODKEY|ControlMask, XK_b}}, spawn, SHCMD(PATH("dmenu/dmenu-bookmark add")) }),
    &((Keychord){1, {{MODKEY|ControlMask|ShiftMask, XK_b}}, spawn, SHCMD(PATH("dmenu/dmenu-bookmark del")) }),

    /* Record selected area */
    &((Keychord){1, {{MODKEY, XK_r}}, spawn, SHCMD(PATH("dwm/dwm-rec-area")) }),

    /* Rofi menus */
    &((Keychord){1, {{MODKEY, XK_d}}, spawn, SHCMD(PATH("dwm/dwm-roficmd")) }),

    /* Program launchers */
    &((Keychord){1, {{MODKEY, XK_w}}, spawn, SHCMD("firefox") }),
    &((Keychord){1, {{MODKEY, XK_e}}, spawn, SHCMD("emacsclient -c -a 'emacs'") }),
    &((Keychord){1, {{MODKEY, XK_f}}, spawn, SHCMD("thunar") }),
    &((Keychord){1, {{ControlMask|Mod1Mask, XK_d}}, spawn, SHCMD("killall dwmblocks ; dwmblocks") }),

    TAGKEYS(XK_1, 0)
    TAGKEYS(XK_2, 1)
    TAGKEYS(XK_3, 2)
    TAGKEYS(XK_4, 3)
    TAGKEYS(XK_5, 4)
    TAGKEYS(XK_6, 5)
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
	{ ClkWinTitle,          0,                   Button4,        focusstack,     {.i = +1 } },  //avanca o foco para a proxima janela
	{ ClkWinTitle,          0,                   Button5,        focusstack,     {.i = -1 } },  //o foco retona para a janela anterior
	{ ClkWinTitle,          0,                   Button2,        zoom,           {0} },
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
	{ ClkClientWin,         MODKEY,              Button4,        resizemousescroll, {.v = &scrollargs[0]} },
	{ ClkClientWin,         MODKEY,              Button5,        resizemousescroll, {.v = &scrollargs[1]} },
	{ ClkClientWin,         MODKEY,              Button6,        resizemousescroll, {.v = &scrollargs[2]} },
	{ ClkClientWin,         MODKEY,              Button7,        resizemousescroll, {.v = &scrollargs[3]} },
	{ ClkClientWin,         MODKEY|ShiftMask,    Button3,        dragcfact,      {0} },
	{ ClkClientWin,         MODKEY|ShiftMask,    Button1,        dragmfact,      {0} },
	{ ClkTagBar,            0,                   Button1,        view,           {0} },
	{ ClkTagBar,            0,                   Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,              Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,              Button3,        toggletag,      {0} },
	{ ClkTagBar,            0,   		         Button4,        shiftview,     {.i = +1 } },  //avanca para a proxima tag
	{ ClkTagBar,            0,                   Button5,        shiftview,     {.i = -1 } },  //retorna para a tag anterior
};

/* signal definitions */
/* signum must be greater than 0 */
/* trigger signals using `xsetroot -name "fsignal:<signame> [<type> <value>]"` */
static const Signal signals[] = {
	/* signum                    function */
	{ "focusstack",              focusstack },
	{ "setmfact",                setmfact },
	{ "togglebar",               togglebar },
	{ "incnmaster",              incnmaster },
	{ "togglefloating",          togglefloating },
	{ "focusmon",                focusmon },
	{ "setcfact",                setcfact },
	{ "tagmon",                  tagmon },
	{ "zoom",                    zoom },
	{ "incrgaps",                incrgaps },
	{ "incrigaps",               incrigaps },
	{ "incrogaps",               incrogaps },
	{ "incrihgaps",              incrihgaps },
	{ "incrivgaps",              incrivgaps },
	{ "incrohgaps",              incrohgaps },
	{ "incrovgaps",              incrovgaps },
	{ "togglegaps",              togglegaps },
	{ "defaultgaps",             defaultgaps },
	{ "setgaps",                 setgapsex },
	{ "view",                    view },
	{ "viewall",                 viewallex },
	{ "viewex",                  viewex },
	{ "toggleview",              toggleview },
	{ "shiftview",               shiftview },
	{ "shiftviewclients",        shiftviewclients },
	{ "cyclelayout",             cyclelayout },
	{ "toggleviewex",            toggleviewex },
	{ "tag",                     tag },
	{ "tagall",                  tagallex },
	{ "tagex",                   tagex },
	{ "toggletag",               toggletag },
	{ "toggletagex",             toggletagex },
	{ "togglescratch",           togglescratch },
	{ "killclient",              killclient },
	{ "xrdb",                    xrdb },
	{ "quit",                    quit },
	{ "setlayout",               setlayout },
	{ "setlayoutex",             setlayoutex },
};
