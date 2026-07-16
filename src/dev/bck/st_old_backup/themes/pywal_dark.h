const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#1e1e1e", /* black   */
  [1] = "#6f6955", /* red     */
  [2] = "#78755a", /* green   */
  [3] = "#77785a", /* yellow  */
  [4] = "#7a7c5d", /* blue    */
  [5] = "#727963", /* magenta */
  [6] = "#848e72", /* cyan    */
  [7] = "#9e9393", /* white   */

  /* 8 bright colors */
  [8]  = "#766161",  /* black   */
  [9]  = "#958D72",  /* red     */
  [10] = "#A19D79", /* green   */
  [11] = "#9FA179", /* yellow  */
  [12] = "#A3A67D", /* blue    */
  [13] = "#99A285", /* magenta */
  [14] = "#B0BE99", /* cyan    */
  [15] = "#c6c6c6", /* white   */

  /* special colors */
  [256] = "#1e1e1e", /* background */
  [257] = "#c6c6c6", /* foreground */
  [258] = "#c6c6c6",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
