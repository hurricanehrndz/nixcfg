{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];
  perSystem =
    { pkgs, ... }:
    {
      treefmt = with pkgs; {
        projectRootFile = "flake.nix";

        programs.nixfmt = {
          enable = lib.meta.availableOn stdenv.buildPlatform nixfmt-rfc-style.compiler;
          package = nixfmt-rfc-style;
        };
        programs.shfmt.enable = true;
        programs.shellcheck.enable = true;
        settings.formatter.shellcheck.options = [
          "-s"
          "bash"
        ];
      };
    };
}
