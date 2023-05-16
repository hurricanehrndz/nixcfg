{inputs, ...}: {
  perSystem = ctx @ {
    pkgs,
    system,
    inputs',
    ...
  }: let
    inherit (inputs'.neovim-flake.packages) neovim;
  in {
    _module.args.packages = ctx.config.packages;
    packages.swiftformat = pkgs.callPackage ./tools/swiftformat.nix {inherit (inputs) swiftformat-src;};
    packages.swiftlint = pkgs.callPackage ./tools/swiftlint {inherit (inputs) swiftlint-src;};
    packages.aws-sso = pkgs.callPackage ./aws-sso {};
    packages.neovim = pkgs.callPackage ./neovim.nix {inherit neovim;};
    packages.codelldb = let pkgs = inputs.nixpkgs-pr211321.legacyPackages.${system}; in pkgs.vscode-extensions.vadimcn.vscode-lldb;
  };
}
