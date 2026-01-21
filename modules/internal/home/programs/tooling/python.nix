{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = osConfig.hrndz;
in
{
  config = mkIf cfg.tooling.python.enable {
    home.packages = with pkgs; [
      pipx
      pyright
      (lib.lowPrio python310)
      (lib.lowPrio python311)
      python312
      ruff
      uv
      virtualenv
    ];
  };
}
