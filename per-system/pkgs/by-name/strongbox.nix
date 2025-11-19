{
  inputs,
  pkgs,
  buildGoModule,
  ...
}:
let
  inherit (inputs) strongbox-src;
in
buildGoModule {
  pname = "strongbox";
  version = "master";
  src = strongbox-src;

  nativeBuildInputs = with pkgs; [ coreutils ];

  checkFlags = [
    "-skip=^TestGitIntegration_Filtering$"
  ];

  ldflags = [
    "-X main.version=master"
    "-X main.commit=${strongbox-src.shortRev}"
    "-X main.date=${strongbox-src.lastModifiedDate}"
    "-X main.builtBy=nix"
  ];

  vendorHash = "sha256-kAQLg6urkUoMYeqPYv+EJ1XCBz7+0lxWlAn2VPtgxLs="; # lib.fakeHash
}
