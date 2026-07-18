{ pkgs, ... }:
{
  programs.jq.enable = true;

  home.packages = [ pkgs.p7zip ];
}
