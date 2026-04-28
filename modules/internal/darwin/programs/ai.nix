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
  config = mkIf cfg.roles.guiDeveloper.enable {
    homebrew.brews = [
      "llama.cpp"
      "opencode" # more up-to-date than nixpkgs
    ];

    homebrew.casks = [
      "lm-studio"
    ];
  };
}
