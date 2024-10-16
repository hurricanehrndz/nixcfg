{
  lib,
  pkgs,
  ...
}:
lib.mkMerge [
  (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    services.tillingwm.enable = true;
    services.tillingwm.settings = builtins.readFile ./config.toml;
  })
]
