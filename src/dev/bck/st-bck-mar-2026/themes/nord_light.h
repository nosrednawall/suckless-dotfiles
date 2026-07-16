#ifndef NORDIC_LIGHT_H_
#define NORDIC_LIGHT_H_

static const char *colorname[] = {
	/* Nordic Light */
  /* 8 normal colors */
	"#ECEFF4", /* black   */
	"#BF616A", /* red     */
	"#A3BE8C", /* green   */
	"#EBCB8B", /* yellow  */
	"#81A1C1", /* blue    */
	"#B48EAD", /* magenta */
	"#88C0D0", /* cyan    */
	"#4C566A", /* white   */

  /* 8 bright colors */
	"#D8DEE9", /* black   */
	"#BF616A", /* red     */
	"#A3BE8C", /* green   */
	"#EBCB8B", /* yellow  */
	"#81A1C1", /* blue    */
	"#B48EAD", /* magenta */
	"#8FBCBB", /* cyan    */
	"#2E3440", /* white   */
};

unsigned int defaultfg = 0;
unsigned int defaultbg = 15;
unsigned int defaultcs = 0;
unsigned int defaultrcs = 257;

#endif // NORDIC_LIGHT_H_
