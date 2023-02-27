{
  config,
  lib,
  pkgs,
  inputs,
  self,
  ...
}:
with lib; let
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
  l = inputs.nixpkgs.lib // builtins;
  pgpPublicKey = "0x0D2565B7C6058A69";
  keysDir = self + "/secrets/keys";
  gpgPkg = config.programs.gpg.package;
  homedir = config.programs.gpg.homedir;
  gpg-agent-start = with pkgs;
    writeShellScript "gpg-agent-start" ''
      ${gpgPkg}/bin/gpg-connect-agent /bye
      sleep 3
      ${pkgs.coreutils}/bin/ln "$(${gpgPkg}/bin/gpgconf --list-dir agent-ssh-socket)" "$SSH_AUTH_SOCK"
    '';
  sockPathCmd = "$(${gpgPkg}/bin/gpgconf --list-dirs agent-ssh-socket)";
in {
  config = mkMerge [
    {
      home.packages = with pkgs; [
        gnupg
        gpgme

        (writeShellScriptBin "gpg-agent-restart" ''
          pkill gpg-agent ; pkill ssh-agent ; pkill pinentry ; eval $(gpg-agent --daemon --enable-ssh-support)
        '')
      ];
      programs.gpg = {
        enable = true;
        mutableKeys = false;
        mutableTrust = false;
        # TODO: clean up the format/structure of these key files
        publicKeys = [
          {
            source = keysDir + "/${pgpPublicKey}.asc";
            trust = "ultimate";
          }
        ];

        # https://github.com/drduh/config/blob/master/gpg.conf
        # https://www.gnupg.org/documentation/manuals/gnupg/GPG-Configuration-Options.html
        # https://www.gnupg.org/documentation/manuals/gnupg/GPG-Esoteric-Options.html
        settings = {
          # Keyserver URL
          keyserver = "hkps://keys.openpgp.org";
          # keyserver hkps://keyserver.ubuntu.com:443
          # keyserver hkps://hkps.pool.sks-keyservers.net
          # keyserver hkps://pgp.ocf.berkeley.edu
        };
      };
    }

    (mkIf isLinux {
      services.gpg-agent = {
        enable = true;
        enableSshSupport = true;
      };
    })

    (mkIf isDarwin {
      launchd.agents.gpg-agent = {
        enable = true;
        config = {
          ProgramArguments = ["${gpg-agent-start}"];
          RunAtLoad = true;
          EnvironmentVariables = {GNUPGHOME = homedir;};
          KeepAlive.SuccessfulExit = false;
        };
      };
      home.file."${homedir}/gpg-agent.conf".text = ''
        max-cache-ttl 1800
        default-cache-ttl 600
        max-cache-ttl-ssh 600
        enable-ssh-support
        pinentry-program ${pkgs.pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac
      '';
      home.sessionVariablesExtra = ''
        export SSH_AUTH_SOCK="${sockPathCmd}"
      '';
    })
  ];
}
