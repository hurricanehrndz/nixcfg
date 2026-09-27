{
  config,
  lib,
  osConfig,
  ...
}:
let
  inherit (import ../bindings/_lib.nix { inherit lib; }) namedWorkspaces;
  inherit (osConfig.hrndz.desktop.hyprland) weather;

  # The whole shell config: the shell reads it and never writes it. Settings
  # changed in the UI (tray pins, clock format and the like) go to
  # ~/.local/state/hrndz-shell/settings.json and are laid over this.
  shellConfig = {
    version = 1;
    bar = {
      position = "top";
      transparent = false;
      centerAnchor = "omarchy.clock";
      layout = {
        left = [
          { id = "omarchy.menu"; }
          {
            id = "omarchy.workspaces";
            named = namedWorkspaces;
          }
        ];
        center = [
          { id = "omarchy.indicators"; }
          {
            id = "omarchy.clock";
            format = "dddd HH:mm";
            formatAlt = "d MMMM 'W'ww yyyy";
            verticalFormat = "HH\n—\nmm";
          }
          (
            {
              id = "omarchy.weather";
            }
            // lib.optionalAttrs (weather.location != null) { inherit (weather) location; }
          )
        ];
        # The agents widget hides itself until a usage record has numbers.
        right = map (id: { id = "omarchy.${id}"; }) (
          [ "tray" ]
          ++ lib.optional osConfig.hrndz.tooling.ai.enable "agents"
          ++ [
            "bluetooth"
            "network"
          ]
          ++ lib.optional osConfig.services.tailscale.enable "tailscale"
          ++ [
            "audio"
            "monitor"
            "power"
          ]
        );
      };
    };
    plugins = [ ];
  };

  # Desktop entries the launcher leaves out: avahi's browsers.
  launcherHides = [
    "avahi-discover"
    "bssh"
    "bvnc"
  ];

  # "KEYS → description" for every described binding, for the keybindings
  # list.
  keybindings =
    let
      pad = width: s: s + lib.concatStrings (lib.replicate (lib.max 0 (width - lib.stringLength s)) " ");
      line =
        entry:
        let
          # code:10 .. code:19 are the 1 .. 0 keys.
          keys = lib.replaceStrings (map (n: "code:${toString (n + 9)}") (lib.range 1 10)) (map (
            n: toString (lib.mod n 10)
          ) (lib.range 1 10)) (lib.elemAt entry._args 0);
          opts = lib.elemAt entry._args 2;
        in
        lib.optional (opts.description or "" != "") "${pad 35 keys} → ${opts.description}";
    in
    lib.concatMap line config.wayland.windowManager.hyprland.settings.bind;
in
{
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    xdg.configFile = {
      "hrndz-shell/shell.json".text = builtins.toJSON shellConfig;
      "hrndz-shell/launcher.hides".text = lib.concatLines launcherHides;
      "hrndz-shell/keybindings.txt".text = lib.concatLines keybindings;
      # Without an image the desktop is the scheme's background colour.
      "hrndz-shell/background" = lib.mkIf (config.stylix.image != null) {
        source = config.stylix.image;
      };
    };
  };
}
