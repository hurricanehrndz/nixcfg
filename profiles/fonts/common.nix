{
  inputs,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  l = inputs.nixpkgs.lib // builtins;
in {
  fonts.fontDir.enable = true;
  fonts.packages =
    (with pkgs; [
      # <https://bboxtype.com/typefaces/FiraSans/>
      fira
      inter
      (nerdfonts.override {
        fonts = [
          "FiraCode"
          "SourceCodePro"
          "NerdFontsSymbolsOnly"
        ];
      })
    ])
    ++ (l.optionals isLinux (with pkgs; [
      bakoma_ttf
      corefonts # broken on aarch64-darwin
      dejavu_fonts
      gentium
      liberation_ttf
      terminus_font # broken on aarch64-darwin
    ]));
}
