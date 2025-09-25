{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  yamlFormat = pkgs.formats.yaml {};
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in {
  home.packages = with pkgs; [
    lazygit
  ];

  programs.lazygit = {
    enable = true;
    settings = {
      promptToReturnFromSubprocess = false;
      os = {
        edit = "nvr -s -l"; # see 'Configuring File Editing' section
        editAtLine = "nvr -s -l +{{line}} -- {{filename}}";
        open = "nvr -s -l {{filename}}";
      };
      git = {
        autoFetch = false;
        autoRefresh = false;
      };
      keybinding = {
        files = {
          commitChanges = "C";
          commitChangesWithEditor = "c";
        };
      };
    };
  };

  xdg.configFile."lazygit/config.yml" = mkIf isDarwin {
    source = yamlFormat.generate "lazygit-config" config.programs.lazygit.settings;
  };
}
