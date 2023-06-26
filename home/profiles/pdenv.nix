{
  pkgs,
  inputs',
  ...
}: let
  inherit (inputs'.pdenv.packages) pdenv;
in
{
  home.packages = with pkgs; [
    pdenv
    neovim-remote
  ];
}
