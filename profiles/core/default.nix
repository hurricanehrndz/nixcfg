# Copyright (c) 2022-2023 Chris Montgomery
# Modifications Copyright (c) 2023 Carlos Hernandez
# 2023-02-21: Adopting for personal needs
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
## Sources:
# https://github.com/montchr/dotfield/blob/d9fd62dbf2f6c4f3f8e61cf0b0f87123de720459/COPYING
{
  config,
  lib,
  pkgs,
  ...
}: let
  l = lib // builtins;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in {
  imports = [
    ./nix-config.nix
    ./system-packages.nix
  ];

  time.timeZone = l.mkDefault "America/Edmonton";

  environment.variables = {
    EDITOR = "vim";
    KERNEL_NAME =
      if pkgs.stdenv.isDarwin
      then "darwin"
      else "linux";
    LC_ALL = "en_US.UTF-8";
    LANG = "en_US.UTF-8";
  };

  environment.shells = with pkgs; [
    bashInteractive
    zsh
  ];

  # Install completions for system packages.
  environment.pathsToLink =
    ["/share/bash-completion"]
    ++ (l.optional config.programs.zsh.enable "/share/zsh");

  programs.zsh = {
    enable = l.mkDefault true;
    shellInit = l.mkDefault "";
    loginShellInit = l.mkDefault "";
    interactiveShellInit = l.mkDefault "";

    # Prompts/completions/widgets should never be initialised at the
    # system-level because it will need to be initialised a second time once the
    # user's zsh configs load.
    promptInit = l.mkForce "";
    enableCompletion = l.mkForce false;
    enableBashCompletion = l.mkForce false;
  };
}
