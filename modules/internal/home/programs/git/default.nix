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
          # zsh-style git shortcuts, invoked as `g <alias>` from the shell.
          aa = "add --all";
          b = "branch";
          ba = "branch -a";
          c = "commit --verbose";
          ca = "commit --verbose --amend";
          caa = "commit --verbose --amend --all";
          cs = "commit --verbose --sign";
          d = "diff";
          dc = "diff --cached";
          f = "fetch";
          fm = "pull";
          main = "switch main";
          master = "switch master";
          p = "push";
          pc = "push --set-upstream origin HEAD";
          pf = "push --force-with-lease --force-if-includes";
          resign = "rebase --exec \"git commit --amend --no-edit -n -S\" -i";
          ss = "status --short";
          st = "status";
          sw = "switch";
          swc = "switch -c";
          unstage = "restore --staged";
          # discard staged + unstaged changes to tracked files (scoped
          # alternative to `discard`/reset --hard, which also moves HEAD)
          restore-all = "restore --staged --worktree .";

          # logging
          tlog = "log --stat --since='1 Day Ago' --graph --pretty=oneline --abbrev-commit --date=relative";
          l = "!git --no-pager log -1 --format=format:\"$path: %Cgreen%s%Creset (%Cred$(git rev-parse --abbrev-ref HEAD)%Creset/%ar)\"; echo ";
          lc = "log ORIG_HEAD.. --stat --no-merges --graph";
          # lg: compact one-line graph (daily driver)
          lg = "log --decorate --pretty=oneline --abbrev-commit --graph";
          # lgs: compact graph with per-commit file stats
          lgs = "log --oneline --decorate --stat --graph";
          # lga: detailed graph across all branches, plus signature status
          lga = "log --all --graph --abbrev-commit --decorate --date=relative --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset) %C(blue)Sig:%G?%C(reset)%C(bold yellow)%d%C(reset)'";
          # lm: full single-commit view with body
          lm = "log --topo-order --pretty=format:'%C(bold)Commit:%C(reset) %C(green)%H%C(red)%d%n%C(bold)Author:%C(reset) %C(cyan)%an <%ae>%n%C(bold)Date:%C(reset)   %C(blue)%ai (%ar)%C(reset)%n%+B'";
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
        # The age clean/smudge/diff filters are configured per-repo by
        # `git-age-filter install` (writes .git/config), not globally. That way
        # a fresh clone has no filter driver and checks out ciphertext instead of
        # aborting on a required filter the machine may not have. Run `install`
        # as step 1 when onboarding a clone.
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

        # AI local files
        ########################
        ".claude/settings.local.json"
        "CLAUDE.local.md"
        "tmp/"
        ".claude/tmp/"
        ".worktrees/"
        # pi coding agent — local/generated project artifacts                                                                                                                                                                                      │
        ".pi/git/"
        ".pi/npm/"
        ".pi/tmp/"
        ".pi/cache/"
        ".pi/logs/"
        ".pi/sessions/"
        ".pi/pi-debug.log"
        ".pi/.ENABLE_PI_DOCS"
      ];
    };
  };
}
