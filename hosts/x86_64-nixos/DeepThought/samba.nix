{ ... }:
{
  # Samba
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        "workgroup" = "WORKGROUP";
        "server string" = "DeepThought";
        "server role" = "standalone server";
        "security" = "user";
        "guest account" = "nobody";
        "map to guest" = "Bad User";
        "min protocol" = "SMB3";
        "ea support" = "yes";
        "smbd profiling level" = "on";
      };
      public = {
        path = "/shares/public";
        comment = "Public Share";
        "guest ok" = "yes";
        "read only" = "no";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "nobody";
        "force group" = "nogroup";
      };
      media = {
        path = "/volumes/storage/media";
        comment = "Media Share";
        "guest ok" = "yes";
        "read only" = "yes";
        "write list" = "@users";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "hurricane";
        "force group" = "users";
      };
      backups = {
        path = "/volumes/storage/backups";
        comment = "Backups";
        "guest ok" = "yes";
        "read only" = "yes";
        "write list" = "@users";
        "create mask" = "0644";
        "directory mask" = "0755";
        "force user" = "hurricane";
        "force group" = "users";
      };
    };
  };

  # mDNS
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
    extraServiceFiles = {
      smb = ''
        <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">%h</name>
          <service>
            <type>_smb._tcp</type>
            <port>445</port>
          </service>
        </service-group>
      '';
    };
  };
}
