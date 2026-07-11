{
  lib,
  options,
  pkgs,
  inputs,
  ...
}:
let
  l = lib // builtins;

  # Only inputs that are themselves flakes (have `outputs`). Raw-source inputs
  # (e.g. zsh plugins) lack flake metadata and can't go in the registry, so we
  # filter them out here before feeding `nix.registry`.
  inputFlakes = l.filterAttrs (_: v: v ? outputs) inputs;

  # Maps every input to an `environment.etc` entry symlinking its source into
  # /etc/nix/inputs/<name>. `outPath` is valid for all inputs (flake or not),
  # so this exposes the full set for legacy `<name>` (NIX_PATH) lookups.
  inputsToPaths = l.mapAttrs' (
    n: v: {
      name = "nix/inputs/${n}";
      value.source = v.outPath;
    }
  );
in
{
  config = l.mkMerge [
    {
      # Symlink every input source into /etc/nix/inputs/<name>.
      environment.etc = inputsToPaths inputs;
      nix.enable = true;
      nix.package = pkgs.lixPackageSets.latest.lix;

      # Pin the flake registry to our locked inputs so `nix run nixpkgs#...`
      # resolves to the local store path instead of fetching/re-locking.
      nix.registry = l.mkForce (l.mapAttrs (_: flake: { inherit flake; }) inputFlakes);

      # NIX_PATH for legacy `<nixpkgs>`-style lookups; /etc/nix/inputs (above)
      # makes every input resolvable as `<name>`.
      nix.nixPath = [
        "nixpkgs=${pkgs.path}"
        "home-manager=${inputs.home-manager}"
        "/etc/nix/inputs"
      ]
      ++ (l.optional pkgs.stdenv.hostPlatform.isDarwin "nix-darwin=${inputs.nix-darwin}");

      nix.settings = {
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
          "pi.cachix.org-1:lGeoGJaZ5ZDabuRzkcD5EBTNnDM4HJ1vqeOxlWk1Flk="
          "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
          "nixpkgs-update.cachix.org-1:6y6Z2JdoL3APdu6/+Iy8eZX2ajf09e4EE9SnxSML1W8="
          "hurricanehrndz.cachix.org-1:rKwB3P3FZ0T0Ck1KierCaO5PITp6njsQniYlXPVhFuA="
          "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        ];

        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
          "https://pi.cachix.org"
          "https://cache.lix.systems"
          "https://nixpkgs-update.cachix.org"
          "https://hurricanehrndz.cachix.org"
          "https://devenv.cachix.org"
        ];

        trusted-users = if pkgs.stdenv.hostPlatform.isDarwin then [ "@admin" ] else [ "@wheel" ];
      };

      nix.gc = {
        automatic = true;
        options = "--delete-older-than 30d";
      };
    }
    (l.mkIf pkgs.stdenv.hostPlatform.isDarwin (
      l.optionalAttrs (options ? nix && options.nix ? gc && options.nix.gc ? interval) {
        nix.gc.interval = {
          Weekday = 0;
          Hour = 2;
          Minute = 0;
        };
      }
    ))
    (l.mkIf pkgs.stdenv.hostPlatform.isLinux {
      nix.gc.dates = "weekly";
    })
  ];
}
