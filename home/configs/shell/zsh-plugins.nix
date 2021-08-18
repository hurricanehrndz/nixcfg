{ pkgs, ... }: {
  plugins = [
    {
      name = "zsh-defer";
      file = "zsh-defer.plugin.zsh";
      src = pkgs.fetchFromGitHub {
        owner = "romkatv";
        repo = "zsh-defer";
        rev = "master";
        sha256 = "sha256-j9aBoEIt21L7jMUALm7BGirNo3K7unRrewOTviXMOQg=";
      };
    }
    {
      # https://github.com/starship/starship/issues/1721#issuecomment-780250578
      # stop eating lines this is not pacman
      name = "zsh-vi-mode";
      file = "zsh-vi-mode.plugin.zsh";
      src = pkgs.fetchFromGitHub {
        owner = "jeffreytse";
        repo = "zsh-vi-mode";
        rev = "master";
        sha256 = "sha256-mWs08JtEG128sQcflKWHw+dA73T90swCis2mME5U32E=";
      };
    }
    {
      name = "zsh-utils";
      file = "history.plugin.zsh";
      src = ./zsh-utils;
    }
    {
      name = "zsh-utils";
      file = "directory.plugin.zsh";
      src = ./zsh-utils;
    }
    {
      name = "fast-syntax-highlighting";
      file = "fast-syntax-highlighting.plugin.zsh";
      src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
      apply = "zsh-defer";
    }
    {
      name = "zsh-history-substring-search";
      file = "zsh-history-substring-search.zsh";
      src = "${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search";
    }
    {
      name = "zsh-autosuggestions";
      file = "zsh-autosuggestions.zsh";
      src = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
      apply = "zsh-defer";
    }
    {
      name = "zsh-utils";
      file = "completion.plugin.zsh";
      src = ./zsh-utils;
    }
  ];
}
