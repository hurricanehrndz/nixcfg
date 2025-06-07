{
  sharedProfiles,
  nixosProfiles,
}: let
  mediaserver =
    (with sharedProfiles; [
      fonts.common
    ])
    ++ (with nixosProfiles; [
      hardware.opengl
      networking.dhcp-all
      networking.reverse-proxy
      services.monitoring
      plex
    ]);
in {
  inherit
    mediaserver
    ;
}
