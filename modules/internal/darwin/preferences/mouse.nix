{
  system.defaults = {
    trackpad = {
      # 0 to enable Silent Clicking, 1 to disable. The default is 1.
      ActuationStrength = 1;
      # Whether to enable trackpad tap to click. The default is false.
      Clicking = true;
      Dragging = false;
      # For normal click: 0 for light clicking, 1 for medium, 2 for firm. The default is 1.
      FirstClickThreshold = 1;
      # For force touch: 0 for light clicking, 1 for medium, 2 for firm. The default is 1.
      SecondClickThreshold = 1;
      TrackpadRightClick = true;
      TrackpadThreeFingerDrag = true;
    };

    magicmouse = {
      MouseButtonMode = "TwoButton";
    };

    NSGlobalDomain = {
      #: Enables swiping left or right with two fingers to navigate backward or forward.
      AppleEnableMouseSwipeNavigateWithScrolls = true;
      AppleEnableSwipeNavigateWithScrolls = true;

      # Show scroll bars when an external mouse or trackball is connected.
      AppleShowScrollBars = "Always";
      NSScrollAnimationEnabled = true;
      # Configures the trackpad tap behavior. Mode 1 enables tap to click.
      "com.apple.mouse.tapBehavior" = 1;
      # Enable "Natural" scrolling direction.
      "com.apple.swipescrolldirection" = true;
      # Whether to enable trackpad secondary click.
      "com.apple.trackpad.enableSecondaryClick" = true;
      # Configures the trackpad tracking speed (0 to 3). The default is 1.0.
      "com.apple.trackpad.scaling" = 1.0;
      # Configures the trackpad corner click behavior. Mode 1 enables right click.
      # https://daiderd.com/nix-darwin/manual/index.html#opt-system.defaults.NSGlobalDomain.com.apple.trackpad.trackpadCornerClickBehavior
      "com.apple.trackpad.trackpadCornerClickBehavior" = null;
    };

    universalaccess = {
      closeViewScrollWheelToggle = false;
      closeViewZoomFollowsFocus = true;
    };
  };
}
