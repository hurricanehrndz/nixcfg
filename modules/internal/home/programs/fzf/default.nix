{
  lib,
  pkgs,
  options,
  osConfig,
  ...
}:
let
  l = lib // builtins;
  cfg = osConfig.hrndz;
  packageCommand = pkg: args: (l.getExe pkg) + " " + (l.cli.toCommandLineShellGNU { } args);
  find = packageCommand pkgs.fd;
  findFiles = args: find (args // { type = "f"; });
  findDirs = args: find (args // { type = "d"; });
  dirPreviewCommand = "${l.getBin pkgs.eza}/bin/eza --tree {} | head -n 200";
  filePreviewCommand = "${l.getBin pkgs.bat}/bin/bat -n --color=always {}";

  fileWidget = {
    command = findFiles {
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
    options = [
      "--preview '${filePreviewCommand}'"
    ];
  };
  changeDirWidget = {
    command = findDirs { };
    options = [
      "--tiebreak=index"
      "--preview '${dirPreviewCommand}'"
    ];
  };

  # Renamed to fileWidget.* / changeDirWidget.* on main-branch home-manager;
  # the 26.05 release only has the flat names.
  widgets =
    if options.programs.fzf ? fileWidget then
      { inherit fileWidget changeDirWidget; }
    else
      {
        fileWidgetCommand = fileWidget.command;
        fileWidgetOptions = fileWidget.options;
        changeDirWidgetCommand = changeDirWidget.command;
        changeDirWidgetOptions = changeDirWidget.options;
      };
in
{
  config = l.mkIf cfg.roles.terminalUser.enable {
    programs.fzf = {
      enable = true;
      defaultOptions = [
        "--height=40%"
        "--layout=reverse"
        "--border"
        "--bind"
        "ctrl-f:preview-page-down,ctrl-b:preview-page-up"
      ];

      enableZshIntegration = false;
    }
    // widgets;
  };
}
