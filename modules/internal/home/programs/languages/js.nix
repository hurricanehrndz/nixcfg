{
  lib,
  pkgs,
  config,
  osConfig,
  ...
}:

let
  inherit (lib) mkIf;
  cfg = osConfig.hrndz;
in
{
  config = mkIf cfg.tooling.js.enable {
    home.sessionVariables = {
      NPM_CONFIG_USERCONFIG = "${config.xdg.configHome}/npm/npmrc";
      # Ensures binaries can be run straight from your terminal terminal
      PATH = "$HOME/.local/share/npm/bin:$PATH";
    };

    xdg.configFile."npm/npmrc".text = ''
      prefix=${config.xdg.dataHome}/npm
      cache=${config.xdg.cacheHome}/npm
    '';

    home.packages = with pkgs; [
      bun
      nodejs
    ];
  };
}
