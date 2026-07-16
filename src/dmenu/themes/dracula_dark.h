#ifndef DRACULA_DARK_H_
#define DRACULA_DARK_H_

static const char *colors[][2] = {
	/*                fg         bg       */
	[SchemeNorm] = { "#F8F8F2", "#282A36" },          // Cor do texto e fundo normal
	[SchemeSel] = { "#282A36", "#6272A4" },           // Cor do texto e fundo selecionado
	[SchemeBorder] = { "#44475A", "#6272A4" },        // Cor da borda normal e selecionada
	[SchemeSelHighlight] = { "#FFB86C", "#44475A" },  // Cor do texto destacado e fundo da seleção
	[SchemeNormHighlight] = { "#FFB86C", "#282A36" }, // Cor do texto destacado normal e fundo
	[SchemeOut] = { "#282A36", "#8BE9FD" },           // Cor do texto e fundo de saída
};

unsigned int defaultitalic = 7;
unsigned int defaultunderline = 7;
#endif // DRACULA_DARK_H_
