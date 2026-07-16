const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#1f0d0d", /* black   */
  [1] = "#9d8133", /* red     */
  [2] = "#484774", /* green   */
  [3] = "#6c5a6d", /* yellow  */
  [4] = "#50759d", /* blue    */
  [5] = "#88818a", /* magenta */
  [6] = "#baa17f", /* cyan    */
  [7] = "#9b9090", /* white   */

  /* 8 bright colors */
  [8]  = "#715c5c",  /* black   */
  [9]  = "#D2AC45",  /* red     */
  [10] = "#615F9B", /* green   */
  [11] = "#917892", /* yellow  */
  [12] = "#6B9DD2", /* blue    */
  [13] = "#B6ADB9", /* magenta */
  [14] = "#F9D7AA", /* cyan    */
  [15] = "#c7c2c2", /* white   */

  /* special colors */
  [256] = "#1f0d0d", /* background */
  [257] = "#c7c2c2", /* foreground */
  [258] = "#c7c2c2",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
