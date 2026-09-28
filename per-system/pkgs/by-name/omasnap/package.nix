# Omarchy's screenshot and annotation editor (github.com/omacom/omasnap, MIT).
# It shells out to hyprctl (from the session PATH, matching the running
# compositor), wl-copy, tesseract for OCR, and omarchy-notification-send,
# which hrndz-shell ships.
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  qt6,
  kdePackages,
  wayland,
  wayland-protocols,
  wayland-scanner,
  tesseract,
  wl-clipboard,
}:
let
  tesseract' = tesseract.override { enableLanguages = [ "eng" ]; };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "omasnap";
  version = "1.21.0";

  src = fetchFromGitHub {
    owner = "omacom";
    repo = "omasnap";
    tag = "v${finalAttrs.version}";
    hash = "sha256-kpoPb5F5yqcczBRUfENsEfv+BD67zQsTG9Ur6Bi3viE=";
  };

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
    wayland
  ];

  # CEILING: upstream's smoke suite compares rendered pixels and fails under
  # nixpkgs' offscreen Qt (backdrop dimming, exit 88), so only check that the
  # wrapped binary starts. Enable doCheck again if upstream loosens it.
  doInstallCheck = true;
  installCheckPhase = ''
    QT_QPA_PLATFORM=offscreen $out/bin/omasnap --version | grep -F ${finalAttrs.version}
  '';

  qtWrapperArgs = [
    "--prefix PATH : ${
      lib.makeBinPath [
        tesseract'
        wl-clipboard
      ]
    }"
  ];

  meta = {
    description = "Wayland screenshot and annotation editor for Hyprland";
    homepage = "https://github.com/omacom/omasnap";
    license = lib.licenses.mit;
    mainProgram = "omasnap";
    platforms = lib.platforms.linux;
  };
})
