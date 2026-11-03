{ ... }:
{
  hrndz = {
    roles.vmHost = {
      enable = true;
      hardware.cpuVendor = "amd";
      users = [ "hurricane" ];
      windowsTestRig.enable = true;
    };
    tooling.js.enable = true;
    tooling.golang.enable = true;
    tooling.documentTools.enable = true;
    tooling.ai.testRig.windows.enable = true;
    tooling.ai.testRig.macos.enable = true;
  };
}
