#ifndef NORDIC_DARK_H_
#define NORDIC_DARK_H_

static const char *colorname[] = {
	/* Nordic Dark */
  /* 8 normal colors */
	"#2E3440", /* black   */
	"#BF616A", /* red     */
	"#A3BE8C", /* green   */
	"#EBCB8B", /* yellow  */
	"#81A1C1", /* blue    */
	"#B48EAD", /* magenta */
	"#88C0D0", /* cyan    */
	"#E5E9F0", /* white   */

  /* 8 bright colors */
	"#4C566A", /* black   */
	"#BF616A", /* red     */
	"#A3BE8C", /* green   */
	"#EBCB8B", /* yellow  */
	"#81A1C1", /* blue    */
	"#B48EAD", /* magenta */
	"#8FBCBB", /* cyan    */
	"#ECEFF4", /* white   */
};

unsigned int defaultfg = 15;
unsigned int defaultbg = 0;
unsigned int defaultcs = 15;
unsigned int defaultrcs = 257;

#endif // NORDIC_DARK_H_
