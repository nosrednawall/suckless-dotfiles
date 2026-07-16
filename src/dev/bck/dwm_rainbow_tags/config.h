/* See LICENSE file for copyright and license details. */

/* Helper macros for spawning commands */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }
#define CMD(...)   { .v = (const char*[]){ __VA_ARGS__, NULL } }

/* appearance */
static const unsigned int borderpx       = 5;   /* border pixel of windows */
static const unsigned int snap           = 32;  /* snap pixel */
static const int swallowfloating         = 1;   /* 1 means swallow floating windows by default */
static const int scalepreview            = 8;   /* Tag preview scaling */
static const unsigned int gappih         = 20;  /* horiz inner gap between windows */
static const unsigned int gappiv         = 10;  /* vert inner gap between windows */
static const unsigned int gappoh         = 10;  /* horiz outer gap between windows and screen edge */
static const unsigned int gappov         = 30;  /* vert outer gap between windows and screen edge */
static const int smartgaps_fact          = 1;   /* gap factor when there is only one client; 0 = no gaps, 3 = 3x outer gaps */
static const char autostartblocksh[]     = "autostart_blocking.sh";
static const char autostartsh[]          = "autostart.sh";
static const char dwmdir[]               = "dwm";
static const char localshare[]           = ".config/suckless";
static const int showbar                 = 1;   /* 0 means no bar */
static const int topbar                  = 1;   /* 0 means bottom bar */
static const int bar_height              = 25;   /* 0 means derive from font, >= 1 explicit height */
static const int vertpad                 = 10;  /* vertical padding of bar */
static const int sidepad                 = 10;  /* horizontal padding of bar */
#define ICONSIZE 20    /* icon size */
#define ICONSPACING 5  /* space between icon and title */
static const char slopspawnstyle[]       = "-t 0 -c 0.92,0.85,0.69,0.3 -o"; /* do NOT define -f (format) here */
static const char slopresizestyle[]      = "-t 0 -c 0.92,0.85,0.69,0.3"; /* do NOT define -f (format) here */
static const int riodraw_borders         = 0;  /* 0 or 1, indicates whether the area drawn using slop includes the window borders */
static const int riodraw_matchpid        = 1;  /* 0 or 1, indicates whether to match the PID of the client that was spawned with riospawn */
/* Status is to be shown on: -1 (all monitors), 0 (a specific monitor by index), 'A' (active monitor) */
static const int statusmon               = -1;
static const char buttonbar[]            = "  ";
static const unsigned int systrayspacing = 2;   /* systray spacing */
static const int showsystray             = 1;   /* 0 means no systray */

/* Indicators: see patch/bar_indicators.h for options */
static int tagindicatortype              = INDICATOR_NONE;
static int tiledindicatortype            = INDICATOR_NONE;
static int floatindicatortype            = INDICATOR_TOP_LEFT_SQUARE;
//static const char *fonts[]          	 = {"Liberation Mono:pixelsize=15:antialias=true:autohint=true","Symbols Nerd Font:style=Bold:antialias=true:pixelsize=17"};
static const char *fonts[]          	 = {
	"Fira Mono:pixelsize=15:antialias=true:autohint=true",
	"Symbols Nerd Font:style=Bold:antialias=true:pixelsize=15",
	"FontAwesome:style=Bold:antialias=true:pixelsize=15",
	"Weather Icons:style=Bold:antialias=true:pixelsize=15"
};
static const char dmenufont[]            = "Caskaydia Mono Nerd Font:size=15:style=Regular:antialias=true:pixelsize=17";
//#include "themes/pywal_dark.h"

static char normfgcolor[]                = "#d5d8ce";
static char normbgcolor[]                = "#0d0a06";
static char normbordercolor[]            = "#0d0a06";
static char normfloatcolor[]             = "#0d0a06";

static char selfgcolor[]                 = "#d5d8ce";
static char selbgcolor[]                 = "#9C8A74";
static char selbordercolor[]             = "#d5d8ce";
static char selfloatcolor[]              = "#9C8A74";

static char titlenormfgcolor[]           = "#d5d8ce";
static char titlenormbgcolor[]           = "#0d0a06";
static char titlenormbordercolor[]       = "#0d0a06";
static char titlenormfloatcolor[]        = "#9C8A74";

static char titleselfgcolor[]            = "#0d0a06";
static char titleselbgcolor[]            = "#9C8A74";
static char titleselbordercolor[]        = "#9C8A74";
static char titleselfloatcolor[]         = "#9C8A74";

static char tagsnormfgcolor[]            = "#d5d8ce";
static char tagsnormbgcolor[]            = "#0d0a06";
static char tagsnormbordercolor[]        = "#0d0a06";
static char tagsnormfloatcolor[]         = "#9C8A74";

static char tagsselfgcolor[]             = "#0d0a06";
static char tagsselbgcolor[]             = "#9C8A74";
static char tagsselbordercolor[]         = "#9C8A74";
static char tagsselfloatcolor[]          = "#9C8A74";

static char hidnormfgcolor[]             = "#B4A799";
static char hidselfgcolor[]              = "#C4B8A5";
static char hidnormbgcolor[]             = "#0d0a06";
static char hidselbgcolor[]              = "#0d0a06";

static char urgfgcolor[]                 = "#0d0a06";
static char urgbgcolor[]                 = "#d5d8ce";
static char urgbordercolor[]             = "#BC9E61";
static char urgfloatcolor[]              = "#9C8A74";

static char c000000[]                    = "#f4bf75";


static char tag1fgcolor[] = "#f92672";
static char tag1bgcolor[] = "#272822";
static char tag2fgcolor[] = "#a6e22e";
static char tag2bgcolor[] = "#272822";
static char tag3fgcolor[] = "#f4bf75";
static char tag3bgcolor[] = "#272822";
static char tag4fgcolor[] = "#66d9ef";
static char tag4bgcolor[] = "#272822";
static char tag5fgcolor[] = "#ae81ff";
static char tag5bgcolor[] = "#272822";
static char tag6fgcolor[] = "#f8f8f2";
static char tag6bgcolor[] = "#272822";
static char tag7fgcolor[] = "#75715e";
static char tag7bgcolor[] = "#272822";
static char tag8fgcolor[] = "#f4bf75";
static char tag8bgcolor[] = "#272822";
static char tag9fgcolor[] = "#a1efe4";
static char tag9bgcolor[] = "#272822";
static char layoutfgcolor[] = "#ae81ff";
static char layoutbgcolor[] = "#272822";

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
	[SchemeTag1]         = { tag1fgcolor,      selbgcolor,      c000000 },
	[SchemeTag2]         = { tag2fgcolor,      tag2bgcolor,      c000000 },
	[SchemeTag3]         = { tag3fgcolor,      tag3bgcolor,	     c000000 },
	[SchemeTag4]         = { tag4fgcolor,      tag4bgcolor,	     c000000 },
	[SchemeTag5]         = { tag5fgcolor,      tag5bgcolor,      c000000 },
	[SchemeTag6]         = { tag6fgcolor,      tag6bgcolor,      c000000 },
	[SchemeTag7]         = { tag7fgcolor,      tag7bgcolor,      c000000 },
	[SchemeTag8]         = { tag8fgcolor,      tag8bgcolor,      c000000 },
	[SchemeTag9]         = { tag9fgcolor,      tag9bgcolor,      c000000 },
	[SchemeLayout]       = { layoutfgcolor,    layoutbgcolor,    c000000 },
};

const char *spcmd1[] = {"st", "-n", "spterm", "-g", "120x34", NULL };
const char *spcmd2[] = {"st", "-n", "spfm", "-g", "144x41", "-e", "ranger", NULL };
const char *spcmd3[] = {"flatpak", "run", "com.bitwarden.desktop", NULL };
const char *spcmd4[] = {"st", "-n", "sppulse", "-g", "100x34", "-e", "pulsemixer", NULL };
const char *spcmd5[] = {"st", "-n", "sptop", "-g", "150x50", "-e", "htop", NULL };
const char *spcmd6[] = {"st", "-n", "spnmtui", "-g", "100x34", "-e", "nmtui", NULL };
const char *spcmd7[] = {"st", "-n", "spncmpcpp", "-g", "100x34", "-e", "ncmpcpp", NULL };
//const char *spcmd8[] = {"/opt/google/chrome/google-chrome", "--profile-directory=Default", "--app-id=hnpfjngllnobngcgfapefoaidbinmjnm", NULL };
const char *spcmd8[] = {"/usr/bin/firefoxpwa", "site", "launch", "01JK1V64QDCVRVVYTEWQH2N5BA",  NULL };
const char *spcmd9[] = {"st", "-n", "spytfzf", "-g", "100x34", "-e", "ytfzf", "--max-threads=4", "--thumbnail-quality=maxres", "--features=hd", "-tl", "--ii=https://yt.securityops.co", NULL };
const char *spcmd10[] = {"qalculate-gtk", NULL };
const char *spcmd11[] = {"st", "-n", "spcalcurse", "-g", "150x50", "-e", "calcurse", NULL };
const char *spcmd12[] = {"st", "-n", "spc3", "-g", "150x50", "-e", "c3", NULL };

static Sp scratchpads[] = {
   /* name          cmd  */
	{"spterm",      		spcmd1},
	{"spranger",    		spcmd2},
	{"bitwarden",   		spcmd3},
	{"sppulse",     		spcmd4},
	{"sptop",       		spcmd5},
	{"spnmtui",     		spcmd6},
	{"spncmpcpp",   		spcmd7},
	{"whatsapp-firefox",	spcmd8},
	{"spytfzf" ,		   	spcmd9},
	{"qalculate-gtk",		spcmd10},
	{"spcalcurse",     		spcmd11},
	{"spc3",        		spcmd12},
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
static char *tagicons[][NUMTAGS] =
{
	[DEFAULT_TAGS]        = { "1", "2", "3", "4", "5", "6", "7", "8", "9" },
	[ALTERNATIVE_TAGS]    = { "A", "B", "C", "D", "E", "F", "G", "H", "I" },
	[ALT_TAGS_DECORATION] = { "<1>", "<2>", "<3>", "<4>", "<5>", "<6>", "<7>", "<8>", "<9>" },
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
	RULE(.class = "st-256color" TERMINAL)
	RULE(.class = "Gimp", .tags = 1 << 4)
	RULE(.class = "Firefox", .tags = 1 << 7)
	RULE(.class = "obsidian",.tags = 1 << 3)
	RULE(.class = "obs",     .tags = 1 << 4)
	RULE(.class = "Soffice", .instance = "soffice", .title = NULL, .monitor = 0, .tags = 0, .isfloating = 0)
	RULE(.class = "Soffice", .instance = "soffice", .title = "Presenting:", .monitor = 1, .tags = 0, .isfloating = 0)
	RULE(.class = "Soffice", .instance = "soffice", .title = "Apresentando", .monitor = 1, .tags = 0, .isfloating = 0)
	RULE(.class = "copyq", .tags = 0, .isfloating = 1)
	RULE(.instance = "spterm", .tags = SPTAG(0), .isfloating = 1 TERMINAL)
	RULE(.instance = "spfm", .tags = SPTAG(1), .isfloating = 1)
	RULE(.instance = "bitwarden",  .tags = SPTAG(2), .isfloating = 1)
	RULE(.instance = "sppulse",  .tags = SPTAG(3), .isfloating = 1)
	RULE(.instance = "sptop",  .tags = SPTAG(4), .isfloating = 1)
	RULE(.instance = "spnmtui" ,  .tags = SPTAG(5), .isfloating = 1)
	RULE(.instance = "spncmpcpp",  .tags = SPTAG(6), .isfloating = 1)
	RULE(.instance = "FFPWA-01JK1V64QDCVRVVYTEWQH2N5BA",  .tags = SPTAG(7), .isfloating = 1)
	RULE(.instance = "spytfzf",	 .tags = SPTAG(8), .isfloating = 1 TERMINAL)
	RULE(.instance = "qalculate-gtk",  .tags = SPTAG(9), .isfloating = 1)
	RULE(.instance = "spcalcurse",  .tags = SPTAG(10), .isfloating = 1)
	RULE(.instance = "spc3",  .tags = SPTAG(11), .isfloating = 1)
	RULE(.class = "updates", .isfloating = 1  TERMINAL)
};

static const MonitorRule monrules[] = {
	/* monitor  tag   layout  mfact  nmaster  showbar  topbar */
	{  1,       -1,   5,      -1,    -1,      -1,      -1     }, // use a different layout for the second monitor
	{  -1,      -1,   0,      -1,    -1,      -1,      -1     }, // default
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
	{ -1,        0,     BAR_ALIGN_NONE,   width_awesomebar,         draw_awesomebar,        click_awesomebar,        NULL,                    "awesomebar" },
};

/* layout(s) */
static const float mfact     = 0.55; /* factor of master area size [0.05..0.95] */
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
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      comboview,      {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      combotag,       {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} }, \
	{ MODKEY|Mod1Mask|ShiftMask,    KEY,      swaptags,       {.ui = 1 << TAG} }, \
	{ MODKEY|Mod1Mask,              KEY,      tagnextmon,     {.ui = 1 << TAG} }, \
	{ MODKEY|Mod1Mask|ControlMask,  KEY,      tagprevmon,     {.ui = 1 << TAG} },

/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *dmenucmd[] = {
	"dmenu_run",
	"-m", dmenumon,
	"-fn", dmenufont,
	"-nb", normbgcolor,
	"-nf", normfgcolor,
	"-sb", selbgcolor,
	"-sf", selfgcolor,
	NULL
};
static const char *termcmd[]  = { "st", NULL };

/* This defines the name of the executable that handles the bar (used for signalling purposes) */
#define STATUSBAR "dwmblocks"
#include "keys.h"

/* signal definitions */
/* signum must be greater than 0 */
/* trigger signals using `xsetroot -name "fsignal:<signame> [<type> <value>]"` */
static const Signal signals[] = {
	/* signum                    function */
	{ "focusstack",              focusstack },
	{ "setmfact",                setmfact },
	{ "togglebar",               togglebar },
	{ "toggletopbar",            toggletopbar },
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
	{ "showhideclient",          showhideclient },
	{ "shifttag",                shifttag },
	{ "shiftview",               shiftview },
	{ "togglesticky",            togglesticky },
	{ "cyclelayout",             cyclelayout },
	{ "toggleviewex",            toggleviewex },
	{ "tag",                     tag },
	{ "tagall",                  tagallex },
	{ "tagex",                   tagex },
	{ "toggletag",               toggletag },
	{ "toggletagex",             toggletagex },
	{ "tagallmon",               tagallmon },
	{ "tagswapmon",              tagswapmon},
	{ "togglehorizontalmax",     togglehorizontalmax },
	{ "toggleverticalmax",       toggleverticalmax },
	{ "togglemax",               togglemax },
	{ "togglescratch",           togglescratch },
	{ "killclient",              killclient },
	{ "winview",                 winview },
	{ "xrdb",                    xrdb },
	{ "tagnextmonex",            tagnextmonex },
	{ "tagprevmonex",            tagprevmonex },
	{ "quit",                    quit },
	{ "setlayout",               setlayout },
	{ "setlayoutex",             setlayoutex },
};
