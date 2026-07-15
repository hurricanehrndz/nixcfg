{ pkgs, ... }:
let
  version = "7.2.77";
  platform =
    {
      "aarch64-darwin" = {
        os = "darwin";
        arch = "aarch64";
        hash = "sha256-p8Jl+GiVu52UatKOOhJqUCCW3JGvt+mDhHeqTTnoRVQ=";
      };
      "x86_64-darwin" = {
        os = "darwin";
        arch = "amd64";
        hash = "sha256-b/j616+q8PlS0krJ+x33kOq2KmTqkJgThsu737w+nDc=";
      };
      "aarch64-linux" = {
        os = "linux";
        arch = "aarch64";
        hash = "sha256-Qv/7DOa467iXUg1P6AVBNx74YWWPL/Ws/hyBWqzlxPM=";
      };
      "x86_64-linux" = {
        os = "linux";
        arch = "amd64";
        hash = "sha256-3AgUzQ/DP0cupPPVWHRH4U/8s0hT7ayaUj7cHF17qGA=";
      };
    }
    .${pkgs.stdenv.hostPlatform.system};
in
pkgs.stdenvNoCC.mkDerivation {
  pname = "cli-proxy-api";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/router-for-me/CLIProxyAPI/releases/download/v${version}/CLIProxyAPI_${version}_${platform.os}_${platform.arch}.tar.gz";
    inherit (platform) hash;
  };

  sourceRoot = ".";
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 cli-proxy-api $out/bin/cli-proxy-api
    runHook postInstall
  '';

  meta = {
    description = "OpenAI, Gemini, and Claude compatible API proxy for CLI accounts";
    homepage = "https://github.com/router-for-me/CLIProxyAPI";
    license = pkgs.lib.licenses.mit;
    mainProgram = "cli-proxy-api";
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];
  };
}
