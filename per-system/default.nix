{ inputs, ... }:
{
  imports = with inputs; [
    # nixpkgs
    ./args.nix

    # formatter
    ./formatter.nix

    # packages
    ./pkgs

    # define shells
    (import-tree ./shells)
  ];
}
