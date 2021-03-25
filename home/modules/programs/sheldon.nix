{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.programs.sheldon;
in {
  options.programs.sheldon = {
   enable = mkEnableOption "Sheldon configuration";

   package = mkOption {
     type = types.package;
     default = pkgs.sheldon;
     defaultText = literalExample "pkgs.sheldon";
     description = "The Sheldon package to install.";
   };

   settings = mkOption {
     type = types.lines;
     default = "";
     description = "TOML inline config for Sheldon";
     example = literalExample ''
       shell = "zsh"
     '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."sheldon/plugins.toml" = mkIf (cfg.settings != "" ) {
      text = cfg.settings;
    };

    programs.zsh.initExtraBeforeCompInit = ''
      # load sheldon plugins
      source <(sheldon source)
    '';
  };
}
