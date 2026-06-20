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
    onActivation.upgrade = true;
    onActivation.autoUpdate = true;
    # Homebrew 6 refuses to load formulae from custom-remote taps (e.g.
    # `jundot/omlx`, see programs/ai.nix) until they're trusted via `brew
    # trust`, which otherwise prompts interactively during activation. Opt out
    # of the trust check for the unattended `brew bundle` run; activation runs
    # under sudo, so this isn't inherited from the user's shell env.
    onActivation.extraEnv.HOMEBREW_NO_REQUIRE_TAP_TRUST = "1";
    # Homebrew 6 deprecated the bare `--cleanup` switch that nix-darwin's
    # `onActivation.cleanup = "zap"` emits ("Calling the --cleanup switch is
    # deprecated"). Keep cleanup off in the module and drive it ourselves via
    # the live `--force-cleanup --zap` flags, which run the same
    # `brew bundle cleanup` machinery non-interactively without the warning.
    onActivation.cleanup = "none";
    onActivation.extraFlags = [
      "--force-cleanup"
      "--zap"
    ];
  };
}
