{
  pkgs,
  config,
  ...
}: let
  inherit (config.homebrew) brewPrefix;
in {
  # security.pam.enableSudoTouchIdAuth = true;

  # Allow for usage of `brew` CLI without adding to `PATH`
  environment.shellAliases."brew" = "${brewPrefix}/brew";

  homebrew.taps = [
    "homebrew/cask-versions"
  ];

  # $ networksetup -listallnetworkservices
  # networking.knownNetworkServices = [
  #   "Wi-Fi"
  #   "Thunderbolt Bridge"
  # ];

  homebrew.casks = [
    "amethyst"
    "apparency"
    "discord"
    "element"
    "logseq"
    "keycastr"
    "powershell"
    "raindropio"
    "utm"
    "vlc"
    "wezterm"
  ];

  homebrew.masApps = {
    "Tailscale" = 1475387142;
  };
}
