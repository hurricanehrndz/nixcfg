{
  lib,
  pkgs,
  osConfig,
  inputs,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  cfg = osConfig.hrndz;
in
{
  config = mkIf cfg.roles.guiDeveloper.enable {
    # Noctis themes, vendored from https://github.com/EastSun5566/noctis-themes
    # (not built into ghostty). Links the repo's ghostty/ dir into
    # $XDG_CONFIG_HOME/ghostty/themes/, making every theme selectable by name.
    xdg.configFile."ghostty/themes".source = "${inputs.noctis-themes-src}/ghostty";
    programs.ghostty = {
      # ghostty installed via Homebrew
      package = if isDarwin then pkgs.ghostty-bin else pkgs.unstable.ghostty;
      enable = true;
      # disable nix's integration
      enableZshIntegration = false;
      settings = {
        theme = "noctis-lux";
        window-theme = "light";
        # disable automatic injection - we do it in zsh
        shell-integration = "none";
        # background-opacity = 0.80;
        background-opacity-cells = true;
        background-blur-radius = 16;
        # window-decoration = false;
        shell-integration-features = "sudo,no-ssh-terminfo,no-ssh-env,cursor";
        clipboard-paste-protection = false;
        # window-show-tab-bar = "never";
        # # Prefer windows over tabs: make ⌘T open a new window like ⌘N.
        # keybind = "super+t=new_window";
        macos-titlebar-style = "hidden";
        window-padding-y = "6,0";
        macos-option-as-alt = true;
        # window-padding-color = "extend";
      };
    };
  };
}
