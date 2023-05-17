{
  pkgs,
  inputs,
  ...
}:
with pkgs;
  mkShell {
    NIX_CFLAGS_COMPILE = lib.optionals stdenv.isDarwin [
      "-I${lib.getDev libcxx}/include/c++/v1"
    ];

    nativeBuildInputs = [poetry];
  }
