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
      "pre-commit"
      "shellcheck"
      "rbenv"
      "ruby-install"
      "lima"
      "docker"
      "docker-compose"
      "pipx"
      "gost"
      "python@3.10"
      "wakeonlan"
      "swiftlint"
      "swiftformat"
      "carthage"
      "bumpversion"
      "makensis"
      "go"
      "sponge"
      "goreleaser"
      "swift-protobuf"
      "grpc-swift"
      "evans"
      "knot"
      "7zip"
      "mingw-w64"
      "mtr"
      "wireguard-tools"
      "fswatch"
      "7zip"
    ];
    casks = [
      "remoteviewer"
      "devpod"
      "postman"
    ];
  };
}
