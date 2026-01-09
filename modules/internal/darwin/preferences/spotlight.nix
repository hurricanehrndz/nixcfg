{
  system.defaults.CustomUserPreferences = {
    # spotlight search items
    "com.apple.Spotlight" = {
      EnabledPreferenceRules = [
        "Custom.relatedContents"
        "com.apple.AppStore"
        "com.apple.iBooksX"
        "com.apple.iCal"
        "com.apple.AddressBook"
        "com.apple.Dictionary"
        "com.apple.mail"
        "com.apple.Notes"
        "com.apple.Photos"
        "com.apple.podcasts"
        "com.apple.reminders"
        "com.apple.Safari"
        "com.apple.shortcuts"
        "com.apple.tips"
        "com.apple.VoiceMemos"
        "System.files"
        "System.folders"
        "System.iphoneApps"
      ];
      orderedItems = [
        {
          enabled = 1;
          name = "APPLICATIONS";
        }
        {
          enabled = 1;
          name = "MENU_EXPRESSION";
        }
        {
          enabled = 0;
          name = "CONTACT";
        }
        {
          enabled = 0;
          name = "MENU_CONVERSION";
        }
        {
          enabled = 1;
          name = "MENU_DEFINITION";
        }
        {
          enabled = 0;
          name = "DOCUMENTS";
        }
        {
          enabled = 0;
          name = "EVENT_TODO";
        }
        {
          enabled = 0;
          name = "DIRECTORIES";
        }
        {
          enabled = 0;
          name = "FONTS";
        }
        {
          enabled = 0;
          name = "IMAGES";
        }
        {
          enabled = 0;
          name = "MESSAGES";
        }
        {
          enabled = 0;
          name = "MOVIES";
        }
        {
          enabled = 0;
          name = "MUSIC";
        }
        {
          enabled = 0;
          name = "MENU_OTHER";
        }
        {
          enabled = 0;
          name = "PDF";
        }
        {
          enabled = 0;
          name = "PRESENTATIONS";
        }
        {
          enabled = 0;
          name = "MENU_SPOTLIGHT_SUGGESTIONS";
        }
        {
          enabled = 0;
          name = "SPREADSHEETS";
        }
        {
          enabled = 1;
          name = "SYSTEM_PREFS";
        }
        {
          enabled = 0;
          name = "TIPS";
        }
        {
          enabled = 0;
          name = "BOOKMARKS";
        }
      ];
    };
  };
}
