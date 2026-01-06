{
  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  xdg.enable = true;

  home.enableNixpkgsReleaseCheck = false;
}
