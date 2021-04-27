final: prev:

{
  powershell-es = prev.callPackage ./powershell-es.nix { };
  nvim-treesitter-parsers = prev.callPackage ./nvim-treesitter-parsers.nix { };
}
