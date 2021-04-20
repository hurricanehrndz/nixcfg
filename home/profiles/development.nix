{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hurricane.profiles.development;
in
{
  options.hurricane.profiles.development = {
    enable = mkEnableOption "development configuration";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      nixfmt
      direnv
      nix-direnv
      powershell
      poetry
      (python38.withPackages (ps: with ps; [ pip ]))
    ];

    hurricane.configs = {
      neovim.enable = true;
      git.enable = true;
      luaformatter.enable = true;
    };
  };
}

