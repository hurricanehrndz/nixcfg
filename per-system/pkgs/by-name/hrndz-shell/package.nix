# The desktop shell: a fork of Omarchy's Quickshell shell (shell/ in
# omacom/omarchy 4.0.0.alpha, rev c668141e9c42b13c80c9ca4ea108e11708c5e8a5),
# no longer tracking upstream. Kept: bar, menu, clipboard, emojis, lock,
# notifications, OSD, polkit, background, services and the bar panels. The
# omarchy-* scripts it called are replaced by scripts/, and its theme,
# config and plugin-install machinery by files Home Manager writes (see
# modules/internal/home/desktop/hyprland/shell/). Internal ids such as
# `omarchy.bar` keep their upstream names.
{
  lib,
  # Where `ambient-set` (NixOS module) keeps the ambient video and still.
  ambientDir ? "/var/lib/ambient",
  playbackRate ? 1.0,
  lockBlankSeconds ? 60,
  stdenvNoCC,
  writeShellApplication,
  writeTextFile,
  bluez,
  brightnessctl,
  coreutils,
  ffmpeg-headless,
  findutils,
  fontconfig,
  gawk,
  geoclue2,
  gnugrep,
  gnused,
  gpu-screen-recorder,
  grim,
  gtk3,
  hyprland,
  hyprpicker,
  iproute2,
  iw,
  jq,
  libnotify,
  mpv,
  networkmanager,
  omasnap,
  perl,
  power-profiles-daemon,
  procps,
  pulseaudio,
  python3,
  qt6,
  runCommand,
  quickshell,
  ripgrep,
  slurp,
  systemd,
  v4l-utils,
  upower,
  util-linux,
  wireplumber,
  wl-clipboard,
  wtype,
  xdg-utils,
  zbar,
  zenity,
}:
let
  # The screensaver and lock screen play video through QtMultimedia (its
  # FFmpeg backend), which nixpkgs' Quickshell leaves out.
  quickshell' = quickshell.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [ qt6.qtmultimedia ];
  });

  script =
    name: runtimeInputs:
    writeShellApplication {
      inherit name runtimeInputs;
      text = builtins.readFile ./scripts/${name}.sh;
    };

  # The agent usage collectors: Python, as Omarchy wrote them.
  collector =
    name:
    writeTextFile {
      inherit name;
      executable = true;
      destination = "/bin/${name}";
      text = "#!${python3.interpreter}\n" + builtins.readFile ./scripts/${name}.py;
    };

  # Omarchy's notification sender; omasnap and screenrecord call it.
  notificationSend = script "omarchy-notification-send" [
    jq
    systemd
  ];

  # gpu-screen-recorder finds its capture helper in /run/wrappers/bin, which
  # the NixOS module's programs.gpu-screen-recorder provides. OCR shares
  # omasnap's English-only tesseract; zbarimg (QR) needs no camera or X
  # support.
  cli = script "hrndz-shell" [
    brightnessctl
    coreutils
    ffmpeg-headless
    findutils
    gawk
    gpu-screen-recorder
    grim
    hyprland
    hyprpicker
    jq
    mpv
    notificationSend
    omasnap
    omasnap.tesseract
    procps
    quickshell'
    slurp
    systemd
    (v4l-utils.override { withGUI = false; })
    wireplumber
    wl-clipboard
    (zbar.override {
      enableVideo = false;
      withXorg = false;
    })
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
      cli
      hyprland
      jq
    ];

    # The panels' helpers. ping stays off these lists: the session PATH's
    # /run/wrappers/bin/ping carries the capability a store ping lacks.
    audio = [
      coreutils
      gawk
      pulseaudio
      wireplumber
    ];
    bluetooth = [
      bluez
      coreutils
      gawk
      util-linux
    ];
    network = [
      coreutils
      gawk
      gnused
      iproute2
      iw
      jq
      networkmanager
    ];
    monitor = [
      brightnessctl
      coreutils
      findutils
      gawk
      hyprland
      jq
      systemd
      util-linux
    ];
    power = [
      coreutils
      gawk
      gnugrep
      power-profiles-daemon
      upower
    ];
    # tailscale comes from the session PATH, matching the daemon the NixOS
    # module runs.
    tailscale-send = [
      coreutils
      libnotify
      zenity
    ];
    # GeoClue's demo client, the one CLI that asks the geoclue service.
    locate = [
      coreutils
      gawk
      (runCommand "where-am-i" { } ''
        mkdir -p $out/bin
        ln -s ${geoclue2}/libexec/geoclue-2.0/demos/where-am-i $out/bin/
      '')
    ];
    # codex, which the Codex collector asks for its limits, too.
    agent-usage-update = [
      coreutils
      jq
      ripgrep
      (collector "agent-usage-claude")
      (collector "agent-usage-codex")
    ];
  };
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
      ./scripts
      ./tests
    ];
  };

  doCheck = true;
  nativeCheckInputs = [ jq ];
  checkPhase = ''
    runHook preCheck
    bash tests/monitor-scale.sh
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    share=$out/share/hrndz-shell
    mkdir -p $share/bin $out/bin
    cp -r shell theme menu.jsonc $share/
    ln -s ${lib.getExe cli} $out/bin/hrndz-shell
    ln -s ${lib.getExe notificationSend} $out/bin/omarchy-notification-send
    ${lib.concatMapAttrsStringSep "\n" (
      name: drv: "ln -s ${lib.getExe drv} $share/bin/${name}"
    ) helpers}

    # Store paths for the commands the QML runs that are not in every
    # session's PATH.
    find $share -type f \( -name '*.qml' -o -name '*.js' -o -name '*.jsonc' \) -print0 |
      while IFS= read -r -d "" f; do
        substituteInPlace "$f" \
          --subst-var-by shareDir "$share" \
          --subst-var-by ambientDir "${ambientDir}" \
          --subst-var-by playbackRate "${toString playbackRate}" \
          --subst-var-by lockBlankMs "${toString (lockBlankSeconds * 1000)}" \
          --subst-var-by hrndzShell "$out/bin/hrndz-shell" \
          --subst-var-by fcMatch "${lib.getExe' fontconfig "fc-match"}" \
          --subst-var-by gtkLaunch "${lib.getExe' gtk3 "gtk-launch"}" \
          --subst-var-by notifySend "${lib.getExe libnotify}" \
          --subst-var-by systemdInhibit "${lib.getExe' systemd "systemd-inhibit"}" \
          --subst-var-by xdgOpen "${lib.getExe' xdg-utils "xdg-open"}"
      done
    if grep -rnE '@[a-zA-Z]+@' $share --include='*.qml' --include='*.js' --include='*.jsonc'; then
      echo "unsubstituted placeholders above" >&2
      exit 1
    fi

    runHook postInstall
  '';

  passthru = {
    inherit ambientDir omasnap;
    quickshell = quickshell';
  };

  meta = {
    description = "Personal Quickshell desktop shell, forked from Omarchy's";
    license = lib.licenses.mit;
    mainProgram = "hrndz-shell";
    platforms = lib.platforms.linux;
  };
}
