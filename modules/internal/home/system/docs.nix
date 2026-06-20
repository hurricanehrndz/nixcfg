{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib) mkDefault mkIf;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  cfg = osConfig.hrndz;
in
{
  config = mkIf cfg.roles.terminalDeveloper.enable {
    programs.man.enable = true;

    # more manpages — only where a man package exists. As of stateVersion
    # 26.05 home-manager defaults programs.man.package to null on Darwin
    # (it uses macOS's system man), and generateCaches has no effect there.
    programs.man.generateCaches = mkDefault (!isDarwin);

    # home-manager docs
    manual.json.enable = true;
    manual.manpages.enable = true;
  };
}
