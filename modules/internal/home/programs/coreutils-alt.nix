{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  cfg = osConfig.hrndz;
in
{
  config = lib.mkIf cfg.cli.enable {
    home.packages = with pkgs; [
      # modern coreutils alternatives
      bottom
      eza
      fd
      sd
      (ripgrep.override { withPCRE2 = true; })

      # TODO: joy ride
      lsd
    ];
  };
}
