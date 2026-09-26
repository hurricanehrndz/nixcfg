{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    optionalAttrs
    types
    ;
  cfg = config.hrndz.desktop.omarchy;
  system = pkgs.stdenv.hostPlatform.system;

  # The Hyprland nixarchy tests Omarchy against (>= 0.55, for the Lua config API).
  hyprlandPkgs = inputs.nixarchy.inputs.hyprland.packages.${system};

  # Runs Hyprland against Omarchy's own hyprland.lua from the store. That file
  # then loads the user overrides in ~/.config/hypr/*.lua.
  sessionLauncher = pkgs.writeShellScript "omarchy-session" ''
    export OMARCHY_PATH=${cfg.package}/share/omarchy
    exec ${pkgs.uwsm}/bin/uwsm start -N Omarchy -D Hyprland -- \
      ${config.programs.hyprland.package}/bin/start-hyprland -- \
      --config ${cfg.package}/share/omarchy/config/hypr/hyprland.lua
  '';

  sessionPackage =
    (pkgs.writeTextFile {
      name = "omarchy-wayland-session";
      destination = "/share/wayland-sessions/omarchy.desktop";
      text = ''
        [Desktop Entry]
        Name=Omarchy
        Comment=Omarchy on NixOS, through Hyprland
        Exec=${sessionLauncher}
        Type=Application
        DesktopNames=Hyprland
      '';
    }).overrideAttrs
      (_: {
        passthru.providedSessions = [ "omarchy" ];
      });

  # /etc files upstream installs on Arch that the Omarchy tree expects.
  installedEtc = lib.attrNames (
    lib.filterAttrs (_: row: row.class == "installed") (
      import "${inputs.nixarchy}/data/etc-overlay.nix"
    )
  );
in
{
  options.hrndz.desktop.omarchy = {
    enable = mkEnableOption "the Omarchy desktop (Hyprland + Quickshell)";

    package = mkOption {
      type = types.package;
      default = inputs.nixarchy.packages.${system}.omarchy;
      defaultText = lib.literalExpression "inputs.nixarchy.packages.\${system}.omarchy";
      description = "The vendored Omarchy tree, patched for NixOS.";
    };

    flake = mkOption {
      type = types.str;
      default = "/home/${config.system.primaryUser}/src/me/nixcfg";
      description = "Flake Omarchy's Update menu rebuilds from (via nh).";
    };

    theme = mkOption {
      type = types.str;
      default = "catppuccin-latte";
      description = "Omarchy theme applied on first login; change it later from the Style menu.";
    };

    autologin = {
      enable = mkEnableOption "greetd autologin into a locked Omarchy session";
      user = mkOption {
        type = types.str;
        default = config.system.primaryUser;
        description = "User for greetd's initial Omarchy autologin session.";
      };
    };

    remote = {
      enable = mkEnableOption "WayVNC startup inside the Omarchy session";
      bind = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Address passed to wayvnc.";
      };
      port = mkOption {
        type = types.port;
        default = 5900;
        description = "Port passed to wayvnc.";
      };
    };
  };

  config = mkIf cfg.enable {
    ##: Hyprland, pinned to what nixarchy tests Omarchy against
    programs.hyprland = {
      enable = true;
      package = hyprlandPkgs.hyprland;
      portalPackage = hyprlandPkgs.xdg-desktop-portal-hyprland;
      xwayland.enable = true;
      withUWSM = true;
    };

    nix.settings = {
      substituters = [
        "https://nixarchy.cachix.org"
        "https://hyprland.cachix.org"
      ];
      trusted-public-keys = [
        "nixarchy.cachix.org-1:05JOuIlsQOWY2/5DQMq7JEA1hwlhgvmMWowMfka8mMM="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIITemDosxrE9/Kb+PfYvE="
      ];
    };

    ##: Login screen - greetd + tuigreet, offering the Omarchy session
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd ${sessionLauncher}";
          user = "greeter";
        };
      }
      // optionalAttrs cfg.autologin.enable {
        initial_session = {
          command = "${sessionLauncher}";
          user = cfg.autologin.user;
        };
      };
    };
    services.displayManager.sessionPackages = [ sessionPackage ];

    ##: Omarchy tree and what its scripts shell out to
    environment.sessionVariables = {
      OMARCHY_PATH = "${cfg.package}/share/omarchy";
      OMARCHY_SCREENSHOT_EDITOR = mkDefault "satty-edit";
      # Read by `omarchy update`, which rebuilds through nh.
      NIXARCHY_FLAKE = cfg.flake;
      NH_FLAKE = cfg.flake;
      XDG_DATA_DIRS = [
        "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
      ];
      MOZ_ENABLE_WAYLAND = "1";
      NIXOS_OZONE_WL = "1";
    };

    environment.systemPackages = [
      cfg.package
      sessionPackage
    ]
    # The session's Hyprland comes from programs.hyprland, not the tree's deps.
    ++ builtins.filter (d: !(lib.hasPrefix "hyprland-" (d.name or ""))) cfg.package.passthru.runtimeDeps
    ++ (with pkgs; [
      glib
      gsettings-desktop-schemas
      gnome-themes-extra
      yaru-theme
      adwaita-icon-theme
      bibata-cursors
      wayvnc
    ])
    # Screen-share picker; nixos-26.05 does not carry it yet.
    ++ [ inputs.nixarchy.inputs.nixpkgs.legacyPackages.${system}.hyprland-preview-share-picker ];

    environment.etc = {
      "omarchy/xcompose".source = "${cfg.package}/share/omarchy/default/xcompose";
    }
    // lib.genAttrs installedEtc (name: {
      source = "${cfg.package}/share/omarchy/etc/${name}";
    });

    fonts.fontconfig.localConf = mkDefault (
      # From the source input, not the built tree: reading a build output here
      # would force a build during evaluation.
      builtins.readFile "${inputs.nixarchy.inputs.omarchy}/default/fontconfig/conf.avail/50-omarchy.conf"
    );
    fonts.packages = [
      cfg.package
    ]
    ++ (with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono
      font-awesome
      liberation_ttf
    ]);

    ##: Portals
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    ##: Lock screen (Quickshell) authenticates through this PAM service
    security.pam.services.omarchy-lock-password = { };
    security.rtkit.enable = true;
    security.polkit.enable = true;
    services.dbus.enable = true;

    ##: Audio - PipeWire stack
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };
    services.pulseaudio.enable = false;

    ##: Desktop services the Omarchy menus and bar talk to
    services.gvfs.enable = true;
    services.tumbler.enable = true;
    services.udisks2.enable = mkDefault true;
    services.upower.enable = mkDefault true;
    services.power-profiles-daemon.enable = mkDefault (!config.services.tlp.enable);
    services.gnome.gnome-keyring.enable = mkDefault true;
    networking.networkmanager.enable = mkDefault true;
    hardware.bluetooth.enable = mkDefault true;
  };
}
