{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  inherit (lib) mkDefault mkIf;
in
{
  config = mkIf config.hrndz.desktop.hyprland.enable {
    ##: Session plumbing
    security.polkit.enable = true;
    services.dbus.enable = true;

    # The shell's lock screen authenticates through this PAM service.
    security.pam.services.desktop-lock = { };

    services.logind.settings.Login = {
      # The shell's power menu owns the power button; logind's default
      # "poweroff" would shut down before the menu could open.
      HandlePowerKey = "ignore";
      # Room for hypridle's sleep delay inhibitor to lock the screen first.
      InhibitDelayMaxSec = 15;
    };

    # Keep the user manager running without a login, so a session started by
    # desktop-vnc over SSH survives the SSH connection closing.
    users.users.${config.system.primaryUser}.linger = true;

    # USB devices stay awake (keyboards, the soundbar). A kernel parameter:
    # usbcore is built in, so modprobe options never reach it.
    boot.kernelParams = [ "usbcore.autosuspend=-1" ];

    ##: Keyboard
    # Caps Lock is Meh (Ctrl+Shift+Alt), as Superkey makes it on macOS; with
    # Super it makes Hyper. xkb has no option for a modifier chord.
    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = [ "*" ];
        settings = {
          main.capslock = "layer(meh)";
          "meh:C-S-A" = { };
        };
      };
    };

    ##: Limits
    # Proton/Wine and file watchers want more than the default 1024 soft limit.
    # A 15s stop timeout lets VMs and containers shut down cleanly while
    # avoiding 90s hangs.
    systemd.settings.Manager = {
      DefaultLimitNOFILE = "65536:524288";
      DefaultTimeoutStopSec = "15s";
    };
    # systemd.user.settings is unstable-only; 26.05 still has extraConfig.
    systemd.user.${if options.systemd.user ? settings then "settings" else "extraConfig"} =
      if options.systemd.user ? settings then
        { Manager.DefaultLimitNOFILE = "65536:524288"; }
      else
        "DefaultLimitNOFILE=65536:524288";
    systemd.services."user@".serviceConfig.TimeoutStopSec = "15s";

    ##: Printing with network discovery
    services.printing = {
      enable = true;
      browsed.enable = false;
    };
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    ##: Desktop services the shell and file manager talk to
    services.gvfs.enable = true;
    services.tumbler.enable = true;
    services.udisks2.enable = mkDefault true;
    services.upower.enable = mkDefault true;
    services.power-profiles-daemon.enable = mkDefault (!config.services.tlp.enable);
    services.gnome.gnome-keyring.enable = mkDefault true;
    # gpg-agent serves SSH (home/programs/gpg.nix); gcr's agent would claim
    # SSH_AUTH_SOCK in the systemd user environment.
    services.gnome.gcr-ssh-agent.enable = false;
    networking.networkmanager.enable = mkDefault true;
    hardware.bluetooth.enable = mkDefault true;

    # External monitors' brightness over DDC/CI: i2c-dev, and ddcutil's rule
    # giving the seat's user the displays' I2C buses.
    hardware.i2c.enable = true;
    services.udev.packages = [ pkgs.ddcutil ];

    # YubiKey: browsers reach FIDO2 through systemd's own udev rules; OATH
    # codes (ykman oath) and the GPG card (scdaemon has disable-ccid) go
    # through pcscd. pcscd's polkit policy admits only processes in the active
    # session, and gpg-agent starts scdaemon from the systemd user manager,
    # which sits outside it.
    services.pcscd.enable = true;
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if ((action.id == "org.debian.pcsc-lite.access_pcsc" ||
             action.id == "org.debian.pcsc-lite.access_card") &&
            subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';

    # The weather widget locates the machine unless a location is fixed. The
    # shell's locate helper asks through GeoClue's where-am-i client.
    services.geoclue2 = mkIf (config.hrndz.desktop.hyprland.weather.location == null) {
      enable = true;
      appConfig.geoclue-where-am-i = {
        isAllowed = true;
        isSystem = false;
      };
    };

    # The shell's Tailscale panel runs tailscale as the desktop user: up/down,
    # exit nodes, account switching.
    services.tailscale.extraSetFlags = mkIf config.services.tailscale.enable [
      "--operator=${config.system.primaryUser}"
    ];
  };
}
