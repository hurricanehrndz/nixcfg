{
  homebrew.casks = [
    "raycast"
  ];

  launchd.user.agents.raycast.serviceConfig = {
    Disabled = false;
    ProgramArguments = ["/Applications/Raycast.app/Contents/Library/LoginItems/RaycastLauncher.app/Contents/MacOS/RaycastLauncher"];
    RunAtLoad = true;
  };

  targets.darwin.defaultsdicts = {
    # Disable Spotlight hotkeys
    "com.apple.symbolichotkeys" = {
      "AppleSymbolicHotKeys" = {
        "64" = {
          enabled = 0;
          value = {
            type = "standard";
            parameters = [
              65535 # no ascii code
              49 # 0x31 space key
              1048576 # command key
            ];
          };
        };
        "65" = {
          enabled = 0;
          value = {
            type = "standard";
            parameters = [
              65535 # no ascii code
              49 # 0x31 space key
              1572864 # command+option
            ];
          };
        };
      };
    };
  };
}
