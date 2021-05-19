{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hurricane.configs.tmux;
  zshrcBeforeCompInit = (import ./zshrc-BeforeCompInit.nix pkgs).zshrcBeforeCompInit;
  zshrcExtra = (import ./zshrc-extra.nix pkgs).zshrcExtra;
  tmuxConf = (import ./tmux-conf.nix { inherit lib config; }).tmuxConf;
in
{

  options.hurricane = { configs.tmux.enable = mkEnableOption "enable awseome tmux config"; };
  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      (writeScriptBin "tmux-popup" (builtins.readFile ./tmux-popup))
      (writeScriptBin "tmux-cleanup" (builtins.readFile ./tmux-cleanup))
      (writeScriptBin "yank" (builtins.readFile ./yank))
    ];

    programs.tmux = {
      enable = true;
      aggressiveResize = true;
      baseIndex = 1;
      customPaneNavigationAndResize = false;
      keyMode = "vi";
      newSession = false;
      shortcut = "a";
      terminal = "screen-256color";
      resizeAmount = 10;
      historyLimit = 10000;
      plugins = with pkgs; [
        tmuxPlugins.copycat
        tmuxPlugins.jump
        {
          plugin = tmuxPlugins.extrakto;
          extraConfig = ''
            set -g set-clipboard on

            set -g @extrakto_clip_tool_run "fg"
            set -g @extrakto_clip_tool "yank"
            set -g @extrakto_popup_size "65%"
            set -g @extrakto_grab_area "window 500"
          '';
        }
      ];
      extraConfig = tmuxConf;
    };

    # Adding helper functions to improve zsh and tmux
    programs.zsh.initExtraBeforeCompInit = zshrcBeforeCompInit;
    programs.zsh.initExtra = zshrcExtra;
  };
}
