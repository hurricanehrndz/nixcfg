{
  pkgs,
  inputs,
  ...
}: let
  username = "carlos";
in {
  # Make sure the nix daemon always runs
  services.nix-daemon.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    ncurses
  ];

  environment.shells = [pkgs.zsh];

  users.users.${username} = {
    home = "/Users/${username}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  home-manager.users.${username} = hmArgs: {
    imports = with hmArgs.roles; base;
    home.stateVersion = "22.11";
  };

  programs.zsh.enable = true;

  system.stateVersion = 4;
}
