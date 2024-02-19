{
  self,
  config,
  pkgs,
  inputs',
  ...
}: {
  environment = {
    systemPackages = with pkgs; [
      mergerfs
      mergerfs-tools
    ];
  };

  # secrets
  age.secrets = {
    "snapraid-runner.apprise.yaml".file = "${self}/secrets/services/snapraid-runner/apprise.yaml.age";
  };

  # enable snapraid
  services.snapraid = {
    enable = true;
    extraConfig = ''
      nohidden
      block_size 256
      autosave 500
    '';
    contentFiles = [
      "/var/snapraid/snapraid.content"
      "/volumes/data1/snapraid.content"
      "/volumes/data2/snapraid.content"
      "/volumes/data3/snapraid.content"
      "/volumes/data4/snapraid.content"
    ];
    dataDisks = {
      d1 = "/volumes/data1";
      d2 = "/volumes/data2";
      d3 = "/volumes/data3";
      d4 = "/volumes/data4";
    };
    parityFiles = [
      "/volumes/parity/snapraid.parity"
    ];
    exclude = [
      "*.bak"
      "*.unrecoverable"
      ".AppleDB"
      ".AppleDouble"
      ".DS_Store"
      ".Spotlight-V100"
      ".TemporaryItems"
      ".Thumbs.db"
      ".Trashes"
      "._AppleDouble"
      ".content"
      ".fseventsd"
      "/lost+found/"
      "/snapraid.conf*"
      "/tmp/"
      "/games/"
      "aquota.group"
      "aquota.user"
    ];
  };

  snapraid-runner = {
    enable = true;
    notification = {
      enable = true;
      config = config.age.secrets."snapraid-runner.apprise.yaml".path;
    };
    scrub.enabled = true;
    snapraid.touch = true;
  };

  # add cache expiration script
  systemd.services.snapraid-cache-expire = {
    description = "Expire snapraid cache";
    startAt = "03:00";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeScript "snapraid-cache-expire" ''
        #!${pkgs.bash}/bin/bash

        CACHE="/volumes/cache/media"
        BACKING="/volumes/backing_storage/media"
        PERCENTAGE=40

        set -o errexit
        while [[ "$(${pkgs.coreutils}/bin/df --output=pcent "''${CACHE}" | ${pkgs.gnugrep}/bin/grep -v Use | ${pkgs.coreutils}/bin/cut -d'%' -f1)" -gt ''${PERCENTAGE} ]]; do
          cd "''${CACHE}"
          echo "Cache needs expiring ..."
          FILE=$(${pkgs.ripgrep}/bin/rg --sort modified --files "./" | \
                  ${pkgs.coreutils}/bin/head -n 1)
          test -n "''${FILE}"
          ${pkgs.rsync}/bin/rsync -avxHAXWESR --preallocate --remove-source-files "''${FILE}" "''${BACKING}/"
          # remove empty directories
          ${pkgs.fd}/bin/fd --type directory --type empty --min-depth 2 . "''${CACHE}/" -x rmdir
          ${pkgs.fd}/bin/fd --type directory --type empty --min-depth 2 . "''${CACHE}/" -x rmdir
        done
      '';
    };
  };
}
