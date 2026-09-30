# Host tools for the windows-test-rig agent skill (agent-toolkit
# skills/windows-test-rig): its `rig` script provisions and drives Windows 11
# test VMs under libvirt, on this host or on another vmHost over qemu+ssh.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.hrndz.roles.vmHost;
in
{
  options.hrndz.roles.vmHost.windowsTestRig.enable =
    mkEnableOption "the windows-test-rig tools (virt-install, xorriso, ImageMagick)";

  config = mkIf (cfg.enable && cfg.windowsTestRig.enable) {
    assertions = [
      {
        assertion = cfg.libvirt.enable;
        message = "hrndz.roles.vmHost.windowsTestRig needs hrndz.roles.vmHost.libvirt.enable.";
      }
    ];

    environment.systemPackages = with pkgs; [
      virt-manager # provides virt-install, which `rig provision` runs
      xorriso # packs the rendered autounattend.xml into an ISO
      imagemagick # `rig shot` converts and checks console screenshots
    ];
  };
}
