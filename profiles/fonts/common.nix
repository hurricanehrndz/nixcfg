{
  inputs,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) isLinux isDarwin;
  l = inputs.nixpkgs.lib // builtins;
  commonFonts = with pkgs; [
    fira
    inter
    (nerdfonts.override {
      fonts = [
        "FiraCode"
        "SourceCodePro"
        "NerdFontsSymbolsOnly"
      ];
    })
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
  fonts = {
    fontDir.enable = true;
  } // (if isLinux then {
    packages = commonFonts ++ linuxFonts;
  } else {
    fonts = commonFonts;
  });
}
