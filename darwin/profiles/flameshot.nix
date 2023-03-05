{
  homebrew.casks = [
    "flameshot"
  ];
  launchd.agents.flameshot.serviceConfig = {
    ProgramArguments = ["/Applications/flameshot.app/Contents/MacOS/flameshot"];
    RunAtLoad = true;
  };
}
