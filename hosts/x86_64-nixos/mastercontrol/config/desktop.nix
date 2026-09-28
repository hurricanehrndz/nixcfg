{ pkgs, ... }:
{
  hrndz.desktop = {
    hyprland.enable = true;
    gaming.enable = true;
    flatpak.packages = [ "sh.cider.Cider" ];
  };

  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "hurricane" ];
  };

  environment.systemPackages = with pkgs; [
    discord
    obsidian
    zed-editor
  ];
}
