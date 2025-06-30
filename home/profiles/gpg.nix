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
    writeShellScriptBin "gpg-agent-start" ''
      ${gpgPkg}/bin/gpg-connect-agent /bye
      ${pkgs.coreutils}/bin/sleep 3
      if [[ -S "$SSH_AUTH_SOCK" ]]; then
        ${pkgs.coreutils}/bin/ln -sf "$(${gpgPkg}/bin/gpgconf --list-dir agent-ssh-socket)" "$SSH_AUTH_SOCK"
      fi
    '';
  sockPathCmd = "$(${gpgPkg}/bin/gpgconf --list-dirs agent-ssh-socket)";
  maxCacheTtl = "1800";
  defaultCacheTtl = "600";
  sshCacheTtl = "600";
in {
  config = mkMerge [
    {
      home.packages = with pkgs; [
        gnupg
        gpgme
        gpg-agent-start
        yubikey-manager
        gopass

        (writeShellScriptBin "gpg-agent-restart" ''
          pkill gpg-agent ; pkill ssh-agent ; pkill pinentry ; eval $(gpg-agent --daemon --enable-ssh-support)
        '')
      ];
      programs.gpg = {
        enable = true;
        mutableKeys = true;
        mutableTrust = true;
        publicKeys =
          [
            {
              source = keysDir + "/${pgpPublicKey}.asc";
              trust = "ultimate";
            }
          ]
          ++ (
            let
              ls = builtins.readDir keysDir;
              files = builtins.filter (name: ls.${name} == "regular" && "${name}" != "${pgpPublicKey}.asc") (builtins.attrNames ls);
            in
              builtins.map (keyName: {
                source = "${keysDir}/${keyName}";
                trust = "full";
              })
              files
          );

        scdaemonSettings = {
          disable-ccid = true;
          verbose = true;
          debug-level = "advanced";
          log-file = "$HOME/.gnupg/gpg-agent.log";
          debug-ccid-driver = true;
          # reader-port = "Yubico Yubikey";
          card-timeout = "1";
        };

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
        enableSshSupport = false;
        enableZshIntegration = false;
        extraConfig = ''
          enable-ssh-support
        '';
      };
      home.sessionVariablesExtra = ''
        # only set SSH_AUTH_SOCK if not SSH session
        if [[ -z "''${SSH_CLIENT}" ]]; then
          export GPG_TTY=$TTY
          ${gpgPkg}/bin/gpg-connect-agent --quiet updatestartuptty /bye > /dev/null
          export SSH_AUTH_SOCK="$(${gpgPkg}/bin/gpgconf --list-dirs agent-ssh-socket)"
        fi
      '';
    })

    (mkIf isDarwin {
      launchd.agents.gpg-agent = {
        enable = true;
        config = {
          ProgramArguments = ["${gpg-agent-start}/bin/gpg-agent-start"];
          RunAtLoad = true;
          EnvironmentVariables = {
            GNUPGHOME = homedir;
            PATH = "${gpg-agent-start}/bin";
          };
          KeepAlive.SuccessfulExit = false;
          StandardOutPath = "/tmp/gpg-agent.out";
          StandardErrorPath = "/tmp/gpg-agent.err";
        };
      };
      home.file."${homedir}/gpg-agent.conf".text = ''
        max-cache-ttl ${maxCacheTtl}
        default-cache-ttl ${defaultCacheTtl}
        max-cache-ttl-ssh ${sshCacheTtl}
        enable-ssh-support
        pinentry-program ${pkgs.pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac
      '';
    })
  ];
}
