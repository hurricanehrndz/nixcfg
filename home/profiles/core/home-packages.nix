{
  pkgs,
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

    # grpc
    evans

    # attempting to use yubikey for age
    age-plugin-yubikey
  ];
}
