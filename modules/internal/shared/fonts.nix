{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = config.hrndz;
in
{
  config = mkIf cfg.roles.guiDeveloper.enable {
    environment.systemPackages =
      with pkgs;
      mkIf isLinux [
        fontconfig
      ];
    fonts.packages =
      with pkgs;
      [
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
  };
}
