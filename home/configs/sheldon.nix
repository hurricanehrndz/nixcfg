{ config, lib, ... }:

with lib;
let
  cfg = config.hurricane.configs.sheldon;
in
{
  options.hurricane.configs.sheldon.enable = mkEnableOption "sheldon config";

  config = mkIf cfg.enable {
    programs.sheldon = {
      enable = true;
      settings = ''
        shell = "zsh"
        [templates]
        fpath = 'fpath+=( "{{ dir }}" )'
        defer = { value = 'zsh-defer source "{{ file }}"', each = true }

        # zsh plugins
        [plugins.zsh-defer]
        github = "romkatv/zsh-defer"

        [plugins.skim]
        github = "lotabout/skim"

        # specify completion sources before module
        [plugins.compeltions]
        github = "zsh-users/zsh-completions"

        # directory plugin from prezto
        [plugins.directory]
        github = "sorin-ionescu/prezto"
        use = ["modules/directory/*.zsh"]

        # initalize history options and completion
        [plugins.zsh-utils]
        github = "belak/zsh-utils"
        use = ["history/*.zsh", "completion/*.zsh"]

        # time consuming plugins
        [plugins.zsh-syntax-highlighting]
        github = "zsh-users/zsh-syntax-highlighting"
        apply = ["defer"]

        # history needs to come after highlighting
        [plugins.zsh-history-substring-search]
        github = "zsh-users/zsh-history-substring-search"

        [plugins.zsh-autosuggestions]
        github = "zsh-users/zsh-autosuggestions"
        apply = ["defer"]
      '';
    };
  };
}
