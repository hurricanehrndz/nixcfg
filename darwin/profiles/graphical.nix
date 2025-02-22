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
    "ktr0731/evans"
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
  ];

  homebrew.masApps = {
    "Tailscale" = 1475387142;
  };
}
