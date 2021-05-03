{ lib, stdenv, ... }:

with lib; {
  zshenvExtra = ''
    # Start compinit in my zshrc
    skip_global_compinit=1

  '' + optionalString stdenv.isDarwin ''
    # Nix setup (environment variables, etc.)
    if [[ -e ~/.nix-profile/etc/profile.d/nix.sh ]] \
        && [[ -z "$NIX_SSL_CERT_FILE" ]]; then
      source ~/.nix-profile/etc/profile.d/nix.sh
    fi
  '';
}
