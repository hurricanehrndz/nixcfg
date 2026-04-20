{
  lib,
  pkgs,
  osConfig,
  ...
}:

let
  inherit (lib) mkIf;
  cfg = osConfig.hrndz;
in
{
  config = mkIf cfg.tooling.extras.enable {
    home.packages = with pkgs; [
    ];
  };
}

