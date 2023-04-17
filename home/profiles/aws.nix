{pkgs, packages, lib, ...}: let
  inherit (pkgs.stdenv) isDarwin;
in {
  home.packages = [ pkgs.awscli2 ];
}
