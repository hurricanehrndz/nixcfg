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
  config = mkIf cfg.tooling.js.enable {
    home.packages = with pkgs; [
      bun
    ];
  };
}
