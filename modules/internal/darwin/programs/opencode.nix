{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = config.hrndz;
in
{
  config = mkIf cfg.tui.enable {
    homebrew.brews = [
      "opencode" # more up-to-date than nixpkgs
    ];
  };
}
