{
  description = "Generate colorscheme from image";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        packages.default = pkgs.rustPlatform.buildRustPackage rec {
          pname = "walrs";
          version = "1.1.7";
          src = ./.;
          
          cargoHash = "sha256-hacO5cg405l5ur5V/7oBjiGf9Q1AaTELRCndg+Q4Sws=";         
          nativeBuildInputs = with pkgs; [ bash ];
          
          preBuild = ''
            export RUSTC_BOOTSTRAP=1
          '';
          
          meta = with pkgs.lib; {
            description = "Generate colorscheme from image";
            license = licenses.gpl3;
            homepage = "https://github.com/pixel2175/walrs";
          };
        };
        
      });
}
