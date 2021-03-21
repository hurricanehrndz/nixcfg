{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.sheldon;

  tomlFormat = pkgs.formats.toml { };

  configFile = tomlFormat.generate "sheldon-config" cfg.settings;
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
     type = tomlFormat.type;
     default = { };
     description = "Configuration for Sheldon";
     example = literalExample ''
       {
         shell = "zsh"
       }
     '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."sheldon/plugins.toml" = mkIf (cfg.settings != { }) {
      source = configFile;
    };
  };
}
