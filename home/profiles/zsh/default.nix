{
  config,
  pkgs,
  lib,
  ...
}: let
  sshf-src = builtins.readFile ./sshf.sh;
  sshf =
    pkgs.writeScriptBin "sshf" sshf-src;
  my-zsh-completions = pkgs.zsh-completions.overrideAttrs (f: p: {
    installPhase = ''
      install -D --target-directory=$out/share/zsh/site-functions src/*

      # tmuxp install it so avoid collision
      rm -f $out/share/zsh/site-functions/_tmuxp

      # trash-cli install it so avoid collision
      rm -f $out/share/zsh/site-functions/_trash*
    '';
  });
  atuin-init = pkgs.writeText "atuin-init" (builtins.readFile ./atuin-init.zsh);
in
  with lib; {
    home.extraOutputsToInstall = [
      "/share/zsh"
      # TODO: is this already implied by `/share/zsh`?
      "/share/zsh/site-functions"
    ];

    home.packages = with pkgs; [
      my-zsh-completions
      nix-zsh-completions
      sshf
    ];

    programs.zsh = {
      enable = true;
      dotDir = ".config/zsh";
      defaultKeymap = "viins";
      autocd = true;
      # zprof.enable = true;
      history = {
        append = true;
        expireDuplicatesFirst = true;
        extended = true;
        findNoDups = true;
        saveNoDups = true;
        ignoreDups = true;
        ignoreAllDups = true;
        ignorePatterns = ["rm *" "pkill *"];
        ignoreSpace = true;
        share = true;
        save = 9000;
        size = 9999;
      };
      autosuggestion = {
        enable = true;
        strategy = [
          "completion"
        ];
      };
      localVariables = {
        ZSH_AUTOSUGGEST_USE_ASYNC = 1;
        ZSH_AUTOSUGGEST_MANUAL_REBIND = 1;
        FORGIT_FZF_DEFAULT_OPTS = " --exact --cycle --height '80%' ";
      };
      envExtra = ''
        if [[ -f  $HOME/.config/zsh/zsh_vars ]]; then
          source $HOME/.config/zsh/zsh_vars
        fi

        # PATH
        if [[ -d "/usr/local/munki" ]]; then
          path=(/usr/local/munki $path)
        fi

        path=($XDG_BIN_HOME $path)
      '';
      initContent = lib.mkMerge [
        (lib.mkOrder 525 ''
          # ^X^S to insert sudo in front of command
          function prepend-sudo { # Insert "sudo " at the beginning of the line
            if [[ $BUFFER != "sudo "* ]]; then
              BUFFER="sudo $BUFFER"; CURSOR+=5
            fi
          }
          zle -N prepend-sudo
          bindkey -M vicmd '^X^S' prepend-sudo
          bindkey -M viins '^X^S' prepend-sudo

          autoload -U edit-command-line
          zle -N edit-command-line
          bindkey   -M   vicmd   '^X^E'    edit-command-line
          bindkey   -M   viins   '^X^E'    edit-command-line

          bindkey   -M   viins   '^Y'      autosuggest-accept
          bindkey   -M   viins   '^P'      history-search-backward
          bindkey   -M   viins   '^N'      history-search-forward

          # atuin
          bindkey -M viins '^r' atuin-search-viins
          bindkey -M vicmd '/' atuin-search
          bindkey -M vicmd '^[[A' atuin-up-search-vicmd
          bindkey -M viins '^[[A' atuin-up-search-viins
          bindkey -M vicmd '^[OA' atuin-up-search-vicmd
          bindkey -M viins '^[OA' atuin-up-search-viins
          bindkey -M vicmd 'k' atuin-up-search-vicmd
        '')
        # https://github.com/rweng/.zsh/blob/master/options.zsh
        (lib.mkOrder 910 ''
          setopt histreduceblanks         # compact consecutive white space chars (cool)
          setopt histnostore              # don't store history related functio
          setopt interactivecomments      # Allow comments inside commands
          setopt nobeep                   # Never beep
          setopt noflowcontrol            # Disable flow control for Zsh, enable ^S

          # 3.2. Changing Directories
          # -------------------------
          setopt autopushd            # automatically pushd directories on dirstack
          setopt nopushdsilent        # print dirstack after each cd/pushd
          setopt pushdignoredups      # don't push dups on stack
          setopt pushdminus           # pushd -N goes to Nth dir in stack
          export DIRSTACKSIZE=8

          # 3.3. Shell Completion
          # ---------------------
          setopt correct              # try to correct spelling...
          setopt no_correctall        # ...only for commands, not filenames
          setopt no_listbeep          # don't beep on ambiguous listings
          setopt listpacked           # variable col widths (takes up less space)
          setopt completealiases      # complete aliases

          # 3.4. Shell Expansion and Globbing
          # ---------------------------------
          setopt extendedglob         # use extended globbing (#, ~, ^)

          # 3.6. Job Control
          # ----------------
          setopt longlistjobs         # list jobs in long format

        '')
        # other plugins
        (lib.mkOrder 915 ''
          # fzf
          source ${config.programs.fzf.package}/share/fzf/completion.zsh
          source ${config.programs.fzf.package}/share/fzf/key-bindings.zsh

          # zoxide
          source ${
            pkgs.runCommand "zoxide-init-zsh" {} ''
              ${lib.getExe config.programs.zoxide.package} init zsh > $out
            ''
          }

          # direnv
          source ${
            pkgs.runCommand "direnv-hook-zsh" {} ''
              ${lib.getExe config.programs.direnv.package} hook zsh > $out
            ''
          }

          # atuin
          if [[ $options[zle] = on ]]; then
             source ${atuin-init}
          fi
        '')
        (lib.mkOrder 1200 ''
          source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh
        '')
      ];
      completionInit = ''
        autoload -Uz compinit
        zcompdump="''${ZDOTDIR:-$HOME}/.zcompdump"
        if [[ ! -f "$zcompdump" ]] || [[ -n "$(find "$zcompdump" -mmin +720)" ]]; then
          compinit
        else
          compinit -C
        fi
        {
          # Compile zcompdump, if modified, to increase startup speed.
          zcompdump="''${ZDOTDIR:-$HOME}/.zcompdump"
          if [[ -s "$zcompdump" && (! -s "''${zcompdump}.zwc" || "$zcompdump" -nt "''${zcompdump}.zwc") ]]; then
            zcompile "$zcompdump"
          fi
        } &!
      '';
      plugins = [
        {
          name = "forgit";
          file = "share/zsh/zsh-forgit/forgit.plugin.zsh";
          src = pkgs.zsh-forgit;
        }
      ];
    };
    programs.starship = {
      enable = true;
      enableZshIntegration = false;
      settings = {
        aws.disabled = true;
        cmd_duration.disabled = true;
        directory = {
          fish_style_pwd_dir_length = 1;
        };
      };
    };
    programs.fzf.enableZshIntegration = false;
    programs.direnv.enableZshIntegration = false;
    programs.zoxide.enable = true;
    programs.zoxide.enableZshIntegration = false;
    programs.atuin.enable = true;
    programs.atuin.enableZshIntegration = false;
    programs.atuin.settings = {
      auto_sync = false;
      search_mode = "fuzzy";
    };
    home.activation.zsh_compile = lib.hm.dag.entryAfter ["installPackages"] ''
      rm -f "${config.xdg.configHome}/zsh/.zshrc.zwc"
      ${pkgs.zsh}/bin/zsh -c 'zcompile "${config.xdg.configHome}/zsh/.zshrc"'
      ${pkgs.zsh}/bin/zsh -c 'zcompile "${config.xdg.configHome}/zsh/.zshenv"'
    '';
  }
