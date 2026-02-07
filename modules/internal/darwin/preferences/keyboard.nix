{
  system.defaults = {
    NSGlobalDomain = {
      # Configures the keyboard control behavior. Mode 3 enables full keyboard control.
      AppleKeyboardUIMode = 3;
      ApplePressAndHoldEnabled = false;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      # Whether to use F1, F2, etc. keys as standard function keys.
      "com.apple.keyboard.fnState" = false;
    };
  };
  # interfers with superkey/hyperkey
  # system.keyboard = {
  #   enableKeyMapping = false;
  #   nonUS.remapTilde = false;
  #   remapCapsLockToControl = false;
  #   remapCapsLockToEscape = false;
  #   swapLeftCommandAndLeftAlt = false;
  # };
}
