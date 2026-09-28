# Omarchy's screenshot and annotation editor (github.com/omacom/omasnap, MIT).
# It shells out to hyprctl (from the session PATH, matching the running
# compositor), wl-copy, tesseract for OCR, and omarchy-notification-send,
# which hrndz-shell ships.
#
# It follows upstream's main branch through the `omasnap` flake input, so
# `just update` moves it. If a build fails after an update, pin the input to
# a release tag (github:omacom/omasnap/vX.Y.Z) until this package catches up.
{
  lib,
  inputs,
  stdenv,
  cmake,
  ninja,
  pkg-config,
  qt6,
  kdePackages,
  libdeflate,
  wayland,
  wayland-protocols,
  wayland-scanner,
  tesseract,
  wl-clipboard,
}:
let
  tesseract' = tesseract.override { enableLanguages = [ "eng" ]; };
  cmakeVersion = lib.head (
    builtins.match ".*project\\(omasnap VERSION ([0-9.]+).*" (
      builtins.readFile "${inputs.omasnap}/CMakeLists.txt"
    )
  );
in
stdenv.mkDerivation {
  pname = "omasnap";
  version = "${cmakeVersion}-unstable-${inputs.omasnap.shortRev}";

  src = inputs.omasnap;

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail /usr/share/wayland-protocols ${wayland-protocols}/share/wayland-protocols
  '';

  cmakeFlags = [ (lib.cmakeBool "BUILD_TESTING" false) ];

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    qt6.wrapQtAppsHook
    wayland-scanner
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtwayland
    kdePackages.layer-shell-qt
    libdeflate
    wayland
  ];

  # CEILING: upstream's smoke suite compares rendered pixels and fails under
  # nixpkgs' offscreen Qt (backdrop dimming, exit 88), so only check that the
  # wrapped binary starts. Enable doCheck again if upstream loosens it.
  doInstallCheck = true;
  installCheckPhase = ''
    QT_QPA_PLATFORM=offscreen $out/bin/omasnap --version | grep -F ${cmakeVersion}
  '';

  qtWrapperArgs = [
    "--prefix PATH : ${
      lib.makeBinPath [
        tesseract'
        wl-clipboard
      ]
    }"
  ];

  # hrndz-shell's OCR uses the same English-only build.
  passthru.tesseract = tesseract';

  meta = {
    description = "Wayland screenshot and annotation editor for Hyprland";
    homepage = "https://github.com/omacom/omasnap";
    license = lib.licenses.mit;
    mainProgram = "omasnap";
    platforms = lib.platforms.linux;
  };
}
