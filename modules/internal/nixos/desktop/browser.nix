{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkIf
    mkMerge
    mkOption
    optional
    types
    ;
  cfg = config.hrndz.desktop.browser;

  browserType = types.enum [
    "brave-origin-beta"
    "brave-origin-nightly"
    "firefox"
  ];

  hasBrowser = browser: builtins.elem browser cfg.browsers;

  desktopEntries = {
    brave-origin-beta = "brave-origin-beta.desktop";
    brave-origin-nightly = "brave-origin-nightly.desktop";
    firefox = "firefox.desktop";
  };

  defaultDesktop = desktopEntries.${cfg.default};

  browserPackages =
    optional (hasBrowser "brave-origin-beta") pkgs.brave-origin-beta
    ++ optional (hasBrowser "brave-origin-nightly") pkgs.brave-origin-nightly;
in
{
  options.hrndz.desktop.browser = {
    browsers = mkOption {
      type = types.listOf browserType;
      default = [ ];
      example = [
        "brave-origin-beta"
        "firefox"
      ];
      description = ''
        Browsers to install for the desktop session. When more than one browser
        is listed, use `hrndz.desktop.browser.default` to choose the default.
      '';
    };

    default = mkOption {
      type = browserType;
      default = "brave-origin-beta";
      description = "Default browser. Must be present in `hrndz.desktop.browser.browsers` when browsers are enabled.";
    };
  };

  config = mkMerge [
    {
      assertions = [
        {
          assertion = cfg.browsers == [ ] || hasBrowser cfg.default;
          message = "hrndz.desktop.browser.default must be one of hrndz.desktop.browser.browsers.";
        }
      ];
    }

    (mkIf (config.hrndz.roles.guiDeveloper.enable || config.hrndz.desktop.hyprland.enable) {
      hrndz.desktop.browser.browsers = mkDefault [ "brave-origin-beta" ];
    })

    (mkIf (browserPackages != [ ]) {
      environment.systemPackages = browserPackages;
    })

    (mkIf (hasBrowser "firefox") {
      programs.firefox = {
        enable = true;
        package = pkgs.firefox;
      };

      environment.sessionVariables.MOZ_ENABLE_WAYLAND = mkDefault "1";
    })

    (mkIf (cfg.browsers != [ ]) {
      xdg.mime.defaultApplications = {
        "text/html" = mkDefault defaultDesktop;
        "x-scheme-handler/about" = mkDefault defaultDesktop;
        "x-scheme-handler/http" = mkDefault defaultDesktop;
        "x-scheme-handler/https" = mkDefault defaultDesktop;
        "x-scheme-handler/unknown" = mkDefault defaultDesktop;
      };
    })
  ];
}
