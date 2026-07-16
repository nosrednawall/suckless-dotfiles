#!/usr/bin/env bash

# Script de instalação do Kanri
# Autor: Assistente
# Descrição: Instala o Kanri (aplicativo Kanban) a partir do AppImage

# Cores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}   Instalador do Kanri v0.8.2   ${NC}"
echo -e "${BLUE}================================${NC}"

# URL do download
KANRI_URL="https://github.com/kanriapp/kanri/releases/download/app-v0.8.2/kanri_0.8.2_amd64.AppImage"
KANRI_DIR="$HOME/.local/share/kanri"
KANRI_APPIMAGE="$KANRI_DIR/kanri.AppImage"
DESKTOP_FILE="$HOME/.local/share/applications/kanri.desktop"
ICON_URL="https://raw.githubusercontent.com/kanriapp/website/refs/heads/main/src/assets/kanri_logo.svg"
ICON_PATH="$KANRI_DIR/kanri-icon.png"

# Cria diretório de instalação
echo -e "${BLUE}Criando diretório de instalação...${NC}"
mkdir -p "$KANRI_DIR"

# Baixa o AppImage
echo -e "${BLUE}Baixando Kanri AppImage...${NC}"
wget -O "$KANRI_APPIMAGE" "$KANRI_URL"

if [ $? -ne 0 ]; then
    echo -e "${RED}Erro ao baixar o Kanri. Verifique sua conexão com internet.${NC}"
    exit 1
fi

# Torna o AppImage executável
echo -e "${BLUE}Tornando o arquivo executável...${NC}"
chmod +x "$KANRI_APPIMAGE"

# Baixa ícone (opcional, usa um ícone padrão se falhar)
echo -e "${BLUE}Baixando ícone...${NC}"
wget -O "$ICON_PATH" "$ICON_URL" 2>/dev/null || {
    echo -e "${RED}Não foi possível baixar o ícone oficial. Usando ícone padrão.${NC}"
    # Cria um ícone simples em SVG se não conseguir baixar
    cat > "$ICON_PATH" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <rect width="100" height="100" fill="#4A90E2"/>
  <text x="50" y="65" font-size="40" text-anchor="middle" fill="white" font-family="Arial">K</text>
</svg>
EOF
}

# Cria o arquivo .desktop
echo -e "${BLUE}Criando atalho no menu de aplicativos...${NC}"
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Name=Kanri
Comment=Modern Kanban application for personal use
Exec=$KANRI_APPIMAGE
Icon=$ICON_PATH
Terminal=false
Type=Application
Categories=Office;ProjectManagement;Utility;
StartupWMClass=Kanri
Keywords=kanban;task;management;
EOF

# Atualiza o cache do desktop
echo -e "${BLUE}Atualizando cache de aplicativos...${NC}"
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}Instalação concluída com sucesso!${NC}"
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}O Kanri foi instalado em: $KANRI_APPIMAGE${NC}"
echo -e "${GREEN}Você pode encontrar o Kanri no menu de aplicativos.${NC}"
echo -e "${GREEN}Para executar agora, digite: $KANRI_APPIMAGE${NC}"

# Pergunta se quer executar agora
read -p "Deseja executar o Kanri agora? (s/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${BLUE}Iniciando Kanri...${NC}"
    "$KANRI_APPIMAGE" &
    disown
fi
