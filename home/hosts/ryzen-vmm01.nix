{ ... }:

{
  home.stateVersion = "20.09";

  programs.home-manager.enable = true;
  targets.genericLinux.enable = true;

  hurricane = {
    profiles = {
      common.enable = true;
      development.enable = true;
      desktop.enable = true;
    };
  };
}

# vim:foldmethod=marker:foldlevel=0:ts=2:sts=2:sw=2:et:nowrap
