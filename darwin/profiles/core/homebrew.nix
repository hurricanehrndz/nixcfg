{ inputs
, pkgs
, ...
}:
let
  l = inputs.nixpkgs.lib // builtins;
  inherit (pkgs.stdenv.hostPlatform) isAarch64;
  brewPrefix =
    if isAarch64
    then "/opt/homebrew"
    else "/usr/local";
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
  environment.systemPath = l.mkBefore [ "${brewPrefix}/bin" "${brewPrefix}/sbin" ];
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
    brews = [
      "7zip"
      "aspell"
      "carthage"
      "cloudflare-wrangler2"
      "docker"
      "docker-compose"
      "fswatch"
      "go"
      "goreleaser"
      "gost"
      "grpc-swift"
      "hunspell"
      "lazydocker"
      "lima"
      "makensis"
      "mingw-w64"
      "mtr"
      "pipx"
      "pre-commit"
      "virtualenv"
      "python@3.12"
      "python@3.10"
      "rbenv"
      "ruby@3.2"
      "shellcheck"
      "sponge"
      "wakeonlan"
      "wireguard-tools"
    ];
    casks = [
    ];
  };
}
