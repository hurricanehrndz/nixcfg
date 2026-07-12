{ ... }:
{
  hrndz = {
    roles.vmHost = {
      enable = true;
      hardware.cpuVendor = "intel";
      users = [ "hurricane" ];

      vfio = {
        enable = true;
        ignoreMsrs = true;
      };
    };
    tooling.js.enable = true;
    tooling.golang.enable = true;
    tooling.extras.enable = true;
  };
}
