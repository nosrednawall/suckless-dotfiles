#ifndef DRACULA_LIGHT_H_
#define DRACULA_LIGHT_H_

static const char *colorname[] = {
	/* Alucard Light */
    /* 8 normal colors */
    [0] = "#ffffff", /* black   */
    [1] = "#ff5555", /* red     */
    [2] = "#50fa7b", /* green   */
    [3] = "#f1fa8c", /* yellow  */
    [4] = "#6272a4", /* blue    */
    [5] = "#bd93f9", /* magenta */
    [6] = "#8be9fd", /* cyan    */
    [7] = "#282a36", /* white   */

    /* 8 bright colors */
    [8]  = "#bbbbbb", /* black   */
    [9]  = "#ff5555", /* red     */
    [10] = "#50fa7b", /* green   */
    [11] = "#f1fa8c", /* yellow  */
    [12] = "#6272a4", /* blue    */
    [13] = "#bd93f9", /* magenta */
    [14] = "#8be9fd", /* cyan    */
    [15] = "#000000", /* white   */

    /* special colors */
    [256] = "#f8f8f2", /* background */
    [257] = "#282a36", /* foreground */
};

unsigned int defaultfg = 257; /* Foreground */
unsigned int defaultbg = 256; /* Background */
unsigned int defaultcs = 257; /* Cursor color */
unsigned int defaultrcs = 257; /* Reverse cursor color */

#endif // DRACULA_LIGHT_H_
