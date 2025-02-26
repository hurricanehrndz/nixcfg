{pkgs, ...}: let
  name = "strongbox-init";
  script = pkgs.writeShellScriptBin name ''
    DATE=$(ddate +'the %e of %B%, %Y')
    cowsay Hello, world! Today is $DATE.
  '';
  nativeBuildInputs = with pkgs; [
    cowsay ddate
  ];
in
  pkgs.symlinkJoin {
    inherit name;

    paths = [script] ++ nativeBuildInputs;

    buildInputs = [pkgs.makeWrapper];

    postBuild = "wrapProgram $out/bin/${name} --prefix PATH : $out/bin";
  }
