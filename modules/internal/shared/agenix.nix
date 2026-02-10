{ lib, pkgs, ... }:

{
  age.ageBin = lib.mkDefault "PATH=$PATH:${lib.makeBinPath [ pkgs.age-plugin-yubikey ]} ${pkgs.age}/bin/age";
}
