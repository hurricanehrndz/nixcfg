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
      # virtualization
    ]);
in {inherit workstation;}
