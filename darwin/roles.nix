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
      raycast
      flameshot
      tailscale
      # virtualization
    ]);
in {inherit workstation;}
