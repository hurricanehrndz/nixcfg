{
  config,
  ...
}:
let
  inherit (config.homebrew) brewPrefix;
in
{
  # security.pam.enableSudoTouchIdAuth = true;

  # Allow for usage of `brew` CLI without adding to `PATH`
  environment.shellAliases."brew" = "${brewPrefix}/brew";

  # $ networksetup -listallnetworkservices
  # networking.knownNetworkServices = [
  #   "Wi-Fi"
  #   "Thunderbolt Bridge"
  # ];

  homebrew.casks = [
    "apparency"
    "ghostty"
    "keycastr"
    "powershell"
    "utm"
    "vlc"
    "wezterm"
    "windows-app"
  ];

  programs.superkey.enable = true;
  programs.aerospace.enable = true;
  programs.aerospace.settings = builtins.readFile ./aerospace.toml;

  homebrew.masApps = {
    "Tailscale" = 1475387142;
  };
}
