#ifndef NORDIC_LIGHT_H_
#define NORDIC_LIGHT_H_

static const char *colors[][2] = {
	/*                fg         bg       */
	[SchemeNorm] = { "#4C566A", "#ECEFF4" },
	[SchemeSel] = { "#ECEFF4", "#81A1C1" },
	[SchemeBorder] = { "#D8DEE9", "#81A1C1" },
	[SchemeSelHighlight] = { "#5E81AC", "#D8DEE9" },
	[SchemeNormHighlight] = { "#5E81AC", "#ECEFF4" },
	[SchemeOut] = { "#ECEFF4", "#88C0D0" },
};

#endif // NORDIC_LIGHT_H_
