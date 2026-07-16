#ifndef VAPORWAVE_LIGHT_H_
#define VAPORWAVE_LIGHT_H_

static const char *colorname[] = {
    /* Vaporwave Light */
    /* 8 normal colors */
    [0] = "#f2f2f2", /* black   */
    [1] = "#ff66cc", /* red     */
    [2] = "#33ffcc", /* green   */
    [3] = "#ffff66", /* yellow  */
    [4] = "#3399ff", /* blue    */
    [5] = "#cc33ff", /* magenta */
    [6] = "#00cccc", /* cyan    */
    [7] = "#4a4a6a", /* white   */

    /* 8 bright colors */
    [8]  = "#b3b3cc", /* black   */
    [9]  = "#ff66cc", /* red     */
    [10] = "#33ffcc", /* green   */
    [11] = "#ffff66", /* yellow  */
    [12] = "#3399ff", /* blue    */
    [13] = "#cc33ff", /* magenta */
    [14] = "#00cccc", /* cyan    */
    [15] = "#4a4a6a", /* white   */

    /* special colors */
    [256] = "#ffffff", /* background */
    [257] = "#4a4a6a", /* foreground */
};

unsigned int defaultfg = 257; /* Foreground color */
unsigned int defaultbg = 256; /* Background color */
unsigned int defaultcs = 257; /* Cursor color */
unsigned int defaultrcs = 257; /* Reverse cursor color */

#endif // VAPORWAVE_LIGHT_H_
