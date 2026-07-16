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
  config = mkIf cfg.roles.terminalDeveloper.enable {
    programs.direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
      };
      enableZshIntegration = false;
      # `layout poetry` activates a project's Poetry virtualenv, mirroring the
      # built-in `layout python`. Imported from the Yelp dotfield direnvrc.
      # nix-direnv is sourced separately via direnv/lib, so this stdlib only
      # adds the custom layout.
      stdlib = ''
        use_mise() {
          direnv_load ${lib.getExe pkgs.mise} direnv exec
        }

        layout_poetry() {
          if [[ ! -f pyproject.toml ]]; then
            log_error 'No pyproject.toml found. Use `poetry new` or `poetry init` to create one first.'
            exit 2
          fi

          local VENV=$(poetry env list --full-path | cut -d' ' -f1)
          if [[ -z $VENV || ! -d $VENV/bin ]]; then
            log_error 'No poetry virtual environment found. Use `poetry install` to create one first.'
            exit 2
          fi

          export VIRTUAL_ENV=$VENV
          export POETRY_ACTIVE=1
          PATH_add "$VENV/bin"
        }
      '';
    };
  };
}
