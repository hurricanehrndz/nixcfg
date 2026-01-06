{
  system.defaults = {
    WindowManager = {
      StageManagerHideWidgets = true;
      StandardHideWidgets = true;
      EnableStandardClickToShowDesktop = false;
    };

    NSGlobalDomain = {
      # do not autohide menubar
      _HIHideMenuBar = false;
      # Whether to animate opening and closing of windows and popovers. The default is true.
      NSAutomaticWindowAnimationsEnabled = false;
    };
  };
}
