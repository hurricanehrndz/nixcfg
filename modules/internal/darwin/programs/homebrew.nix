{ lib, pkgs, ... }:
let
  inherit (lib) mkBefore;
  inherit (pkgs.stdenv.hostPlatform) isAarch64;
  brewPrefix = if isAarch64 then "/opt/homebrew" else "/usr/local";
in
{
  # <https://github.com/LnL7/nix-darwin/issues/596>
  #
  # $ brew shellenv
  # export HOMEBREW_PREFIX="/opt/homebrew";
  # export HOMEBREW_CELLAR="/opt/homebrew/Cellar";
  # export HOMEBREW_REPOSITORY="/opt/homebrew";
  # export PATH="/opt/homebrew/bin:/opt/homebrew/sbin${PATH+:$PATH}";
  # export MANPATH="/opt/homebrew/share/man${MANPATH+:$MANPATH}:";
  # export INFOPATH="/opt/homebrew/share/info:${INFOPATH:-}";
  environment.systemPath = mkBefore [
    "${brewPrefix}/bin"
    "${brewPrefix}/sbin"
  ];

  # Allow for usage of `brew` CLI without adding to `PATH`
  environment.shellAliases."brew" = "${brewPrefix}/bin/brew";

  environment.variables = {
    HOMEBREW_PREFIX = brewPrefix;
    HOMEBREW_CELLAR = "${brewPrefix}/Cellar";
    HOMEBREW_REPOSITORY = brewPrefix;
    INFOPATH = "${brewPrefix}/share/info:\${INFOPATH:-}";
    MANPATH = "${brewPrefix}/share/man\${MANPATH+:$MANPATH}:";
  };

  homebrew = {
    enable = true;
    # Use the nix-darwin brewfile when invoking `brew bundle` imperatively.
    global.brewfile = true;
    caskArgs.no_quarantine = true;
    onActivation.cleanup = "zap";
    onActivation.upgrade = true;
    onActivation.autoUpdate = true;
  };
}
