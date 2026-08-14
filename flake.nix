{
  description = "Awesome-wallpapers: My collection of awesome wallpapers";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    git-hooks,
    ...
  }: let
    supportedSystems = ["x86_64-linux" "aarch64-linux"];

    forAllSystems = f:
      nixpkgs.lib.genAttrs supportedSystems
      (system: f system (import nixpkgs {inherit system;}));
  in {
    devShells = forAllSystems (system: pkgs: {
      default = import ./shell.nix {
        inherit pkgs;
        gitHooksLib = git-hooks.lib.${system};
      };
    });
  };
}
