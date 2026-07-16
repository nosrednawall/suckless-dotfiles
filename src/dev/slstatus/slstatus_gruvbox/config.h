/* See LICENSE file for copyright and license details. */

/* interval between updates (in ms) */
const unsigned int interval = 1000;

/* text to show if no value can be retrieved */
static const char unknown_str[] = "";

/* maximum output string length */
#define MAXLEN 2048

static const struct arg args[] = {
	/* function                     format						argument */
	{ run_command,		"^b#282828^^c#89B482^%s ",				"bash ~/.local/bin/music_status_bar.sh"},
	//{ run_command,	"^b#282828^^c#89B482^%s ",				"bash ~/.local/bin/sl-wttr.sh"},
	{ run_command,		"^b#282828^^c#89B482^%s ",				"bash ~/.local/bin/cpu_status.sh"},
	//{ cpu_perc,		"^b#282828^^c#89B482^ ^b#282828^^c#d4be98^%s󰏰 ",	NULL},
	//{ run_command,	"^b#282828^^c#89B482^%s",				"sensors | awk '/edge/ {print$2}' | sed 's/+//'"},
	{ ram_perc,			"^b#282828^^c#B8bb26^ ^b#282828^^c#d4be98^%s󰏰 ",	NULL},
	{ disk_perc,		"^b#282828^^c#45858B^󰋊 ^b#282828^^c#d4be98^%s󰏰 ",	"/" },
	{ wifi_essid,		"^b#282828^^c#fabd2f^ ^b#282828^^c#d4be98^%s",		"wlp5s0" },
	{ wifi_perc,		"^b#282828^^c#d4be98^%s󰏰 ",				"wlp5s0" },
	//{ netspeed_rx,	"^b#282828^^c#fabd2f^  ^b#282828^^c#d4be98^%s",	"wlp5s0" },
	//{ netspeed_tx,	"^b#282828^^c#fabd2f^  ^b#282828^^c#d4be98^%s",	"wlp5s0" },
	//{ battery_perc,	"^b#282828^^c#b16286^  ^b#282828^^c#d4be98^%s󰏰 ",	"BAT1" },
	{ run_command,		"%s",							"bash ~/.local/bin/battery_status.sh" },
	{ run_command,		"^b#282828^^c#89B482^%s ",				"bash ~/.local/bin/volume_icon.sh" },
	{ run_command,		"^b#282828^^c#89B482^󰌌 ^b#282828^^c#d4be98^%s ",	"setxkbmap -query | grep layout | awk '{print$2}'"},
	{ run_command,		"^b#282828^^c#89B482^ ^b#282828^^c#d4be98^%s ",	"date +'%d/%m/%Y'" },
	{ run_command,		"^b#282828^^c#89B482^󰥔 ^b#282828^^c#d4be98^%s",	"date +'%H:%M'"},
};

/*
 * function            description                     argument (example)
 *
 * battery_perc        battery percentage              battery name (BAT0)
 *                                                     NULL on OpenBSD/FreeBSD
 * battery_remaining   battery remaining HH:MM         battery name (BAT0)
 *                                                     NULL on OpenBSD/FreeBSD
 * battery_state       battery charging state          battery name (BAT0)
 *                                                     NULL on OpenBSD/FreeBSD
 * cat                 read arbitrary file             path
 * cpu_freq            cpu frequency in MHz            NULL
 * cpu_perc            cpu usage in percent            NULL
 * datetime            date and time                   format string (%F %T)
 * disk_free           free disk space in GB           mountpoint path (/)
 * disk_perc           disk usage in percent           mountpoint path (/)
 * disk_total          total disk space in GB          mountpoint path (/)
 * disk_used           used disk space in GB           mountpoint path (/)
 * entropy             available entropy               NULL
 * gid                 GID of current user             NULL
 * hostname            hostname                        NULL
 * ipv4                IPv4 address                    interface name (eth0)
 * ipv6                IPv6 address                    interface name (eth0)
 * kernel_release      `uname -r`                      NULL
 * keyboard_indicators caps/num lock indicators        format string (c?n?)
 *                                                     see keyboard_indicators.c
 * keymap              layout (variant) of current     NULL
 *                     keymap
 * load_avg            load average                    NULL
 * netspeed_rx         receive network speed           interface name (wlan0)
 * netspeed_tx         transfer network speed          interface name (wlan0)
 * num_files           number of files in a directory  path
 *                                                     (/home/foo/Inbox/cur)
 * ram_free            free memory in GB               NULL
 * ram_perc            memory usage in percent         NULL
 * ram_total           total memory size in GB         NULL
 * ram_used            used memory in GB               NULL
 * run_command         custom shell command            command (echo foo)
 * swap_free           free swap in GB                 NULL
 * swap_perc           swap usage in percent           NULL
 * swap_total          total swap size in GB           NULL
 * swap_used           used swap in GB                 NULL
 * temp                temperature in degree celsius   sensor file
 *                                                     (/sys/class/thermal/...)
 *                                                     NULL on OpenBSD
 *                                                     thermal zone on FreeBSD
 *                                                     (tz0, tz1, etc.)
 * uid                 UID of current user             NULL
 * uptime              system uptime                   NULL
 * username            username of current user        NULL
 * vol_perc            OSS/ALSA volume in percent      mixer file (/dev/mixer)
 *                                                     NULL on OpenBSD/FreeBSD
 * wifi_essid          WiFi ESSID                      interface name (wlan0)
 * wifi_perc           WiFi signal in percent          interface name (wlan0)
 */


/*

static const char c_bg[]          = "#222121";
static const char c_fg[]          = "#dfbf8e";
static const char c_white[]       = "#fbf1c7";
static const char c_red[]         = "#cc241d";
static const char c_green[]       = "#B8bb26";
static const char c_yellow[]      = "#fabd2f";
static const char c_blue[]        = "#45858B";
static const char c_purple[]      = "#b16286";
static const char c_aqua[]        = "#689d6a";
static const char c_gray[]        = "#a89984";
static const char c_orange[]      = "#d65d0e";
static const char c_aqua2[]       = "#427b58";

static const char icone_color[] = "^b#282828^^c#629464^";
static const char texto_color[] = "^b#282828^^c^#dfbf8e";

static const struct arg args[] = {
	{ run_command,		"^b#282828^^c#629464^ %s",			"bash ~/.local/bin/music_status_bar.sh"},
	{ run_command,		"^b#282828^^c#b16286^ %s",			"bash ~/.local/bin/sl-wttr.sh"},
	{ run_command,		"^b#282828^^c#fb4934^ %s",			"bash ~/.local/bin/cpu_status.sh"},
	//{ cpu_perc,		"^b#282828^^c#fb4934^ %.3s󰏰 ",			NULL},
	//{ run_command,	"^b#282828^^c#fb4934^%s",			"sensors | awk '/edge/ {print$2}' | sed 's/+//'"},
	{ ram_perc,		"^b#282828^^c#B8bb26^  %s󰏰 ",			NULL},
	{ disk_perc,		"^b#282828^^c#45858B^ 󰋊 %s󰏰 ",			"/" },
	{ wifi_essid,		"^b#282828^^c#fabd2f^  %s",			"wlan0" },
	{ wifi_perc,		"^b#282828^^c#fabd2f^ %s󰏰 ",			"wlan0" },
	//{ netspeed_rx,	"^b#282828^^c#fabd2f^   %s",			"wlan0" },
	//{ netspeed_tx,	"^b#282828^^c#fabd2f^   %s",			"wlan0" },
	//{ battery_perc,	"^b#282828^^c#b16286^  %s󰏰 ",			"BAT1" },
	{ run_command,		"%s",						"bash ~/.local/bin/battery_status.sh" },
	{ run_command,		"^b#282828^^c#dfbf8e^ %s",			"bash ~/.local/bin/volume_icon.sh" },
	{ run_command,		"^b#282828^^c#45858b^ 󰌌 %s",			"setxkbmap -query | grep layout | awk '{print$2}'"},
	{ run_command,		"^b#282828^^c#d65d0e^  %s",			"date +'%a %d %b %Y'" },
	{ run_command,		"^b#282828^^c#689d6a^ 󰥔 %s ",			"date +'%H:%M'"},
};




static const struct arg args[] = {
	{ run_command,		"^b#282828^^c#89B482^ %s",				"bash ~/.local/bin/music_status_bar.sh"},
	{ run_command,		"^b#282828^^c#89B482^ %s",				"bash ~/.local/bin/sl-wttr.sh"},
	{ run_command,		"^b#282828^^c#89B482^ %s",				"bash ~/.local/bin/cpu_status.sh"},
	//{ cpu_perc,		"^b#282828^^c#89B482^ ^b#282828^^c#dfbf8e^%s󰏰 ",	NULL},
	//{ run_command,	"^b#282828^^c#89B482^%s",				"sensors | awk '/edge/ {print$2}' | sed 's/+//'"},
	{ ram_perc,		"^b#282828^^c#89B482^  ^b#282828^^c#dfbf8e^%s󰏰 ",	NULL},
	{ disk_perc,		"^b#282828^^c#89B482^ 󰋊 ^b#282828^^c#dfbf8e^%s󰏰 ",	"/" },
	{ wifi_essid,		"^b#282828^^c#89B482^  ^b#282828^^c#dfbf8e^%s",	"wlan0" },
	{ wifi_perc,		"^b#282828^^c#dfbf8e^ %s󰏰 ",				"wlan0" },
	//{ netspeed_rx,	"^b#282828^^c#89B482^  ^b#282828^^c#dfbf8e^%s",	"wlan0" },
	//{ netspeed_tx,	"^b#282828^^c#89B482^  ^b#282828^^c#dfbf8e^%s",	"wlan0" },
	//{ battery_perc,	"^b#282828^^c#89B482^  ^b#282828^^c#dfbf8e^%s󰏰 ",	"BAT1" },
	{ run_command,		"%s",							"bash ~/.local/bin/battery_status.sh" },
	{ run_command,		"^b#282828^^c#89B482^ %s",				"bash ~/.local/bin/volume_icon.sh" },
	{ run_command,		"^b#282828^^c#89B482^ 󰌌 ^b#282828^^c#dfbf8e^%s",	"setxkbmap -query | grep layout | awk '{print$2}'"},
	{ run_command,		"^b#282828^^c#89B482^  ^b#282828^^c#dfbf8e^%s",	"date +'%a %d %b %Y'" },
	{ run_command,		"^b#282828^^c#89B482^ 󰥔 ^b#282828^^c#dfbf8e^%s ",	"date +'%H:%M'"},
};


 */
