{
  description = "awesome-wallpapers";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    packages.${system}.default = pkgs.stdenv.mkDerivation (finalAttrs: {
      pname = "awesome-wallpapers";
      version = "0.0.1";

      src = ./app;

      nativeBuildInputs = [
        pkgs.nodejs
        pkgs.pnpmConfigHook
      ];

      pnpmDeps = pkgs.fetchPnpmDeps {
        inherit (finalAttrs) pname version src;
        fetcherVersion = 2;
        hash = "sha256-Aa8amfaU+3CxrDKTee2vjz3CV0g0f+vzpJyDAaP/bY0=";
      };

      buildPhase = ''
        pnpm run build
      '';

      installPhase = ''
        mkdir -p $out/share/awesome-wallpapers
        cp -r build/. $out/share/awesome-wallpapers
      '';
    });
  };
}
