{
  pkgs,
  inputs',
  ...
}: let
  inherit (inputs'.devenv_pr507.packages) devenv;
in {
  home.packages = [
    devenv
  ];
}
