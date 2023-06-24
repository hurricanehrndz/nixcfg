{
  pkgs,
  inputs,
  ...
}:
with pkgs;
  mkShell {
    buildInputs = [go];
  }
