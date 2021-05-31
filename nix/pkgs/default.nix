final: prev:

{
  powershell-es = prev.callPackage ./powershell-es.nix { };
  nvim-ts-grammars = prev.callPackage ./nvim-ts-grammars { };
}
