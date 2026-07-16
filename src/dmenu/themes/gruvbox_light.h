static const char *colors[][2] = {
    /*                fg         bg       */
    [SchemeNorm]          = { "#3c3836", "#fbf1c7" }, // Texto normal e fundo
    [SchemeSel]           = { "#fbf1c7", "#689d6a" }, // Texto selecionado e fundo
    [SchemeBorder]        = { "#d5c4a1", "#458588" }, // Cor da borda e cor de fundo quando a borda está ativa
    [SchemeSelHighlight]  = { "#d79921", "#fbf1c7" }, // Cor do texto selecionado e destaque de fundo quando selecionado
    [SchemeNormHighlight] = { "#d79921", "#fbf1c7" }, // Cor do texto normal e destaque de fundo quando não selecionado
    [SchemeOut]           = { "#282828", "#8ec07c" }, // Cor do texto e fundo para itens que não estão na lista atual
};
