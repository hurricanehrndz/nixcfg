{
  config,
  ...
}: let
  inherit (config.homebrew) brewPrefix;
in {
  # security.pam.enableSudoTouchIdAuth = true;

  # Allow for usage of `brew` CLI without adding to `PATH`
  environment.shellAliases."brew" = "${brewPrefix}/brew";

  homebrew.taps = [
    "nikitabobko/tap"
  ];

  # $ networksetup -listallnetworkservices
  # networking.knownNetworkServices = [
  #   "Wi-Fi"
  #   "Thunderbolt Bridge"
  # ];

  homebrew.casks = [
    "aerospace"
    "apparency"
    "ghostty"
    "keycastr"
    "powershell"
    "utm"
    "vlc"
    "wezterm"
    "superkey"
  ];

  homebrew.masApps = {
    "Tailscale" = 1475387142;
  };
}
