{pkgs, ...}: {
  # Make sure the nix daemon always runs
  services.nix-daemon.enable = true;
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  environment.systemPackages = [
    pkgs.vim
  ];

  programs.zsh.enable = true;

  system.stateVersion = 4;
}
