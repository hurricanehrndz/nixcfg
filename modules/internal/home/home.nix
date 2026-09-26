{ inputs, ... }:
{
  # external modules
  imports = [
    inputs.nix-index-database.homeModules.nix-index
    inputs.stylix.homeModules.stylix
  ];

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  xdg.enable = true;

  home.enableNixpkgsReleaseCheck = false;
}
