{ pkgs, ... }:
let
  script-name = "git-age-filter";
  script-src = builtins.readFile ./script.sh;
  script = pkgs.writeShellScriptBin script-name script-src;
  runtimeInputs = with pkgs; [
    age
    age-plugin-yubikey
    coreutils
    git
    gnugrep
  ];
in
pkgs.symlinkJoin {
  name = script-name;

  paths = [ script ];

  buildInputs = [ pkgs.makeWrapper ];

  postBuild = "wrapProgram $out/bin/${script-name} --prefix PATH : ${pkgs.lib.makeBinPath runtimeInputs}";

  meta = {
    description = "Transparent git file encryption using age and age-plugin-yubikey";
    license = pkgs.lib.licenses.mit;
    mainProgram = script-name;
  };
}
