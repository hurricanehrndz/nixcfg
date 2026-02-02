{
  inputs,
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
    ;
  cfg = osConfig.hrndz;

  # Initialize zsh library
  fzl = self.lib.fast-zsh-lib { inherit pkgs; };

  # zsh raw scripts
  rawScripts = [
    {
      name = "default-nix-environment";
      content = ''
        # Nix environment -- this will provide completions from nix pkgs i.e. home.packages
        for profile in ''${(z)NIX_PROFILES}; do
              fpath+=($profile/share/zsh/site-functions $profile/share/zsh/$ZSH_VERSION/functions $profile/share/zsh/vendor-completions)
        done
        HELPDIR="${pkgs.zsh}/share/zsh/$ZSH_VERSION/help"
      '';
      order = 160;
    }
  ];

  plugins = [
    {
      name = "zephyr-environment";
      src = inputs.zephyr-zsh-src;
      file = "plugins/environment/environment.plugin.zsh";
      order = 150;
    }
    {
      name = "zephyr-editor";
      src = inputs.zephyr-zsh-src;
      file = "plugins/editor/editor.plugin.zsh";
      order = 200;
    }
    {
      name = "zephyr-history";
      src = inputs.zephyr-zsh-src;
      file = "plugins/history/history.plugin.zsh";
      order = 300;
    }
    {
      name = "zephyr-directory";
      src = inputs.zephyr-zsh-src;
      file = "plugins/directory/directory.plugin.zsh";
      order = 300;
    }
    {
      name = "zephyr-color";
      src = inputs.zephyr-zsh-src;
      file = "plugins/color/color.plugin.zsh";
      order = 300;
    }
    {
      name = "zephr-completion";
      src = inputs.zephyr-zsh-src;
      file = "plugins/completion/completion.plugin.zsh";
      order = 800;
    }
    {
      name = "zsh-syntax-highlighting";
      src = pkgs.zsh-syntax-highlighting;
      file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
      order = 1900; # Load last
      defer = true;
    }
    {
      name = "zsh-autosuggestions";
      src = pkgs.zsh-autosuggestions;
      file = "share/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh";
      order = 2000; # Load last
      defer = true;
    }
  ];

  customPlugins = fzl.mkPluginsFromDir {
    dir = ./plugins;
    namePrefix = "custom";
  };

  # ZSH dotDir configuration - define once to avoid circular deps
  dotDir = "${config.xdg.configHome}/zsh";

  # Cached inits configuration
  cachedInits = [
    {
      name = "fzf";
      package = pkgs.fzf;
      initArgs = [ "--zsh" ];
      order = 500; # Load after core but before prompt
    }
    {
      name = "starship";
      package = pkgs.starship;
      initArgs = [
        "init"
        "zsh"
      ];
      order = 650; # Load before completion
    }
    {
      name = "zoxide";
      package = pkgs.zoxide;
      initArgs = [
        "init"
        "zsh"
      ];
      order = 1500; # Load late
      defer = true;
    }
    {
      name = "direnv";
      package = pkgs.direnv;
      initArgs = [
        "hook"
        "zsh"
      ];
      order = 1600; # Load late
      defer = true;
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

    # Add plugin files to dotDir
    home.file = fzl.mkPluginFiles {
      inherit
        cachedInits
        rawScripts
        dotDir
        ;
      plugins = plugins ++ customPlugins;
    };

    home.packages = with pkgs; [
      zsh-completions
      nix-zsh-completions
    ];

    # command-not-found alt
    programs.command-not-found.enable = false;
    programs.nix-index-database.comma.enable = false;

    programs.zsh = {
      enable = true;
      package = pkgs.zsh;
      dotDir = dotDir;
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
          fast-zsh-init = fzl.mkInitContent {
            inherit
              cachedInits
              rawScripts
              dotDir
              ;
            plugins = plugins ++ customPlugins;
          };
        in
        mkForce fast-zsh-init;

      ## things to add
      # source /nix/store/giwji59178p0ih6ndy1llq21ap8apxrm-nix-index-with-full-db-0.1.9/etc/profile.d/command-not-found.sh
    };
    programs.starship = {
      enable = true;
      enableZshIntegration = false;
      settings = {
        command_timeout = 500;
        scan_timeout = 10;

        # Inserts a blank line between shell prompts
        add_newline = true;

        format = lib.concatStrings [
          "$username"
          "$hostname"
          "$directory"
          "$git_branch"
          "$git_state"
          "$git_status"
          "$python"
          "$cmd_duration"
          "$line_break"
          "$character"
        ];

        directory = {
          fish_style_pwd_dir_length = 1;
          truncate_to_repo = false;
        };
        git_status = {
          ignore_submodules = true;
          # use_git_executable = true;
        };
        python.python_binary = [ ];
        cmd_duration.disabled = true;
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
