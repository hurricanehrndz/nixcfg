{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hurricane.profiles.development;
in
{
  options.hurricane.profiles.development = {
    enable = mkEnableOption "development configuration";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = with pkgs; [
        nixfmt
        direnv
        nix-direnv
        powershell
        powershell-es
        # Tree-Sitter
        # see: https://github.com/breuerfelix/nixos/commit/f6aaf6d75e9a847a91e16314752c9d6614e1b04c#diff-fad35a4bb4e2335be1b89e3563ec9be3946208467db9de26226674db7469b6d4R41-R44
        gcc gccStdenv
        poetry
        (python38.withPackages (ps: with ps; [ pip ]))
      ];

      xdg.dataFile."pses".source =
        "${pkgs.powershell-es}/share/PowerShellEditorServices";

      hurricane.configs = {
        neovim.enable = true;
        git.enable = true;
      };
    }

    (mkIf (pkgs.stdenv.isLinux) {
      home.packages = with pkgs; [
        sumneko-lua-language-server
      ];
      xdg.dataFile."lua-lsp".source =
        "${pkgs.sumneko-lua-language-server}/extras";
    })

  ]);
}
