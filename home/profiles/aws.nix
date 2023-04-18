{
  pkgs,
  packages,
  lib,
  ...
}: let
  inherit (pkgs.stdenv) isDarwin;
in {
  home.packages =
    [pkgs.awscli]
    ++ lib.optionals isDarwin [
      packages.aws-sso
    ];
}
