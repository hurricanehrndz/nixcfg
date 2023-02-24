{
  sharedProfiles,
  darwinProfiles,
}: let
  workstation =
    # (with sharedProfiles; [
    #   # fonts.common
    #   # fonts.iosevka-variants
    # ])
    with darwinProfiles; [
      # graphical
      system-defaults
      # virtualization
    ];
in {inherit workstation;}
