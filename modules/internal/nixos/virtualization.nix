{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkDefault
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optional
    optionals
    types
    ;
  cfg = config.me.virtualization;
  cpuModule =
    if cfg.hardware.cpuVendor == "intel" then
      "kvm-intel"
    else if cfg.hardware.cpuVendor == "amd" then
      "kvm-amd"
    else
      null;
  iommuParam =
    if cfg.hardware.cpuVendor == "intel" then
      "intel_iommu=on"
    else if cfg.hardware.cpuVendor == "amd" then
      "amd_iommu=on"
    else
      null;
in
{
  options.me.virtualization = {
    enable = mkEnableOption "NixOS virtualization host support";

    hardware.cpuVendor = mkOption {
      type = types.nullOr (
        types.enum [
          "intel"
          "amd"
        ]
      );
      default = null;
      description = "CPU vendor for KVM and optional IOMMU/VFIO hardware support.";
    };

    users = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Users allowed to manage local virtualization resources.";
    };

    libvirt.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable libvirtd/qemu host virtualization.";
    };

    virtManager.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable virt-manager and install virt-viewer.";
    };

    vfio = {
      enable = mkEnableOption "VFIO kernel modules for PCI passthrough";

      ignoreMsrs = mkOption {
        type = types.bool;
        default = false;
        description = "Add kvm.ignore_msrs=1 for guests that access unsupported model-specific registers.";
      };

      iommu.enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the CPU-vendor-specific IOMMU kernel parameter.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        {
          assertion = cfg.hardware.cpuVendor != null;
          message = "me.virtualization.enable requires me.virtualization.hardware.cpuVendor to be set to \"intel\" or \"amd\".";
        }
      ];

      boot.kernelModules = optional (cpuModule != null) cpuModule;
      boot.kernelParams =
        optionals cfg.vfio.ignoreMsrs [ "kvm.ignore_msrs=1" ]
        ++ optionals (cfg.vfio.iommu.enable && iommuParam != null) [ iommuParam ];

      users.users = lib.genAttrs cfg.users (_: {
        extraGroups = [ "kvm" ] ++ optional cfg.libvirt.enable "libvirtd";
      });
    }

    (mkIf cfg.libvirt.enable {
      virtualisation.libvirtd = {
        enable = true;
        qemu = {
          ovmf.enable = mkDefault true;
          swtpm.enable = mkDefault true;
        };
      };
    })

    (mkIf cfg.virtManager.enable {
      programs.virt-manager.enable = true;
      environment.systemPackages = with pkgs; [
        virt-viewer
      ];
    })

    (mkIf cfg.vfio.enable {
      boot.kernelModules = [
        "vfio"
        "vfio_iommu_type1"
        "vfio_pci"
        "vfio_virqfd"
      ];
    })
  ]);
}
