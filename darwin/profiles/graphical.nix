{
  pkgs,
  config,
  ...
}: let
  inherit (config.homebrew) brewPrefix;
in {
  security.pam.enableSudoTouchIdAuth = true;

  # Allow for usage of `brew` CLI without adding to `PATH`
  environment.shellAliases."brew" = "${brewPrefix}/brew";

  homebrew.taps = [
    "homebrew/cask"
    "homebrew/cask-versions"
  ];

  # $ networksetup -listallnetworkservices
  # networking.knownNetworkServices = [
  #   "Wi-Fi"
  #   "Thunderbolt Bridge"
  # ];

  homebrew.casks = [
    "discord"
    "element"
    "eloston-chromium" #          <- aka "ungoogled-chromium" in nixpkgs
    "firefox-developer-edition"
    "flameshot"
    "keycastr"
    "powershell"
    "raindropio"
    "raycast"
    "slack"
    "utm"
    "visual-studio-code"
    "vlc"
  ];

  homebrew.masApps = {
    "Tailscale" = 1475387142;
    "Xcode" = 497799835;
    "Microsoft Remote Desktop" = 1295203466;
  };
}
