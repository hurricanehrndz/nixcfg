{
  homebrew.casks = [
    "flameshot"
  ];
  launchd.user.agents.flameshot.serviceConfig = {
    ProgramArguments = [ "/Applications/flameshot.app/Contents/MacOS/flameshot" ];
    Disabled = false;
    RunAtLoad = true;
  };
}
