{ ... }:
{
  hrndz = {
    roles.vmHost = {
      enable = true;
      hardware.cpuVendor = "intel";
      users = [ "hurricane" ];
      windowsTestRig.enable = true;

      vfio = {
        enable = true;
        ignoreMsrs = true;
      };
    };
    tooling.js.enable = true;
    tooling.golang.enable = true;
    tooling.documentTools.enable = true;
  };
}
