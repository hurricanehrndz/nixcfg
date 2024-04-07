{
  sharedProfiles,
  darwinProfiles,
}: let
  workstation =
    (with sharedProfiles; [
      fonts.common
    ])
    ++ (with darwinProfiles; [
      graphical
      system-defaults
      # yabi
      raycast
      tailscale
      virtualization
    ]);
in {inherit workstation;}
