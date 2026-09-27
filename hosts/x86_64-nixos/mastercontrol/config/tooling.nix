{ ... }:
{
  hrndz = {
    roles.vmHost = {
      enable = true;
      hardware.cpuVendor = "amd";
      users = [ "hurricane" ];
    };
    tooling.js.enable = true;
    tooling.golang.enable = true;
    tooling.documentTools.enable = true;
  };
}
