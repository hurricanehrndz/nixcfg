{
  config,
  lib,
  pkgs,
  ...
}:
let
  # The one command bindings and autostart call for what the desktop shell
  # provides: `hrndz-shell <feature> [args]`. Wiring the shell means editing
  # this table.
  # TODO(phase2): point every feature at the forked QuickShell shell. Until
  # then each one logs "TODO(phase2): <feature>" (journalctl --user -t hrndz-shell).
  hrndzShell = pkgs.writeShellApplication {
    name = "hrndz-shell";
    runtimeInputs = [ pkgs.systemd ];
    text = ''
      todo() {
        echo "TODO(phase2): $*" | systemd-cat -t hrndz-shell
      }

      feature="''${1:-}"
      shift || true
      case "$feature" in
        start) todo start "$@" ;;
        launcher) todo launcher "$@" ;;
        menu) todo menu "$@" ;;
        system-menu) todo system-menu "$@" ;;
        keybindings) todo keybindings "$@" ;;
        clipboard) todo clipboard "$@" ;;
        emoji) todo emoji "$@" ;;
        lock) todo lock "$@" ;;
        bar) todo bar "$@" ;;
        # osd <volume|microphone|brightness>
        osd) todo osd "$@" ;;
        # notifications <dismiss-one|dismiss-all|invoke-last|history>
        notifications) todo notifications "$@" ;;
        # panel <audio|bluetooth|network|power|display|calendar>
        panel) todo panel "$@" ;;
        *)
          echo "hrndz-shell: unknown feature: $feature" >&2
          exit 2
          ;;
      esac
    '';
  };
in
{
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    home.packages = [ hrndzShell ];
  };
}
