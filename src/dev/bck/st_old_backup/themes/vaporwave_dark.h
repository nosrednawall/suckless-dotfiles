#ifndef VAPORWAVE_DARK_H_
#define VAPORWAVE_DARK_H_

static const char *colorname[] = {
    /* Vaporwave Dark */
    /* 8 normal colors */
    [0] = "#1a1a2e", /* black   */
    [1] = "#ff3399", /* red     */
    [2] = "#00ffcc", /* green   */
    [3] = "#ffff66", /* yellow  */
    [4] = "#3399ff", /* blue    */
    [5] = "#cc33ff", /* magenta */
    [6] = "#00ccff", /* cyan    */
    [7] = "#e0e0e0", /* white   */

    /* 8 bright colors */
    [8]  = "#4a4a6a", /* black   */
    [9]  = "#ff3399", /* red     */
    [10] = "#00ffcc", /* green   */
    [11] = "#ffff66", /* yellow  */
    [12] = "#3399ff", /* blue    */
    [13] = "#cc33ff", /* magenta */
    [14] = "#00ccff", /* cyan    */
    [15] = "#ffffff", /* white   */

    /* special colors */
    [256] = "#0d0d25", /* background */
    [257] = "#e0e0e0", /* foreground */
};

unsigned int defaultfg = 257; /* Foreground color */
unsigned int defaultbg = 256; /* Background color */
unsigned int defaultcs = 257; /* Cursor color */
unsigned int defaultrcs = 257; /* Reverse cursor color */

#endif // VAPORWAVE_DARK_H_
