{ config, ... }:

{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };

    overlays = [
      (final: prev: {
        local = config.packages;
      })
    ];
  };
}
