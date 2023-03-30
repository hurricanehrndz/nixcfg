{ stdenv, swift, swiftpm, swiftpm2nix, swiftformat-src }:

stdenv.mkDerivation rec {
  pname = "swiftformat";
  version = "0.51.3";
  src = swiftformat-src;


  # Including SwiftPM as a nativeBuildInput provides a buildPhase for you.
  # This by default performs a release build using SwiftPM, essentially:
  #   swift build -c release
  nativeBuildInputs = [ swift swiftpm ];


  installPhase = ''
    # This is a special function that invokes swiftpm to find the location
    # of the binaries it produced.
    binPath="$(swiftpmBinPath)"
    # Now perform any installation steps.
    mkdir -p $out/bin
    cp $binPath/swiftformat $out/bin/
  '';
}

