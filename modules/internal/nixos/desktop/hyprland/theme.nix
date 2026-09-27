{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  # Stylix at the system level, for what runs before Home Manager's session:
  # the boot splash (plymouth.nix) and the login screen (sddm.nix). The scheme
  # is the one Home Manager's Stylix uses (modules/internal/home/theme.nix);
  # every other system target stays off, and Home Manager keeps its own import.
  config = mkIf config.hrndz.desktop.hyprland.enable {
    stylix = {
      enable = true;
      autoEnable = false;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/${config.hrndz.theme.scheme}.yaml";
      homeManagerIntegration.autoImport = false;
      # Stylix's main branch still reports 26.05 against nixos-unstable's 26.11;
      # Home Manager's matches it, so only the system check trips.
      enableReleaseChecks = false;
    };
  };
}
