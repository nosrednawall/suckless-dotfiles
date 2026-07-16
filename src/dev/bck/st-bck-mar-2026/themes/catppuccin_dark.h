/* Terminal colors (16 first used in escape sequence) */
static const char *colorname[] = {
	/* 8 normal colors */
	"#51576D", // Cinza escuro
	"#E78284", // Vermelho suave
	"#A6D189", // Verde suave
	"#E5C890", // Amarelo suave
	"#8CAAEE", // Azul suave
	"#F4B8E4", // Rosa suave
	"#81C8BE", // Ciano suave
	"#B5BFE2", // Azul acinzentado

	/* 8 bright colors */
	"#626880", // Cinza médio
	"#E78284", // Vermelho suave
	"#A6D189", // Verde suave
	"#E5C890", // Amarelo suave
	"#8CAAEE", // Azul suave
	"#F4B8E4", // Rosa suave
	"#81C8BE", // Ciano suave
	"#A5ADCE", // Azul claro

	[256] = "#CDD6F4", /* default foreground colour */
	[257] = "#303446", /* default background colour */
	[258] = "#F2D5CF", /* Cursor color */
};

/*
 * foreground, background, cursor, reverse cursor
 */
unsigned int defaultfg = 256;
unsigned int defaultbg = 257;
unsigned int defaultcs = 258;
static unsigned int defaultrcs = 258;
