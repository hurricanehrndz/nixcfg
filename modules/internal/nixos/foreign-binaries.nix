{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    ;
  cfg = config.hrndz.foreignBinaries;

  appimage = pkgs.writeShellApplication {
    name = "appimage";
    runtimeInputs = [
      config.programs.appimage.package
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnugrep
      pkgs.gnused
    ];
    text = builtins.readFile ./foreign-binaries-appimage.sh;
  };
in
{
  options.hrndz.foreignBinaries = {
    # Software built for a conventional Linux layout: prebuilt glibc binaries
    # (mise-installed node/python/bun, downloaded language servers, npm/pip
    # natives) and scripts with #!/bin/bash or #!/usr/bin/env shebangs.
    enable = mkEnableOption "support for binaries and scripts not built by Nix" // {
      default = config.hrndz.roles.terminalDeveloper.enable;
    };

    appimage.enable = mkEnableOption "running AppImages directly" // {
      default = cfg.enable;
    };
  };
  config = mkIf cfg.enable {
    # Registers binfmt so ./Foo.AppImage runs without appimage-run.
    programs.appimage = mkIf cfg.appimage.enable {
      enable = true;
      binfmt = true;
    };
    environment.systemPackages = mkIf cfg.appimage.enable [ appimage ];
    # nixpkgs' default library set covers headless tools (libstdc++, zlib,
    # openssl, curl, libxml2, ...); the desktop adds its GUI libraries.
    programs.nix-ld.enable = true;
    # Mounts /bin and /usr/bin as a view of the current PATH.
    services.envfs.enable = true;
  };
}
