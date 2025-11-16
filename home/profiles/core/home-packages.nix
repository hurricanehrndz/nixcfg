{
  pkgs,
  packages,
  ...
}:
{
  home.packages = with pkgs; [
    bottom
    eza
    fd # <- faster projectile indexing
    sd
    fx # <- interactive terminal json viewer                  => <https://github.com/antonmedv/fx>
    glow # <- charmbracelet's markdown cli renderer
    (ripgrep.override { withPCRE2 = true; })
    gtrash
    yq

    # TODO: joy ride
    lsd
    grex

    # AI
    mods
    packages.gpt

    # grpc
    evans
  ];
}
