{
  config,
  lib,
  options,
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
    networking.networkmanager.enable = mkDefault true;
    hardware.bluetooth.enable = mkDefault true;
  };
}
