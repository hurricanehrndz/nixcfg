{
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in
{
  environment.variables = {
    EDITOR = "vim";
    KERNEL_NAME = if isDarwin then "darwin" else "linux";
    LC_ALL = "en_US.UTF-8";
    LANG = "en_US.UTF-8";
    PAGER = "less";
    LESS = "-R";
  };
}
