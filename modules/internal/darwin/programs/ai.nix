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
  config = mkIf cfg.tooling.ai.enable {
    # oMLX (Apple-Silicon MLX inference server) lives in a custom tap whose
    # repo isn't named `homebrew-omlx`, so the clone target must be explicit.
    homebrew.taps = [
      {
        name = "jundot/omlx";
        clone_target = "https://github.com/jundot/omlx";
      }
    ];

    homebrew.brews = [
      "omlx" # MLX-based local LLM server; run `omlx start`
    ];
  };
}
