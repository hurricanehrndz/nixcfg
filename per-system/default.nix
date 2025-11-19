{ inputs, ... }:
{
  imports = with inputs; [
    # nixpkgs
    ./args.nix

    # formatter
    ./formatter.nix
    ./treefmt.nix

    # packages
    ./pkgs

    # define shells
    (import-tree ./shells)
  ];
}
