{
  homebrew.casks = [
    "raycast"
  ];

  launchd.user.agents.raycast.serviceConfig = {
    Disabled = false;
    ProgramArguments = [
      "/Applications/Raycast.app/Contents/Library/LoginItems/RaycastLauncher.app/Contents/MacOS/RaycastLauncher"
    ];
    RunAtLoad = true;
  };

  # disable problematic hotkeys
  # https://apple.stackexchange.com/questions/91679/is-there-a-way-to-set-an-application-shortcut-in-the-keyboard-preference-pane-vi
  # # Show Spotlight search field - Command, Shift, Space
  # 64 = { enabled = 1; value = { parameters = ( 65535, 49, 1179648 ); type = standard; }; };

  # Show Spotlight window - Control, Shift, Space
  # 65 = { enabled = 1; value = { parameters = ( 65535, 49, 393216 ); type = standard; }; };
  system.activationScripts.postUserActivation.text = ''
    defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 64 "
    <dict>
      <key>enabled</key>
      <false/>
      <key>value</key>
      <dict>
        <key>type</key>
        <string>standard</string>
        <key>parameters</key>
          <array>
            <integer>65535</integer>
            <integer>49</integer>
            <integer>1048576</integer>
          </array>
      </dict>
    </dict>
    "
    defaults write com.apple.symbolichotkeys.plist AppleSymbolicHotKeys -dict-add 65 "
    <dict>
      <key>enabled</key>
      <false/>
      <key>value</key>
      <dict>
        <key>type</key>
        <string>standard</string>
        <key>parameters</key>
          <array>
            <integer>65535</integer>
            <integer>49</integer>
            <integer>1572864</integer>
          </array>
      </dict>
    </dict>
    "
    $DRY_RUN_CMD /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';
}
