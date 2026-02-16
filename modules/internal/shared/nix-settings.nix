{
  lib,
  options,
  pkgs,
  inputs,
  ...
}:
let
  l = lib // builtins;
  inputFlakes = l.filterAttrs (_: v: v ? outputs) inputs;
  inputsToPaths = l.mapAttrs' (
    n: v: {
      name = "nix/inputs/${n}";
      value.source = v.outPath;
    }
  );

  mkCustomNixSettings = isDarwin: {
    accept-flake-config = true;
    auto-optimise-store = true;
    builders-use-substitutes = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    fallback = true;
    keep-derivations = true;
    keep-outputs = true;
    max-jobs = "auto";
    warn-dirty = false;

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-update.cachix.org-1:6y6Z2JdoL3APdu6/+Iy8eZX2ajf09e4EE9SnxSML1W8="
      "hurricanehrndz.cachix.org-1:rKwB3P3FZ0T0Ck1KierCaO5PITp6njsQniYlXPVhFuA="
    ];

    substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://nixpkgs-update.cachix.org"
      "https://hurricanehrndz.cachix.org"
    ];

    trusted-users = if isDarwin then [ "@admin" ] else [ "@wheel" ];
  };
in
{
  config = l.mkMerge [
    {
      environment.etc = inputsToPaths inputs;
      nix.registry = l.mkForce (l.mapAttrs (_: flake: { inherit flake; }) inputFlakes);
      nix.nixPath = [
        "nixpkgs=${pkgs.path}"
        "home-manager=${inputs.home-manager}"
        "/etc/nix/inputs"
      ]
      ++ (l.optional pkgs.stdenv.hostPlatform.isDarwin "darwin=${inputs.darwin}");
    }
    (l.mkIf pkgs.stdenv.hostPlatform.isLinux {
      nix.settings = mkCustomNixSettings false;
      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
    })
    (l.mkIf pkgs.stdenv.hostPlatform.isDarwin (
      {
        nix.enable = false;
      }
      // l.optionalAttrs (options ? determinateNix) {
        determinateNix = {
          enable = true;
          customSettings = mkCustomNixSettings true;
          registry = l.mapAttrs (_: flake: { inherit flake; }) inputFlakes;
          determinateNixd = {
            builder.state = "enabled";
            garbageCollector.strategy = "automatic";
          };
        };
      }
    ))
  ];
}
