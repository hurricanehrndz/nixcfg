{
  config,
  lib,
  pkgs,
  options,
  ...
}:
with lib; let
  cfg = config.services.gnomeDesktop;
in {
  options.services.gnomeDesktop = {
    enable = mkEnableOption "Enable GNOME desktop environment.";

    username = mkOption {
      type = types.str;
      description = ''
        Primary GNOME desktop user.
      '';
    };
  };
  config = mkIf cfg.enable {
    services.xserver = {
      enable = true;
      desktopManager.gnome.enable = true;
      displayManager.gdm = {
        enable = true;
        wayland = true;
        # disable suspend on login screen
        autoSuspend = false;
      };
      displayManager.autoLogin.enable = true;
      displayManager.autoLogin.user = "hurricane";

      # mouse and/or touchbad driver
      libinput.enable = true;
    };

    # fix autologin stop crash
    # https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
    systemd.services."autovt@tty1".enable = lib.mkForce false;
    systemd.services."getty@tty1".enable = lib.mkForce false;

    # see: https://discourse.nixos.org/t/why-is-my-new-nixos-install-suspending/19500/2
    # https://discourse.nixos.org/t/disable-suspend-if-ssh-sessions-are-active/11655
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.login1.suspend" ||
              action.id == "org.freedesktop.login1.suspend-multiple-sessions" ||
              action.id == "org.freedesktop.login1.hibernate" ||
              action.id == "org.freedesktop.login1.hibernate-multiple-sessions")
          {
              return polkit.Result.NO;
          }
      });
    '';

    # Gnome packages
    environment.gnome.excludePackages =
      (with pkgs; [
        gnome-photos
        gnome-tour
      ])
      ++ (with pkgs.gnome; [
        cheese # webcam tool
        gnome-music
        gedit # text editor
        epiphany # web browser
        geary # email reader
        gnome-characters
        tali # poker game
        iagno # go game
        hitori # sudoku game
        atomix # puzzle game
        yelp # Help view
        gnome-contacts
        gnome-initial-setup
      ]);
    programs.dconf.enable = true;
    environment.systemPackages = with pkgs; [
      gnome.gnome-tweaks
      libsecret
    ];

    # audio
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
    hardware.pulseaudio.enable = false;

    services.udev.packages = with pkgs; [gnome.gnome-settings-daemon];
    xdg = {
      portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-wlr # screen capture wayland
        ];
      };
    };

    security.polkit.enable = true;
    networking.firewall.allowedTCPPorts = [3389];

    home-manager.users.${cfg.username} = {pkgs, ...}: {
      dconf.settings = {
        "org/gnome/shell" = {
          disable-user-extensions = false;

          # `gnome-extensions list` for a list
          enabled-extensions = [
            "allowlockedremotedesktop@kamens.us"
          ];
        };
        "org/gnome/desktop/interface" = {
          color-scheme = "default";
          enable-hot-corners = false;
        };

        "org/gnome/desktop/interface" = {
          show-battery-percentage = false;
        };

        "org/gnome/desktop/privacy" = {
          old-files-age = 30;
          remove-old-temp-files = true;
          remove-old-tash-files = true;
        };
      };
      home.packages = with pkgs; [
        gnomeExtensions.allow-locked-remote-desktop
      ];
    };
  };
}
