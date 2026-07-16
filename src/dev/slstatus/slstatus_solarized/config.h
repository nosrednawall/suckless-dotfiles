/* See LICENSE file for copyright and license details. */
#define SCRIPTS(name)                      "/home/anderson/.dotfiles/.config/suckless/slstatus/slstatus_solarized/scripts/"name
/* interval between updates (in ms) */
const unsigned int interval = 1000;

/* text to show if no value can be retrieved */
static const char unknown_str[] = "";

/* maximum output string length */
#define MAXLEN 1000

static const struct arg args[] = {
	/* function                     format						argument */
	{ run_command,	    			"%s",				SCRIPTS("music_status_bar.sh") },
	//{ run_command,					"%s",			  	SCRIPTS("pomodoro_status.sh") },
	//{ run_command,					"%s  ",				SCRIPTS("update_status.sh") },
	{ run_command,					"%s  ",				SCRIPTS("cpu_status.sh") },
	{ ram_perc,			"^c#859900^ ^c#93a1a1^%s󰏰  ",NULL},
	{ disk_perc,		"^c#45858B^󰋊 ^c#93a1a1^%s󰏰  ","/" },

	//{ wifi_essid,		"^c#b58900^ ^c#93a1a1^%s",  "wlp5s0" },
	//{ ipv4, " %s  ", "wlp5s0" },
	//{ wifi_perc,		"^c#93a1a1^ %s󰏰 ",				"wlp5s0" },
//	{ \netspeed_rx,	    "^c#b58900^  ^c#93a1a1^%s",	"wlp5s0" },
//	{ netspeed_tx,	    "^c#b58900^  ^c#93a1a1^%s",	"wlp5s0" },
	//{ battery_perc,	"^c#d33682^  ^c#93a1a1^%s󰏰 ", "BAT1" },
	{ run_command,		"%s",							 SCRIPTS("wifi_status.sh") },
	{ run_command,		"%s",							 SCRIPTS("ethernet_status.sh") },
	//{ ipv4, 			"%s", 							"enp4s0" },
	{ run_command,					"%s",				SCRIPTS("battery_status.sh") },
	{ run_command,					"%s  ",				SCRIPTS("volume_icon.sh") },
	{ run_command,					"%s  ",				SCRIPTS("keyboard_status.sh")},
	{ run_command,		"^c#2aa198^ ^c#93a1a1^%s  ",	"date +'%d/%m/%Y'" },
	{ run_command,		"^c#2aa198^󰥔 ^c#93a1a1^%s ",	"date +'%H:%M'"},

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
