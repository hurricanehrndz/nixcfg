{ lib, stdenv, ... }:

with lib; {
  zshenvExtra = ''
    # Start compinit in my zshrc
    skip_global_compinit=1
  '';
}
