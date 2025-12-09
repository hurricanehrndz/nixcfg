{
  lib,
  pkgs,
  osConfig,
  ...
}:
let
  l = lib // builtins;
  cfg = osConfig.hrndz;
  packageCommand = pkg: args: (l.getExe pkg) + " " + (l.cli.toGNUCommandLineShell { } args);
  find = packageCommand pkgs.fd;
  findFiles = args: find (args // { type = "f"; });
  findDirs = args: find (args // { type = "d"; });
  dirPreviewCommand = "${l.getBin pkgs.eza}/bin/eza --tree {} | head -n 200";
  filePreviewCommand = "${l.getBin pkgs.bat}/bin/bat -n --color=always {}";
in
{
  config = l.mkIf cfg.tui.enable {
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
        "--preview '${filePreviewCommand}'"
      ];

      changeDirWidgetCommand = findDirs { };
      changeDirWidgetOptions = [
        "--tiebreak=index"
        "--preview '${dirPreviewCommand}'"
      ];
    };
  };
}
