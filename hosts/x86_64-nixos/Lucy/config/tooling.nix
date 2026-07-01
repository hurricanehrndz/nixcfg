{ ... }:
{
  hrndz.tooling = {
    virtualization = {
      enable = true;
      hardware.cpuVendor = "intel";
      users = [ "hurricane" ];

      vfio = {
        enable = true;
        ignoreMsrs = true;
      };
    };
    js.enable = true;
    golang.enable = true;
    extras.enable = true;
  };
}
