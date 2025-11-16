{
  pkgs,
  inputs,
  ...
}:
let
  l = inputs.nixpkgs.lib // builtins;
  packageCommand = pkg: args: (l.getExe pkg) + " " + (l.cli.toGNUCommandLineShell { } args);
  find = packageCommand pkgs.fd;
  findFiles = args: find (args // { type = "f"; });
  findDirs = args: find (args // { type = "d"; });
  dirPreviewCommand = "${l.getBin pkgs.eza}/bin/eza --tree {} | head -n 200";
in
{
  programs.fzf = {
    enable = true;
    defaultOptions = [
      "--height=40%"
      "--layout=reverse"
      "--border"
      "--bind"
      "ctrl-f:preview-page-down,ctrl-b:preview-page-up"
    ];

    fileWidgetCommand = findFiles {
      hidden = true;
      follow = true;
      exclude = [
        ".git"
        ".devenv"
        ".direnv"
        ".std"
        "node_modules"
        "vendor"
      ];
    };
    fileWidgetOptions = [
      "--preview 'bat -n --color=always {}'"
    ];

    changeDirWidgetCommand = findDirs { };
    changeDirWidgetOptions = [
      "--tiebreak=index"
      "--preview '${dirPreviewCommand}'"
    ];
  };
}
