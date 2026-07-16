#define PATH(name)                      "/home/anderson/.dotfiles/.config/suckless/dwmblocks/scripts/"name

//Modify this file to change what commands output to your statusbar, and recompile using the make command.
static const Block blocks[] = {
	/*Icon*/	/*Command*/ /*Update Interval*/	/*Update Signal*/
	{"", PATH("sb-music"), 		10, 					1},
	{"", PATH("sb-update"), 		60, 					2},
	{"", PATH("sb-loadavg"), 		10, 					3},
	{"", PATH("sb-memory"), 		10, 					4},
	{"", PATH("sb-disk"), 			10, 					5},
	{"", PATH("sb-vpn"), 			10, 					16},
	{"", PATH("sb-wifi"), 			10, 					6},
	{"", PATH("sb-ethernet"), 		10, 					7},
    {"", PATH("sb-brightness"), 	0, 					8},
    {"", PATH("sb-volume"), 		0, 					9},
    {"", PATH("sb-mic"), 			0, 					10},
    {"", PATH("sb-record"), 		10, 					11},
    {"", PATH("sb-keyboard"), 		0, 					12},
    {"", PATH("sb-battery"), 		30, 					13},
    {"", PATH("sb-date"), 			3600, 					14},
    {"", PATH("sb-hour"), 			30, 					15},
};

//sets delimiter between status commands. NULL character ('\0') means no delimiter.
static char delim[] = "\0";
static unsigned int delimLen = 5;
