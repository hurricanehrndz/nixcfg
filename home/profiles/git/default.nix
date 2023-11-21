{pkgs, ...}: {
  home.packages = with pkgs; [
    git-crypt
    difftastic
    delta
  ];

  programs.git = {
    enable = true;
    userName = "Carlos Hernandez";
    userEmail = "carlos@hrndz.ca";
    extraConfig = {
      pull.ff = "only";
      safe.directory = "/etc/nixos";
    };

    aliases = {
      # logging
      plog = "log --graph --pretty='format:%C(red)%d%C(reset) %C(yellow)%h%C(reset) %ar %C(green)%aN%C(reset) %s'";
      tlog = "log --stat --since='1 Day Ago' --graph --pretty=oneline --abbrev-commit --date=relative";
      l = "!git --no-pager log -1 --format=format:\"$path: %Cgreen%s%Creset (%Cred$(git rev-parse --abbrev-ref HEAD)%Creset/%ar)\"; echo ";
      x = "log -10 --format=format:'%Cgreen%h%Creset %Cred%d%Creset %s %Cblue(%ar by %an)%Creset'";
      xlog = "!git x";
      xlogall = "log -10 --branches --format=format:'%Cgreen%h%Creset %Cred%d%Creset %s %Cblue(%ar by %an)%Creset'";
      xlogfull = "log --format=format:'%Cgreen%h%Creset %Cred%d%Creset %s %Cblue(%ar by %an)%Creset'";
      xlogfullall = "log --branches --format=format:'%Cgreen%h%Creset %Cred%d%Creset %s %Cblue(%ar by %an)%Creset'";
      glog = "log --oneline --decorate --stat --graph";
      tree = "log --decorate --pretty=oneline --abbrev-commit --graph";
      lc = "log ORIG_HEAD.. --stat --no-merges --graph";
      lg1 = "log --graph --abbrev-commit --decorate --date=relative --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)'";
      lg2 = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all";
      lg = "!git lg1";
      # other stuff
      clean-all = "clean -dfq";
    };

    extraConfig = {
      user = {
        signingKey = "0D2565B7C6058A69";
      };
      core = {
        whitespace = "-indent-with-non-tab,trailing-space,cr-at-eol";
        pager = "delta";
      };
      interactive = {
        diffFilter = "delta --color-only";
      };
      diff.tool = "difftastic";
      difftool = {
        prompt = false;
        "difftastic".cmd = "difft \"$LOCAL\" \"$REMOTE\"" ;
      };
      pager.difftool = true;
      merge = {
        tool = "diffview";
        log = true;
      };
      mergetool = {
        "diffview" = {
          cmd = "nvim -f -c 'DiffviewOpen'";
        };
        keepBackup = false;
      };
      status = {
        showStash = true;
      };
      stash = {
        showPatch = true;
      };
      commit = {
        verbose = true;
        # gpgSign= true;
      };
      url = {
        "git@github.com:" = {
          pushInsteadOf = [
            "github:"
            "git://github.com/"
            "https://github.com/"
          ];
        };
        "https://github.com/" = {
          insteadOf = "github:";
        };
      };
    };
  };
}
