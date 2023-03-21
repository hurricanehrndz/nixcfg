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
        editCommand = "nvr -s -l"; # see 'Configuring File Editing' section
        editCommandTemplate = "{{editor}} +{{line}} -- {{filename}}";
        openCommand = "nvr -s -l {{filename}}";
      };
      git = {
        autorefresh = false;
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
