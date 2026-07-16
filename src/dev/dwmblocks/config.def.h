#define PATH(name) "/home/anderson/.config/suckless/scripts/dwmblocks/"name

//Modify this file to change what commands output to your statusbar, and recompile using the make command.
static const Block blocks[] = {
	/*Icon*/	/*Command*/ /*Update Interval*/	/*Update Signal*/
	{"", PATH("sb-mpd"), 		     0, 					1},
	{"", PATH("sb-update"), 		3600, 					2},
	{"", PATH("sb-loadavg"), 		60, 					3},
	{"", PATH("sb-memory"), 		60, 					4},
	{"", PATH("sb-disk"), 			60, 					5},
	{"", PATH("sb-vpn"), 			60, 					16},
	{"", PATH("sb-wifi"), 			60, 					6},
	{"", PATH("sb-ethernet"), 		60, 					7},
    {"", PATH("sb-brightness"), 	0, 					    8},
    {"", PATH("sb-volume"), 		0, 					    9},
    {"", PATH("sb-mic"), 			0, 					    10},
    {"", PATH("sb-record"), 		10, 					11},
    {"", PATH("sb-keyboard"), 		0, 					    12},
    {"", PATH("sb-battery"), 		30, 					13},
    {"", PATH("sb-date"), 			3600, 					14},
    {"", PATH("sb-hour"), 			30, 					15},
};

//sets delimiter between status commands. NULL character ('\0') means no delimiter.
static char delim[] = "\0";
static unsigned int delimLen = 0;
