{ pkgs, ... }:
let
  script-name = "git-age-filter";
  script-src = builtins.readFile ./script.sh;
  script = pkgs.writeShellScriptBin script-name script-src;
  nativeBuildInputs = with pkgs; [
    age
    age-plugin-yubikey
    coreutils
    git
    gnugrep
  ];
in
pkgs.symlinkJoin {
  name = script-name;

  paths = [ script ] ++ nativeBuildInputs;

  buildInputs = [ pkgs.makeWrapper ];

  postBuild = "wrapProgram $out/bin/${script-name} --prefix PATH : $out/bin";
}
