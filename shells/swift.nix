{
  pkgs,
  inputs,
  ...
}: let
  inherit (pkgs) mkShell;
in
  mkShell {
    nativeBuildInputs = with pkgs; [swift swiftpm];
  }

#     inherit (inputs.devenv.lib) mkShell;
# in
#   mkShell {
#     inherit inputs pkgs;
#     modules = [
#       ({
#         config,
#         pkgs,
#         ...
#       }:
#         {
#           packages = with pkgs; [swift swiftpm];
#           languages.swift.enable = true;
#         }
#         // pkgs.lib.optionals pkgs.stdenv.isDarwin {
#           packages = with pkgs.darwin.apple_sdk; [
#             frameworks.Foundation
#             frameworks.CoreFoundation
#             pkgs.swiftPackages.Foundation
#           ];
#           env.CFLAGS = [" -iframework ${config.env.DEVENV_PROFILE}/Library/Frameworks"];
#         })
#     ];
#   }
