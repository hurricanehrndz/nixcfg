{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (lib) mkIf;
  cfg = osConfig.hrndz;
in
{
  config = mkIf cfg.cli.enable {
    home.packages = with pkgs; [
      delta
      difftastic
      gh
      local.git-age-filter
    ];

    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "Carlos Hernandez";
          email = "carlos@hrndz.ca";
        };
        alias = {
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
        init = {
          defaultBranch = "main";
        };
        pull.ff = "only";
        safe.directory = "/etc/nixos";
        core = {
          whitespace = "-indent-with-non-tab,trailing-space,cr-at-eol";
          pager = "delta";
        };
        delta = {
          light = true;
          line-numbers = true;
          features = "OneHalfLight";
          syntax-theme = "OneHalfLight";
        };
        interactive = {
          diffFilter = "delta --color-only";
        };
        diff.tool = "difftastic";
        diff.age = {
          textconv = "git-age-filter diff";
        };
        difftool = {
          prompt = false;
          "difftastic".cmd = "difft \"$LOCAL\" \"$REMOTE\"";
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
        filter = {
          # https://github.com/bphenriques/dotfiles/blob/4fce72c08e7d2b1c9eadbaefb8db3d2b8ac99eb9/bin/sops-git-filter.sh
          age = {
            clean = "git-age-filter clean %f";
            smudge = "git-age-filter smudge";
            required = true;
          };
        };
        url = {
          "git@github.com:" = {
            pushInsteadOf = [
              "github:"
              "gh:"
              "git://github.com/"
              "https://github.com/"
            ];
          };
          "https://github.com/" = {
            insteadOf = [
              "github:"
              "gh:"
            ];
          };
          "git@github.com:hurricanehrndz/" = {
            insteadOf = "me:";
          };
          "git@github.yelpcorp.com:" = {
            insteadOf = [
              "y:"
              "https://github.yelpcorp.com/"
            ];
          };
        };
      };
      signing = {
        key = "0D2565B7C6058A69";
        signByDefault = true;
      };

      ignores = [
        # Direnv files           #
        ##########################
        ".direnv/"
        ".envrc"

        # Editing tools and IDEs #
        ##########################
        "*.swp"
        "*~"

        # Logs and databases #
        ######################
        "*.log"
        "*.sql"
        "*.sqlite"

        # OS generated files #
        ######################
        ".DS_Store"
        ".DS_Store?"
        "._*"
        ".Spotlight-V100"
        ".Trashes"
        "ehthumbs.db"
        "Thumbs.db"

        # vim submodules files #
        ########################
        "doc/tags"
        "*/doc/tags"

        # Claude Code local files
        ########################
        ".claude/settings.local.json"
        "CLAUDE.local.md"
        "tmp/"
        ".claude/tmp/"
      ];
    };
  };
}
