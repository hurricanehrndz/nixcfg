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
      # virtualization
    ]);
in {inherit workstation;}
