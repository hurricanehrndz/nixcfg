{
  inputs,
  self,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  braveOriginPkgs = import inputs.nixpkgs-brave-origin {
    inherit system;
    config.allowUnfree = true;
  };

  # Brave publishes public Origin Beta versions per-platform. Use those pins
  # instead of the newest GitHub asset so browser packages do not jump ahead of
  # public releases.
  braveOriginBetaSources = builtins.fromJSON (builtins.readFile ./brave-origin-beta-sources.json);
in
{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };

    overlays = [
      inputs.agenix.overlays.default
      inputs.snapraid-runner.overlays.default

      (final: prev: {
        local = self.packages.${system};
        master = import inputs.nixpkgs-master {
          inherit system;
          config.allowUnfree = true;
        };
        unstable = import inputs.nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };

        brave-origin-beta =
          let
            source = braveOriginBetaSources.${system} or null;
          in
          if source == null then
            braveOriginPkgs.brave-origin-beta
          else
            braveOriginPkgs.brave-origin-beta.overrideAttrs (_: {
              inherit (source) version;
              src = final.fetchurl {
                inherit (source) url hash;
              };
            });

        inherit (braveOriginPkgs) brave-origin-nightly;
      })
    ];
  };
}
