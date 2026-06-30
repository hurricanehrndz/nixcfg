{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf optionals;
  cfg = osConfig.hrndz;
in
{
  config = mkIf cfg.tooling.golang.enable {
    home.packages =
      with pkgs;
      [
        go
      ]
      ++ optionals stdenv.isLinux [
        gcc
      ];
  };
}
