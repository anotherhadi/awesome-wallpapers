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
        pkgs.pnpm.configHook
      ];

      pnpmDeps = pkgs.pnpm.fetchDeps {
        inherit (finalAttrs) pname version src;
        fetcherVersion = 2;
        hash = "sha256-t1j6SNTG6uE8yLbo02LcRt41TghqvSJbVqj/7/Kmwzc=";
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
