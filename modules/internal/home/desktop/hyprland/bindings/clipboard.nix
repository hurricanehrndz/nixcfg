{
  config,
  lib,
  ...
}:
let
  inherit (import ./_lib.nix { inherit lib; }) bind exec;
  inherit (lib.generators) mkLuaInline;
in
{
  # Universal clipboard: SUPER + C/V/X work the same in every app, terminals
  # included. The shortcut goes to the focused surface with explicit mods, so
  # it also reaches layer-shell panels. The down/up split works around
  # send_shortcut sometimes leaving synthetic keys stuck.
  # https://github.com/hyprwm/Hyprland/discussions/14099
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    wayland.windowManager.hyprland.settings = {
      # universal_shortcut(mods, key[, terminal_mods, terminal_key]) returns a
      # bind action. Terminals carry the "terminal" tag from rules.nix; dynamic
      # tags have a trailing "*". Terminals get CTRL + SHIFT, not the Insert
      # keys: SHIFT + Insert pastes the primary selection in Ghostty, kitty and
      # Alacritty, so it would miss what tmux copied over OSC 52.
      universal_shortcut._var = mkLuaInline ''
        function(mods, key, terminal_mods, terminal_key)
          local function is_terminal()
            local window = hl.get_active_window()
            for _, tag in ipairs(window and window.tags or {}) do
              if tag:gsub("%*$", "") == "terminal" then
                return true
              end
            end
            return false
          end

          return function()
            local m, k = mods, key
            if terminal_mods and is_terminal() then
              m, k = terminal_mods, terminal_key
            end
            hl.dispatch(hl.dsp.send_key_state({ mods = m, key = k, state = "down" }))
            hl.timer(function()
              hl.dispatch(hl.dsp.send_key_state({ mods = m, key = k, state = "up" }))
            end, { timeout = 50, type = "oneshot" })
          end
        end'';

      bind = [
        (bind "SUPER + C" "Universal copy" ''universal_shortcut("CTRL", "C", "CTRL + SHIFT", "C")'')
        (bind "SUPER + V" "Universal paste" ''universal_shortcut("CTRL", "V", "CTRL + SHIFT", "V")'')
        (bind "SUPER + X" "Universal cut" ''universal_shortcut("CTRL", "X")'')
        (bind "SUPER + CTRL + V" "Clipboard history" (exec "hrndz-shell clipboard"))
      ];
    };
  };
}
