{
  pkgs,
  inputs,
  ...
}: let
  username = "carlos";
in {
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

  home-manager.users.${username} = hmArgs: {
    imports = with hmArgs.roles; base;
    home.stateVersion = "22.11";
  };

  programs.zsh.enable = true;

  system.stateVersion = 4;
}
