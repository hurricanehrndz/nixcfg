# Apple Music client (github.com/wimpysworld/sidra, BlueOak-1.0.0), wrapped
# from the upstream release AppImage because it is not in nixpkgs.
{
  lib,
  appimageTools,
  fetchurl,
}:
let
  pname = "sidra";
  version = "1.2.1";

  src = fetchurl {
    url = "https://github.com/wimpysworld/sidra/releases/download/${version}/Sidra-linux-x86_64.AppImage";
    hash = "sha256-jip87nDTVxudIThGVsZ3bnuZU32YPMfjEug0y48mKA0=";
  };

  contents = appimageTools.extractType2 { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
    install -Dm444 ${contents}/sidra.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/sidra.desktop \
      --replace-fail 'Exec=AppRun' 'Exec=sidra'
    cp -r ${contents}/usr/share/icons $out/share
  '';

  meta = {
    description = "Elegant Apple Music desktop client";
    homepage = "https://github.com/wimpysworld/sidra";
    license = lib.licenses.blueOak100;
    platforms = [ "x86_64-linux" ];
    mainProgram = "sidra";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
