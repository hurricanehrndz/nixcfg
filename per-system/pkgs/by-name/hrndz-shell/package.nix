# The desktop shell: a fork of Omarchy's Quickshell shell (shell/ in
# basecamp/omarchy 4.0.0.alpha, rev c668141e9c42b13c80c9ca4ea108e11708c5e8a5),
# no longer tracking upstream. Kept: bar, menu, clipboard, emojis, lock,
# notifications, OSD, polkit, background, services and the bar panels. The
# omarchy-* scripts it called are replaced by scripts/, and its theme,
# config and plugin-install machinery by files Home Manager writes (see
# modules/internal/home/desktop/hyprland/shell/). Internal ids such as
# `omarchy.bar` keep their upstream names.
{
  lib,
  stdenvNoCC,
  writeShellApplication,
  runCommand,
  brightnessctl,
  coreutils,
  findutils,
  fontconfig,
  gawk,
  gnugrep,
  grim,
  gtk3,
  hyprland,
  hyprpicker,
  jq,
  libnotify,
  perl,
  procps,
  quickshell,
  satty,
  slurp,
  systemd,
  wireplumber,
  wl-clipboard,
  wtype,
  xdg-utils,
}:
let
  script =
    name: runtimeInputs:
    writeShellApplication {
      inherit name runtimeInputs;
      text = builtins.readFile ./scripts/${name}.sh;
    };

  cli = script "hrndz-shell" [
    brightnessctl
    coreutils
    findutils
    gawk
    grim
    hyprland
    hyprpicker
    jq
    procps
    quickshell
    satty
    slurp
    systemd
    wireplumber
    wl-clipboard
  ];

  # Called by the QML as <share>/bin/<name>.
  helpers = lib.mapAttrs script {
    clipboard-capture = [
      coreutils
      gawk
      gnugrep
      jq
      perl
      wl-clipboard
    ];
    clipboard-paste = [
      coreutils
      jq
      wl-clipboard
      wtype
    ];
    clipboard-open = [
      coreutils
      gnugrep
      jq
      xdg-utils
    ];
    emoji-insert = [
      coreutils
      wl-clipboard
      wtype
    ];
    focus-app = [
      hyprland
      jq
    ];
    session-locked = [
      hyprland
      jq
    ];
    dpms = [
      hyprland
      jq
    ];
  };

  # The icon font the bar and menu glyphs use. Its own derivation so the
  # NixOS font list and the Home Manager package share one build.
  font = runCommand "hrndz-shell-font" { } ''
    install -Dm444 ${./fonts/omarchy.ttf} $out/share/fonts/truetype/omarchy.ttf
  '';
in
stdenvNoCC.mkDerivation {
  pname = "hrndz-shell";
  version = "4.0.0-alpha-fork";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./shell
      ./theme
      ./menu.jsonc
    ];
  };

  installPhase = ''
    runHook preInstall

    share=$out/share/hrndz-shell
    mkdir -p $share/bin $out/bin
    cp -r shell theme menu.jsonc $share/
    ln -s ${lib.getExe cli} $out/bin/hrndz-shell
    ${lib.concatMapAttrsStringSep "\n" (
      name: drv: "ln -s ${lib.getExe drv} $share/bin/${name}"
    ) helpers}

    # Store paths for the commands the QML runs that are not in every
    # session's PATH.
    find $share -type f \( -name '*.qml' -o -name '*.js' -o -name '*.jsonc' \) -print0 |
      while IFS= read -r -d "" f; do
        substituteInPlace "$f" \
          --subst-var-by shareDir "$share" \
          --subst-var-by hrndzShell "$out/bin/hrndz-shell" \
          --subst-var-by fcMatch "${lib.getExe' fontconfig "fc-match"}" \
          --subst-var-by gtkLaunch "${lib.getExe' gtk3 "gtk-launch"}" \
          --subst-var-by notifySend "${lib.getExe libnotify}" \
          --subst-var-by systemdInhibit "${lib.getExe' systemd "systemd-inhibit"}"
      done
    if grep -rnE '@[a-zA-Z]+@' $share --include='*.qml' --include='*.js' --include='*.jsonc'; then
      echo "unsubstituted placeholders above" >&2
      exit 1
    fi

    runHook postInstall
  '';

  passthru = { inherit font; };

  meta = {
    description = "Personal Quickshell desktop shell, forked from Omarchy's";
    license = lib.licenses.mit;
    mainProgram = "hrndz-shell";
    platforms = lib.platforms.linux;
  };
}
