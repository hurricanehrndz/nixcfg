{
  inputs,
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

  system = pkgs.stdenv.hostPlatform.system;

  browserType = types.enum [
    "zen"
    "firefox"
  ];

  hasBrowser = browser: builtins.elem browser cfg.browsers;

  desktopEntries = {
    zen = "zen-beta.desktop";
    firefox = "firefox.desktop";
  };

  defaultDesktop = desktopEntries.${cfg.default};

  browserPackages = optional (hasBrowser "zen") inputs.zen-browser.packages.${system}.default;
in
{
  options.hrndz.desktop.browser = {
    browsers = mkOption {
      type = types.listOf browserType;
      default = [ ];
      example = [
        "zen"
        "firefox"
      ];
      description = ''
        Browsers to install for the desktop session. When more than one browser
        is listed, use `hrndz.desktop.browser.default` to choose the default.
      '';
    };

    default = mkOption {
      type = browserType;
      default = "zen";
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
      hrndz.desktop.browser.browsers = mkDefault [ "zen" ];
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
