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
  config = mkIf cfg.tooling.python.enable {
    home.packages = with pkgs; [
      bun
    ];
  };
}
