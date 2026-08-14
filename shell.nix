{
  pkgs,
  gitHooksLib,
}: let
  hooks = gitHooksLib.run {
    src = ./.;
    hooks = {
      check-filename-format = {
        enable = true;
        name = "check-filename-format";
        entry = "bash .github/scripts/check-filename-format.sh";
        language = "system";
        files = "(wallpapers/)";
        pass_filenames = false;
      };
      convert-to-png = {
        enable = true;
        name = "convert-to-png";
        entry = "bash .github/scripts/convert-to-png.sh";
        language = "system";
        files = "(wallpapers/)";
        pass_filenames = false;
      };
      create-markdowns = {
        enable = true;
        name = "create-markdowns";
        entry = "bash .github/scripts/create-markdowns.sh";
        language = "system";
        files = "(wallpapers/)";
        pass_filenames = false;
      };
    };
  };
in
  pkgs.mkShell {
    packages = hooks.enabledPackages ++ (with pkgs; [imagemagick oxipng gifsicle]);
    shellHook = hooks.shellHook;
  }
