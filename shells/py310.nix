{
  pkgs,
  inputs,
  inputs',
  ...
}:
with pkgs;
  mkShell {
    NIX_CFLAGS_COMPILE = lib.optionals stdenv.isDarwin [
      "-I${lib.getDev libcxx}/include/c++/v1"
    ];

    packages = [
      pre-commit
    ];

    nativeBuildInputs = [libffi python310];
  }
