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
      (lib.setPrio 20 python310)
      (lib.setPrio 15 python311)
      python312
      ruff
      uv
      virtualenv
    ];
  };
}
