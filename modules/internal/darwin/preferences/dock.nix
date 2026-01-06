{
  system.defaults = {
    dock = {
      autohide = true;
      autohide-delay = 0.1;
      autohide-time-modifier = 0.1;
      expose-animation-duration = 0.1;
      expose-group-apps = true; # aerospace setting
      launchanim = false;
      mineffect = "genie";
      minimize-to-application = true;
      mouse-over-hilite-stack = true;
      mru-spaces = false;
      orientation = "bottom";
      show-recents = false;
      showhidden = true;
      static-only = true;
      tilesize = 64;

      ##: Corner hot actions
      # 1 => Disabled
      # 2 => Mission Control
      # 3 => Application Windows
      # 4 => Desktop
      # 5 => Start Screen Saver
      # 6 => Disable Screen Saver
      # 7 => Dashboard
      # 10 => Put Display to Sleep
      # 11 => Launchpad
      # 12 => Notification Center
      # 13 => Lock Screen
      # 14 => Quick Note
      wvous-bl-corner = 1;
      wvous-br-corner = 1;
      wvous-tl-corner = 1;
      wvous-tr-corner = 1;
    };

    spaces.spans-displays = true; # aerospace
  };
}
