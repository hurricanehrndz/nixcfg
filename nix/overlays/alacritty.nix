inputs@{ ... }:
final: prev:

# see:
# https://github.com/guibou/nixGL/issues/16
let
  lib = prev.lib;
  stdenv = prev.stdenv;
in { alacritty = if stdenv.isLinux then (final.wrapWithNixGLIntel prev.alacritty) else prev.alacritty; }
