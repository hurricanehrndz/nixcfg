{pkgs, ...}: {
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
    };
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

      # FZF opts
      export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
      export FORGIT_FZF_DEFAULT_OPTS=" --exact --cycle --height '80%' "
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
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
