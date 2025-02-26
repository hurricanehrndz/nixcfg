{pkgs, ...}: let
  script-name = "strongbox-init";
  script-src = builtins.readFile ./script.sh;
  script = pkgs.writeShellScriptBin script-name script-src;
  nativeBuildInputs = with pkgs; [
    coreutils
    gawk
  ];
in
  pkgs.symlinkJoin {
    name = script-name;

    paths = [script] ++ nativeBuildInputs;

    buildInputs = [pkgs.makeWrapper];

    postBuild = "wrapProgram $out/bin/${script-name} --prefix PATH : $out/bin";
  }
