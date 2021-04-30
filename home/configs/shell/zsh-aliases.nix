{ pkgs, ... }: {
  aliases = with pkgs; {
    # Aliases that make commands colourful.
    "grep" = "${gnugrep}/bin/grep --color=auto";
    "fgrep" = "${gnugrep}/bin/fgrep --color=auto";
    "egrep" = "${gnugrep}/bin/egrep --color=auto";
    # exa
    "ls" = "${exa}/bin/exa";
    "ll" = "${exa}/bin/exa -lhF --group-directories-first";
    "la" = "${exa}/bin/exa -alhF --group-directories-first";
    "lt" = "${exa}/bin/exa -alhF --sort modified";
    "l" = "${exa}/bin/exa -1 --group-directories-first -F";
    "tree" = "${exa}/bin/exa -T";
    # Aliases for `cat` to `bat`.
    "cat" = "${bat}/bin/bat";
    # tmux
    "tm" = "${tmux}/bin/tmux new-session -A -s main";
    # general
    "mkdir" = "mkdir -p";
    "nixfmt" = "${nixfmt}/bin/nixfmt --width 120";
  };
}
