{
  inputs,
  pkgs,
  lib,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) isLinux isDarwin;
  l = inputs.nixpkgs.lib // builtins;
  commonFonts = with pkgs; [
    fira
    inter
    nerd-fonts.fira-code
    nerd-fonts.sauce-code-pro
    nerd-fonts.symbols-only
  ];
  linuxFonts = with pkgs; [
    bakoma_ttf
    corefonts # broken on aarch64-darwin
    dejavu_fonts
    gentium
    liberation_ttf
    terminus_font # broken on aarch64-darwin
  ];
in {
    fonts.packages = commonFonts ++ (lib.optional isLinux linuxFonts);
  }
