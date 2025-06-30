{
  stdenv,
  lib,
  pkgs,
  realtek-r8152-src,
  kernel ? pkgs.linuxPackages_latest.kernel,
  ...
}: let
  src = realtek-r8152-src;
in
  # Create a derivation for the Realtek driver
  stdenv.mkDerivation {
    name = "realtek-r8152-driver";
    passthru.moduleName = "r8152";

    inherit src;

    nativeBuildInputs = kernel.moduleBuildDependencies;
    kernel = kernel.dev;
    kernelVersion = kernel.modDirVersion;

    buildFlags = [
      "KERNEL_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    ];

    installPhase = ''
      mkdir -p $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/net/usb/
      cp r8152.ko $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/net/usb/
    '';

    meta = {
      description = "Realtek official r8152 USB Ethernet driver";
      license = lib.licenses.gpl2;
    };
  }
