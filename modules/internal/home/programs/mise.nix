{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = osConfig.hrndz;
  home = config.home.homeDirectory;
in
{
  # The agentToolkitSync activation runs mise non-interactively in these checkouts,
  # so a fresh clone must already be trusted. Trust itself is recorded in mise's
  # state dir, not this file; only `mise use -g`/`mise settings set` need it
  # writable.
  config = mkIf cfg.roles.terminalDeveloper.enable {
    home.packages = [ pkgs.unstable.mise ];

    xdg.configFile."mise/config.toml".source = (pkgs.formats.toml { }).generate "mise-config.toml" {
      settings = {
        # mise defaults to compiling Python from source on NixOS; nix-ld
        # (hrndz.foreignBinaries) runs its locked prebuilt binaries instead.
        all_compile = false;
        trusted_config_paths = [
          "${home}/src/me/agent-toolkit"
          "${home}/src/me/respec"
        ];
      };
    };
  };
}
