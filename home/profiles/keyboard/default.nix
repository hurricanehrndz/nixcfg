{
  lib,
  pkgs,
  ...
}:
lib.mkMerge [
  {
    home.packages = with pkgs; [];
  }
  # enable skhd here, because it autoreloads config on changes
  (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    services.skhd.enable = true;
    services.skhd.configPath = ./skhdrc;
  })
]
