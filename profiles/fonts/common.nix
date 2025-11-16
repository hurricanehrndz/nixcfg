{
  pkgs,
  lib,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  myFontPkgs =
    with pkgs;
    [
      sketchybar-app-font
      fira
      inter
      nerd-fonts.fira-code
      nerd-fonts.sauce-code-pro
      nerd-fonts.jetbrains-mono
      nerd-fonts.hack
      nerd-fonts.symbols-only
    ]
    ++ (lib.optionals isLinux [
      bakoma_ttf
      corefonts # broken on aarch64-darwin
      dejavu_fonts
      gentium
      liberation_ttf
      terminus_font # broken on aarch64-darwin
    ]);
in
{
  fonts.packages = myFontPkgs;
}
