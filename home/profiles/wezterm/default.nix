{
  pkgs,
  lib,
  ...
}: let
  l = lib // builtins;
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux isMacOS;
in {
  xdg.configFile."wezterm/wezterm.lua".source = ./config/wezterm.lua;
  home.packages = l.optionals isLinux (with pkgs; [
    weztrem
  ]);
}
