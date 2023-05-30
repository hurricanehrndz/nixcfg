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
      rm $out/share/zsh/site-functions/_tmuxp

      # trash-cli install it so avoid collision
      rm $out/share/zsh/site-functions/_trash*
    '';
  });
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
      enableCompletion = true;
      autocd = true;
      history = {
        expireDuplicatesFirst = true;
        extended = true;
        ignoreDups = true;
        ignorePatterns = ["rm *" "pkill *"];
        ignoreSpace = true;
        save = 10000;
        share = true;
        size = 10000;
      };
      initExtraFirst = ''
        # xdg bin home
        path=("$HOME/.local/bin" $path)

        # Initialise the builtin profiler -- run `zprof` to read results
        zmodload zsh/zprof
      '';
      initExtraBeforeCompInit = ''
        # ^X^S to insert sudo in front of command
        function prepend-sudo { # Insert "sudo " at the beginning of the line
          if [[ $BUFFER != "sudo "* ]]; then
            BUFFER="sudo $BUFFER"; CURSOR+=5
          fi
        }
        zle -N prepend-sudo

        setopt interactivecomments      # Allow comments inside commands
        setopt autopushd                # Maintain directories in a heap
        setopt pushdignoredups          # Remove duplicates from directory heap
        setopt pushdminus               # Invert + and - meanings
        setopt autocd                   # Don't need to use `cd`
        setopt longlistjobs             # Display PID when using jobs
        setopt nobeep                   # Never beep
        setopt noflowcontrol            # Disable flow control for Zsh, enable ^S

        bindkey -M vicmd '^X^S' prepend-sudo
        bindkey -M viins '^X^S' prepend-sudo

        autoload -U edit-command-line
        zle -N edit-command-line

        bindkey   -M   viins   '^Y'      autosuggest-accept
        bindkey   -M   vicmd   '^X^E'    edit-command-line
        bindkey   -M   viins   '^X^E'    edit-command-line
        bindkey   -M   viins   '^P'      history-search-backward
        bindkey   -M   viins   '^N'      history-search-forward

      '';
      completionInit = ''
        autoload -Uz compinit
        if [[ -z "$(find "''${ZDOTDIR:-$HOME}" -mtime 0 -name '.zcompdump')" ]]; then
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
        {
          name = "autosuggestions";
          file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
          src = pkgs.zsh-autosuggestions;
        }
        {
          name = "fast-syntax-highlighting";
          file = "share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh";
          src = pkgs.zsh-fast-syntax-highlighting;
        }
      ];
      initExtra = ''
        # FZF opts
        export FORGIT_FZF_DEFAULT_OPTS=" --exact --cycle --height '80%' "

        if [[ -f  $HOME/.config/zsh/zsh_vars ]]; then
          source $HOME/.config/zsh/zsh_vars
        fi

        # PATH
        path=($XDG_BIN_HOME $path)
      '';
    };
    programs.starship = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        aws.disabled = true;
        cmd_duration.disabled = true;
        directory = {
          fish_style_pwd_dir_length = 1;
        };
      };
    };
    programs.fzf.enableZshIntegration = true;
    programs.zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
    home.activation.zsh_compile = lib.hm.dag.entryAfter ["installPackages"] ''
      rm -f "${config.xdg.configHome}/zsh/.zshrc.zwc"
      ${pkgs.zsh}/bin/zsh -c 'zcompile "${config.xdg.configHome}/zsh/.zshrc"'
    '';
  }
