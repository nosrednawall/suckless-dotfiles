#ifndef VAPORWAVE_DARK_H_
#define VAPORWAVE_DARK_H_

static const char *colors[][2] = {
	/*                fg         bg       */
	[SchemeNorm] = { "#e0e0e0", "#1a1a2e" },          // Cor do texto e fundo normal
	[SchemeSel] = { "#1a1a2e", "#ff66cc" },           // Cor do texto e fundo selecionado
	[SchemeBorder] = { "#4a4a6a", "#ff66cc" },        // Cor da borda normal e selecionada
	[SchemeSelHighlight] = { "#00ffff", "#4a4a6a" },  // Cor do texto destacado e fundo da seleção
	[SchemeNormHighlight] = { "#00ffff", "#1a1a2e" }, // Cor do texto destacado normal e fundo
	[SchemeOut] = { "#1a1a2e", "#00cccc" },           // Cor do texto e fundo de saída
};

unsigned int defaultitalic = 7;
unsigned int defaultunderline = 7;
#endif // VAPORWAVE_DARK_H_
