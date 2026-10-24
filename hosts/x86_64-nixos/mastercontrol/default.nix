{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    (inputs.import-tree ./config)
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 1;
  # Kernel 7.2's modules_install runs depmod despite nixpkgs' DEPMOD=true, so
  # v4l2loopback (pulled in by OBS's virtual camera) ships modules.* index files
  # that collide with the kernel's. Drop them; remove once nixpkgs fixes it.
  boot.kernelPackages = pkgs.linuxPackages_zen.extend (
    _: prev: {
      v4l2loopback = prev.v4l2loopback.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          rm -f $out/lib/modules/*/modules.*
        '';
      });
    }
  );

  networking.hostName = "mastercontrol";
  networking.domain = "hrndz.ca";

  system.primaryUser = "hurricane";
  system.stateVersion = "25.11";
}
