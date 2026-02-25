{ lib, ... }:
{
  options.system.primaryUser = lib.mkOption {
    type = lib.types.str;
    description = "The primary user of the system. Mirrors the nix-darwin option for shared module compatibility.";
  };
}
