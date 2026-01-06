{
  system.defaults = {
    finder = {
      AppleShowAllExtensions = false;
      AppleShowAllFiles = false;
      CreateDesktop = false;

      # search current folder
      FXDefaultSearchScope = "SCcf";
      FXEnableExtensionChangeWarning = false;
      # "icnv" => Icon view
      # "Nlsv" => List view
      # "clmv" => Column View
      # "Flwv" => Gallery View
      FXPreferredViewStyle = "Nlsv";

      NewWindowTarget = "Home";

      ShowPathbar = true;
      ShowStatusBar = true;
      _FXShowPosixPathInTitle = false;
      _FXSortFoldersFirst = true;
    };

    NSGlobalDomain = {
      NSDocumentSaveNewDocumentsToCloud = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;

      # Set the size of the finder sidebar icons
      # 1 => small; 2 => medium; 3 => large (default)
      NSTableViewDefaultSizeMode = 1;
      NSTextShowsControlCharacters = true;
      # Disable the over-the-top focus ring animation
      NSUseAnimatedFocusRing = false;
      NSWindowResizeTime = 0.001;

      # Set the spring loading delay for directories. The default is the float `1.0`.
      "com.apple.springing.delay" = 0.1;
      # Enable spring loading (expose) for directories.
      "com.apple.springing.enabled" = true;
    };

    CustomUserPreferences = {
      "com.apple.finder" = {
        ShowRecents = false;
        ShowRecentTags = false;
      };
    };
  };
}
