{ config, lib, pkgs, ... }:

with lib;
let cfg = config.hurricane.profiles.development;
in {
  options.hurricane.profiles.development = {
    enable = mkEnableOption "development configuration";
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = with pkgs; [
        nixfmt
        nix-direnv
        powershell
        powershell-es
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
      home.packages = with pkgs; [ sumneko-lua-language-server ];
      xdg.dataFile."lua-lsp".source =
        "${pkgs.sumneko-lua-language-server}/extras";
    })

  ]);
}
