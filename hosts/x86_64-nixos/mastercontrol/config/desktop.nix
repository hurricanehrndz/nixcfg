{ pkgs, ... }:
{
  hrndz.desktop = {
    hyprland.enable = true;
    gaming.enable = true;
  };

  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "hurricane" ];
  };

  environment.systemPackages = with pkgs; [
    cider-2
    discord
    obsidian
    zed-editor
  ];
}
