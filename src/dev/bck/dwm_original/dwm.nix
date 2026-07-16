{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation {
  name = "dwm-build-env";

  buildInputs = with pkgs; [
    xorg.libX11
    xorg.libXft
    xorg.libXinerama
    freetype
    fontconfig
    pkg-config
    git
    gnumake
    gcc
  ];

  # Script de build automatizado
  shellHook = ''
    echo "Ambiente de build DWM pronto!"
    if [ ! -f config.h ]; then
      echo "Copie seu config.h para este diretório"
      echo "Depois execute: make && sudo make install"
    fi
  '';
}
