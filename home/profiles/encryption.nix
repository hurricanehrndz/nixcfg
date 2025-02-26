{
  pkgs,
  packages,
  ...
}: {
  home.packages = with pkgs; [
    sops
    age
    packages.strongbox
    packages.strongbox-init
  ];
}
