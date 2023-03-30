{ stdenv, swift, swiftpm, swiftpm2nix, swiftPackages, unzip, swiftlint-src }:

let
  # Pass the generated files to the helper.
  generated = swiftpm2nix.helpers ./nix;
in

stdenv.mkDerivation rec {
  pname = "swiftlint";
  version = "0.51.0";

  src = swiftlint-src;

  # Including SwiftPM as a nativeBuildInput provides a buildPhase for you.
  # This by default performs a release build using SwiftPM, essentially:
  #   swift build -c release
  nativeBuildInputs = [ swift swiftpm  ];

  buildInputs = [unzip swiftPackages.XCTest];

  # The helper provides a configure snippet that will prepare all dependencies
  # in the correct place, where SwiftPM expects them.
  configurePhase = generated.configure;

  installPhase = ''
    # This is a special function that invokes swiftpm to find the location
    # of the binaries it produced.
    binPath="$(swiftpmBinPath)"
    # Now perform any installation steps.
    mkdir -p $out/bin
    cp $binPath/$pname $out/bin/
  '';
}
