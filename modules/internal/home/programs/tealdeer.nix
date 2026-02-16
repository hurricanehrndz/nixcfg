{
  config,
  lib,
  osConfig,
  ...
}:
let
  inherit (config) xdg;
  cfg = osConfig.hrndz;
in
{
  config = lib.mkIf cfg.cli.enable {
    programs.tealdeer.enable = true;
    programs.tealdeer.settings = {
      display = {
        use_pager = false;
        compact = false;
      };
      updates = {
        auto_update = true;
        auto_update_interval_hours = 24 * 7;
      };
      directories.cache_dir = "${xdg.cacheHome}/tealdeer";
    };
  };
}
