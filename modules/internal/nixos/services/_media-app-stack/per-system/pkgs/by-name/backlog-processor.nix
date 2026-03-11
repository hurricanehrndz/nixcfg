{
  inputs,
  lib,
  pkgs,
  buildNpmPackage,
}:

buildNpmPackage {
  pname = "seekarr";
  version = "master";

  src = inputs.backlog-processor-src;

  npmDepsHash = "sha256-KLqsfV9/KWINAW87sFo9+vC6oNVwYJd/QierGWpR8p8=";

  postPatch = ''
    ${pkgs.jq}/bin/jq '. + { bin: { "seekarr": "dist/index.js" } }' package.json > package.json.tmp
    mv package.json.tmp package.json
  '';

  postInstall = ''
    sed -i '1i #!/usr/bin/env node' $out/lib/node_modules/seekarr/dist/index.js
    patchShebangs $out/bin/seekarr
  '';

  meta = {
    description = "A lightweight tool that triggers manual searches in Sonarr and Radarr to find missing items and upgrade existing ones to better quality.";
    homepage = "https://github.com/scottrobertson/seekarr";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
