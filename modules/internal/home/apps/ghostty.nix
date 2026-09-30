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
  noctisThemes = "${inputs.noctis-themes-src}/ghostty";
in
{
  config = mkIf cfg.roles.developerWorkstation.enable {
    # Noctis themes, vendored from https://github.com/EastSun5566/noctis-themes
    # (not built into ghostty). Each file is linked into
    # $XDG_CONFIG_HOME/ghostty/themes/, making every theme selectable by name
    # while leaving room for the Stylix theme.
    xdg.configFile = lib.mapAttrs' (
      name: _: lib.nameValuePair "ghostty/themes/${name}" { source = "${noctisThemes}/${name}"; }
    ) (builtins.readDir noctisThemes);
    programs.ghostty = {
      # ghostty installed via Homebrew
      package = if isDarwin then pkgs.ghostty-bin else pkgs.unstable.ghostty;
      enable = true;
      # HM's snippet is dropped by our mkForce'd initContent; zsh sources it.
      enableZshIntegration = false;
      settings = {
        # null means Stylix sets it from the scheme (see ../theme.nix).
        theme = mkIf (cfg.theme.ghostty != null) cfg.theme.ghostty;
        window-theme = "ghostty";
        font-size = mkIf (!isDarwin) 11;
        # disable automatic injection - zsh sources it (../shells/zsh)
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
