{
  pkgs,
  inputs',
  ...
}:
let
  inherit (inputs'.devenv.packages) devenv;
in
{
  home.packages = [
    devenv
  ];
}
