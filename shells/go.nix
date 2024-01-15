{
  pkgs,
  inputs,
  inputs',
  ...
}: let
  inherit (inputs.devenv.lib) mkShell;
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
            revive
            gomodifytags
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
