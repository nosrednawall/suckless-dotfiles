const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#1f1b0d", /* black   */
  [1] = "#7A846C", /* red     */
  [2] = "#8C8974", /* green   */
  [3] = "#95948B", /* yellow  */
  [4] = "#A3A69E", /* blue    */
  [5] = "#ACB4B3", /* magenta */
  [6] = "#C2C3B8", /* cyan    */
  [7] = "#9b9890", /* white   */

  /* 8 bright colors */
  [8]  = "#716c5c",  /* black   */
  [9]  = "#a2c170",  /* red     */
  [10] = "#c5bc78", /* green   */
  [11] = "#ccc38a", /* yellow  */
  [12] = "#c2d49d", /* blue    */
  [13] = "#abdada", /* magenta */
  [14] = "#dce1b9", /* cyan    */
  [15] = "#c7c6c2", /* white   */

  /* special colors */
  [256] = "#1f1b0d", /* background */
  [257] = "#c7c6c2", /* foreground */
  [258] = "#c7c6c2",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
