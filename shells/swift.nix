{
  pkgs,
  inputs,
}: let
  inherit (pkgs) mkShell;
in
  mkShell {
    nativeBuildInputs = with pkgs; [swift swiftpm];
  }
