{ stdenv, lib, fetchzip }:

stdenv.mkDerivation rec {
  pname = "powershell-es";
  version = "2.3.0";
  src = fetchzip {
    url =
      "https://github.com/PowerShell/PowerShellEditorServices/releases/download/v${version}/PowerShellEditorServices.zip";
    stripRoot = false;
    sha256 = "sha256-wRVhHuN692xSzD/GSRqBAO9UHHBylrBnt+lPjGtPPh0=";
  };

  installPhase = ''
    dest=$out/share
    mkdir -p $dest
    cp -r * $dest
    ls $dest
  '';

  meta = with lib; {
    description = "PowerShell Editor Services";
    homepage = https://github.com/PowerShell/PowerShellEditorServicess;
    platforms = [ "x86_64-darwin" "x86_64-linux" ];
    license = with licenses; [ mit ];
  };
}
