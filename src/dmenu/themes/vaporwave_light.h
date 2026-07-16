#ifndef VAPORWAVE_LIGHT_H_
#define VAPORWAVE_LIGHT_H_

static const char *colors[][2] = {
	/*                fg         bg       */
	[SchemeNorm] = { "#4a4a6a", "#f2f2f2" },          // Cor do texto e fundo normal
	[SchemeSel] = { "#f2f2f2", "#ff66cc" },           // Cor do texto e fundo selecionado
	[SchemeBorder] = { "#b3b3cc", "#ff66cc" },        // Cor da borda normal e selecionada
	[SchemeSelHighlight] = { "#00cccc", "#b3b3cc" },  // Cor do texto destacado e fundo da seleção
	[SchemeNormHighlight] = { "#00cccc", "#f2f2f2" }, // Cor do texto destacado normal e fundo
	[SchemeOut] = { "#f2f2f2", "#ff3399" },           // Cor do texto e fundo de saída
};

unsigned int defaultitalic = 7;
unsigned int defaultunderline = 7;
#endif // VAPORWAVE_LIGHT_H_
