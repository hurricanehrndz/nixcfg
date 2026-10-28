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
  config = mkIf (cfg.tooling.ai.enable && cfg.tooling.ai.localInference.enable) {
    # oMLX (Apple-Silicon MLX inference server) lives in a custom tap whose
    # repo isn't named `homebrew-omlx`, so the clone target must be explicit.
    homebrew.taps = [
      {
        name = "jundot/omlx";
        clone_target = "https://github.com/jundot/omlx";
        trusted = true;
      }
    ];

    homebrew.brews = [
      # Fully qualified: `brew bundle cleanup` matches entries against each
      # formula's full name, so a bare `omlx` keeps omlx but not its deps.
      "jundot/omlx/omlx" # MLX-based local LLM server; run `omlx start`
    ];
  };
}
