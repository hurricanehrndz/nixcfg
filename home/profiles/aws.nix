{
  pkgs,
  packages,
  lib,
  inputs',
  ...
}: let
  inherit (inputs'.git-fat.packages) git-fat;
  inherit (pkgs.stdenv) isDarwin;
in {
  home.packages =
    [
      pkgs.awscli
    ];
}
