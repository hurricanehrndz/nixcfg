{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkIf
    mkMerge
    mkOption
    types
    ;
  cfg = config.me.hardware.gpu;
in
{
  options.me.hardware.gpu = {
    vendor = mkOption {
      type = types.nullOr (
        types.enum [
          "intel"
          "amd"
        ]
      );
      default = null;
      description = "GPU vendor profile for host hardware graphics support.";
    };

    enable32Bit = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable 32-bit graphics driver support.";
    };
  };

  config = mkIf (cfg.vendor != null) (mkMerge [
    {
      hardware.graphics = {
        enable = true;
        enable32Bit = cfg.enable32Bit;
      };
    }

    (mkIf (cfg.vendor == "intel") {
      hardware.graphics.extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
      ];

      environment.sessionVariables.LIBVA_DRIVER_NAME = mkDefault "iHD";
      hardware.cpu.intel.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;
    })

    (mkIf (cfg.vendor == "amd") {
      hardware.graphics.extraPackages = with pkgs; [
        libvdpau-va-gl
      ];

      environment.systemPackages = with pkgs; [
        radeontop
      ];

      environment.sessionVariables.AMD_VULKAN_ICD = mkDefault "RADV";
      hardware.cpu.amd.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;
    })
  ]);
}
