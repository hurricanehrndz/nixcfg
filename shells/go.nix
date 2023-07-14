{
  pkgs,
  inputs,
  inputs',
  ...
}: let
  inherit (inputs.devenv.lib) mkShell;
  inherit (inputs'.pdenv) packages;
in
  mkShell {
    inherit inputs pkgs;
    modules = [
      (
        {
          config,
          pkgs,
          ...
        }: {
          packages = with pkgs; [
            revive
            gopls
            gofumpt
            golangci-lint
            gomodifytags
            packages.goimports-reviser
          ];
          languages.go.enable = true;
        }
        # // pkgs.lib.optionals pkgs.stdenv.isDarwin {
        #   packages = with pkgs.darwin.apple_sdk; [
        #     frameworks.Foundation
        #     frameworks.CoreFoundation
        #     pkgs.swiftPackages.Foundation
        #   ];
        #   env.CFLAGS = [" -iframework ${config.env.DEVENV_PROFILE}/Library/Frameworks"];
        # })
      )
    ];
  }
# with pkgs;
#   mkShell {
#     buildInputs = [go gopls golangci-lint gofumpt];
#   }
