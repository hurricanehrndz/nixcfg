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
  config = mkIf cfg.tooling.ruby.enable {
    home.packages = with pkgs; [
      rbenv
      ruby_3_4
      rubyfmt
    ];
  };
}
