#ifndef DRACULA_LIGHT_H_
#define DRACULA_LIGHT_H_

static const char *colors[][2] = {
	/*                fg         bg       */
	[SchemeNorm] = { "#282A36", "#F8F8F2" },          // Cor do texto e fundo normal
	[SchemeSel] = { "#F8F8F2", "#FF79C6" },           // Cor do texto e fundo selecionado
	[SchemeBorder] = { "#BBBFC5", "#FF79C6" },        // Cor da borda normal e selecionada
	[SchemeSelHighlight] = { "#FF5555", "#BBBFC5" },  // Cor do texto destacado e fundo da seleção
	[SchemeNormHighlight] = { "#FF5555", "#F8F8F2" }, // Cor do texto destacado normal e fundo
	[SchemeOut] = { "#F8F8F2", "#8BE9FD" },           // Cor do texto e fundo de saída
};

#endif // DRACULA_LIGHT_H_
