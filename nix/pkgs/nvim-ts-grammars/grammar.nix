{ lib, stdenv, libcxx, tree-sitter }:

# Build a parser grammar and put the resulting shared object in `$out/parser`

{
# language name
language
# version of tree-sitter
, version
# source for the language grammar
, source, location ? null }:

stdenv.mkDerivation {

  pname = "${language}-grammar";
  inherit version;

  src = if location == null then source else "${source}/${location}";

  NIX_CFLAGS_COMPILE = lib.optionalString stdenv.isDarwin "-I${lib.getDev libcxx}/include/c++/v1";
  buildInputs = [ tree-sitter ];

  dontUnpack = true;
  configurePhase = ":";
  buildPhase = ''
    runHook preBuild
    scanner_cc="$src/src/scanner.cc"
    if [ ! -f "$scanner_cc" ]; then
      scanner_cc=""
    fi
    scanner_c="$src/src/scanner.c"
    if [ ! -f "$scanner_c" ]; then
      scanner_c=""
    fi
    $CC -o parser.so -I$src/src $src/src/parser.c $scanner_cc $scanner_c -shared -Os -lstdc++ -fPIC
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    mkdir $out
    mv parser.so $out/
    runHook postInstall
  '';
}
