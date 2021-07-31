{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hurricane.configs.git;
in
{
  options.hurricane = {
    configs.git.enable = mkEnableOption "enable custom nix conf";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      delta
    ];
    programs.git = {
      package = pkgs.gitAndTools.gitFull;
      enable = true;
      userName = "Carlos Hernandez";
      userEmail = "hurricanehrndz@techbyte.ca";
      ignores = [
        "*.swp"
        "*~"
        "*.log"
        "*.sql"
        "*.sqlite"
        ".DS_Store"
        ".DS_Store?"
        "._*"
        ".Spotlight-V100"
        ".Trashes"
        "ehtumb.db"
        "Thumbs.db"
        "doc/tags"
        "*/doc/tags"
      ];
      extraConfig = {
        advice = {
          addIgnoredFile = false;
          detachedHead = false;
        };
        color = {
          ui = "auto";
          pager = true;
          branch = {
            current = "yellow reverse";
            local   = "yellow";
            remote  = "green";
          };
          diff = {
            meta = "yellow bold";
            frag = "magenta bold";
            old  = "red bold";
            new  = "green bold";
          };
          status = {
            added = "yellow";
            changed = "green";
            untracked = "cyan";
          };
        };
        commit.verbose = true;
        core = {
          editor = config.home.sessionVariables.EDITOR;
          pager = "delta --theme='${config.home.sessionVariables.BAT_THEME}'";
          whitespace = "-indent-with-non-tab,trailing-space,cr-at-eol";
        };
        # git diff: detect renames aswell as copies
        diff.renames = "copies";
        merge = {
          tool = "fugitive";
        };
        mergetool = {
          # Include summaries of merged commits in newly created merge commit messages
          log = true;
          keepBackup = false;
          # https://github.com/tpope/vim-fugitive/issues/1306
          fugitive = {
            cmd = "nvim -f -c \"Gvdiffsplit!\" \"$MERGED\"";
          };
        };
        url = {
          "git://github.com/" = {
            insteadOf = [ "github:" "https://github.com/" ];
          };
          "git@github.com:" = {
            pushInsteadOf = [ "github:" "git://github.com/" ];
          };
        };
        github.username = "hurricanehrndz";
        help.autocorrect = 1;
        pull.rebase = true;
        status.showStash = true;
        stash.showPatch = true;
      };
    };
    programs.zsh = {
      envExtra = ''
        _git_log_oneline_format='%C(green)%h%C(reset) %s%C(red)%d %C(reset)%C(blue)Sig:%G?%C(reset)%n'
      '';
      shellAliases = with pkgs; {
        "g" = "${git}/bin/git";
        "gcl" = "${git}/bin/git clone --recursive";
        "gf" = "${git}/bin/git fetch";
        "gco" = "${git}/bin/git checkout";
        "gcm" = "${git}/bin/git checkout master";
        "gst" = "${git}/bin/git status";
        "gss" = "${git}/bin/git status --short";
        "glg" = ''${git}/bin/git log --topo-order --all --graph --pretty=format:"''${_git_log_oneline_format}"'';
        "grsh" = "${git}/bin/git reset --hard";
        "grst" = "${git}/bin/git reset";
        "gd" = "${git}/bin/git diff";
        "gdc" = "${git}/bin/git diff --cached";
        "gc" = "${git}/bin/git commit --verbose";
        "gcs" = "${git}/bin/git commit -S --verbose";
        "gca" = "${git}/bin/git commit -a --verbose";
        "gca!" = "${git}/bin/git commit -a --amend --verbose";
        "ga" = "${git}/bin/git add";
        "gp" = "${git}/bin/git push";
        "gpf" = "${git}/bin/git push --force-with-lease";
        "gsoc" = "${git}/bin/git rebase --exec \"${git} commit --amend --no-edit -n -S\" -i";
      };
    };
  };
}
