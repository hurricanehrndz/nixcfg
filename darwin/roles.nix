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
      tailscale
      virtualization
    ]);
in {inherit workstation;}
