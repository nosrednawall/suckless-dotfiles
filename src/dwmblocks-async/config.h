#define CONFIG_H

// String used to delimit block outputs in the status.
#define DELIMITER ""

// Maximum number of Unicode characters that a block can output.
#define MAX_BLOCK_OUTPUT_LENGTH 180

// Control whether blocks are clickable.
#define CLICKABLE_BLOCKS 1

// Control whether a leading delimiter should be prepended to the status.
#define LEADING_DELIMITER 0

// Control whether a trailing delimiter should be appended to the status.
#define TRAILING_DELIMITER 0

// Path for scripts - now using /usr/local/bin
#define SCRIPT_PATH(name) "~/.config/suckless/scripts/dwmblocks/"name

// Define blocks for the status feed as X(icon, cmd, interval, signal).
#define BLOCKS(X)                                   \
    X("", SCRIPT_PATH("sb-potato-c"),      1, 19)   \
    X("", SCRIPT_PATH("sb-players"),       1, 18)   \
    X("", SCRIPT_PATH("sb-weather"),     600, 17)   \
    X("", SCRIPT_PATH("sb-update"),     6000, 16)   \
    X("", SCRIPT_PATH("sb-loadavg"),      10, 15)   \
    X("", SCRIPT_PATH("sb-memory"),       10, 14)   \
    X("", SCRIPT_PATH("sb-disk"),         10, 13)   \
    X("", SCRIPT_PATH("sb-vpn"),          10, 12)   \
    X("", SCRIPT_PATH("sb-wifi"),         10, 11)   \
    X("", SCRIPT_PATH("sb-ethernet"),     10, 10)   \
    X("", SCRIPT_PATH("sb-brightness"),    0,  9)   \
    X("", SCRIPT_PATH("sb-volume"),      600,  8)   \
    X("", SCRIPT_PATH("sb-mic"),         600,  7)   \
    X("", SCRIPT_PATH("sb-record"),      100,  6)   \
    X("", SCRIPT_PATH("sb-keyboard"),      1,  5)   \
    X("", SCRIPT_PATH("sb-battery"),      30,  4)   \
    X("", SCRIPT_PATH("sb-moon"),       6000,  3)   \
    X("", SCRIPT_PATH("sb-date"),        600,  2)   \
    X("", SCRIPT_PATH("sb-hour"),          1,  1)

/*
Comando para atualizar todos os blocks de uma vez
kill -10 $(pidof dwmblocks)


Comandos para atualizar blocos específicos:
kill -30 $(pidof dwmblocks)  // atualiza o bloco 2 (hora)
kill -32 $(pidof dwmblocks)  // atualiza o bloco 3 (lua)

Sinais correspondentes:

Script          VP    ID   =  Numero pidof

sb-potato-c     34 +  19   =     52
sb-players      34 +  18   =     51
sb-weather      34 +  17   =     50
sb-update       34 +  16   =     49
sb-loadavg      34 +  15   =     48
sb-memory       34 +  14   =     47
sb-disk         34 +  13   =     46
sb-vpn          34 +  12   =     45
sb-wifi         34 +  11   =     44
sb-ethernet     34 +  10   =     43
sb-brightness   34 +   9   =     42
sb-volume       34 +   8   =     41
sb-mic          34 +   7   =     40
sb-record       34 +   6   =     40
sb-keyboard     34 +   5   =     39
sb-battery      34 +   4   =     38
sb-moon         34 +   3   =     37
sb-date         34 +   2   =     36
sb-hour         34 +   1   =     35

*/
