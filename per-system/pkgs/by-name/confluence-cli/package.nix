{ pkgs, ... }:

pkgs.buildNpmPackage rec {
  pname = "confluence-cli";
  version = "2.25.2";

  src = pkgs.fetchurl {
    url = "https://registry.npmjs.org/confluence-cli/-/confluence-cli-${version}.tgz";
    hash = "sha256-e1tw/4WEJLh8QP++HZc2wVZa6cGjeNVfJYYCNgWh28k=";
  };
  sourceRoot = "package";

  npmDepsHash = "sha256-d7mLLM91i0mqm2nBdL+paNIA6aguSyfOOXhpti6Keu8=";
  dontNpmBuild = true;
  npmFlags = [ "--omit=dev" ];
  # The published shrinkwrap omits dev dependencies, but package.json still lists them.
  postPatch = ''
    ${pkgs.jq}/bin/jq 'del(.devDependencies)' package.json > package.json.tmp
    mv package.json.tmp package.json
  '';

  meta = {
    description = "Command-line interface for Atlassian Confluence";
    homepage = "https://github.com/pchuri/confluence-cli";
    license = pkgs.lib.licenses.mit;
    mainProgram = "confluence";
  };
}
