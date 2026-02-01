{
  self,
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  inherit (lib)
    mkIf
    mkForce
    mkMerge
    mkOrder
    ;
  cfg = osConfig.hrndz;

  # Initialize zsh library
  zshLib = self.lib.fast-zsh-lib { inherit pkgs; };

  # Cached inits configuration
  cachedInits = [
    {
      name = "direnv";
      package = pkgs.direnv;
      initArgs = [
        "hook"
        "zsh"
      ];
      order = 585; # Load early (environment setup)
    }
    {
      name = "zoxide";
      package = pkgs.zoxide;
      initArgs = [
        "init"
        "zsh"
      ];
      order = 590; # Load early (directory jumping)
    }
    {
      name = "fzf";
      package = pkgs.fzf;
      initArgs = [ "--zsh" ];
      order = 600; # Load after core but before prompt
    }
    {
      name = "starship";
      package = pkgs.starship;
      initArgs = [
        "init"
        "zsh"
      ];
      order = 605; # Load late (prompt customization)
    }
  ];
in
{
  config = mkIf cfg.tui.enable {
    home.extraOutputsToInstall = [
      "/share/zsh"
      # TODO: is this already implied by `/share/zsh`?
      "/share/zsh/site-functions"
    ];

    home.packages =
      (with pkgs; [
        zsh-completions
        nix-zsh-completions
      ])
      ++ (zshLib.mkPackages { inherit cachedInits; });

    # command-not-found alt
    programs.command-not-found.enable = false;
    programs.nix-index-database.comma.enable = false;

    programs.zsh = {
      enable = true;
      package = pkgs.zsh;
      dotDir = "${config.xdg.configHome}/zsh";
      # zprof.enable = true;
      envExtra = ''
        if [[ -f  $HOME/.config/zsh/zsh_vars ]]; then
          source $HOME/.config/zsh/zsh_vars
        fi

        # PATH
        if [[ -d "/usr/local/munki" ]]; then
          path=(/usr/local/munki $path)
        fi
      '';
      completionInit = "";
      initContent =
        let
          fast-zsh-init = zshLib.mkInitContent { inherit cachedInits; };
        in
        mkMerge [
          (mkOrder 915 fast-zsh-init)
        ];
      # mkForce ''
      #   # environment
      #   for profile in ''${(z)NIX_PROFILES}; do
      #         fpath+=($profile/share/zsh/site-functions $profile/share/zsh/$ZSH_VERSION/functions $profile/share/zsh/vendor-completions)
      #   done
      #   HELPDIR="${pkgs.zsh}/share/zsh/$ZSH_VERSION/help"
      #
      # '' ++ fast-zsh-init;

      ## things to add
      # source /nix/store/giwji59178p0ih6ndy1llq21ap8apxrm-nix-index-with-full-db-0.1.9/etc/profile.d/command-not-found.sh
      # if [[ -n $GHOSTTY_RESOURCES_DIR ]]; then
      #   source "$GHOSTTY_RESOURCES_DIR"/shell-integration/zsh/ghostty-integration
      # fi
    };
    programs.starship = {
      enable = true;
      enableZshIntegration = false;
      settings = {
        cmd_duration.disabled = true;
        directory = {
          fish_style_pwd_dir_length = 1;
        };
        git_status.use_git_executable = true;
      };
    };
    # plugins/integrations
    programs.zoxide.enable = true;
    programs.zoxide.enableZshIntegration = false;

    # performance tweak
    home.activation.zsh_compile = lib.hm.dag.entryAfter [ "installPackages" ] ''
      rm -f "${config.xdg.configHome}/zsh/.zshrc.zwc"
      rm -f "${config.xdg.configHome}/zsh/.zshenv.zwc"
      ${pkgs.zsh}/bin/zsh -c 'zcompile "${config.xdg.configHome}/zsh/.zshrc"'
      ${pkgs.zsh}/bin/zsh -c 'zcompile "${config.xdg.configHome}/zsh/.zshenv"'
    '';
  };
}
