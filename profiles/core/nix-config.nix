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
#
# Copyright (C) 2021 Gytis Ivaskevicius
# SPDX-License-Identifier: MIT
#
## Sources:
# https://github.com/montchr/dotfield/blob/d9fd62dbf2f6c4f3f8e61cf0b0f87123de720459/COPYING
# https://github.com/gytis-ivaskevicius/flake-utils-plus/blob/2bf0f91643c2e5ae38c1b26893ac2927ac9bd82a/LICENSE
{
  self,
  lib,
  pkgs,
  ...
}: let
  inherit (self) inputs;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  l = lib // builtins;
  inputFlakes = l.filterAttrs (_: v: v ? outputs) inputs;
  inputsToPaths = l.mapAttrs' (n: v: {
    name = "nix/inputs/${n}";
    value.source = v.outPath;
  });
in {
  imports = [
    ./substituters/common.nix
    ./substituters/nix-community.nix
    ./substituters/nixpkgs-update.nix
  ];

  environment.etc = inputsToPaths inputs;
  nix = {
    package = pkgs.nix;
    nixPath = lib.mkForce [
      "nixpkgs=${pkgs.path}"
      "home-manager=${inputs.home-manager}"
      "darwin=${inputs.darwin}"
      "/etc/nix/inputs"
    ];
    registry = l.mapAttrs (_: flake: {inherit flake;}) inputFlakes;
    settings = {
      auto-optimise-store = false;
      experimental-features = ["nix-command" "flakes"];
      sandbox = l.mkDefault (!isDarwin);
      allowed-users = ["*"];
      trusted-users = ["root" "@wheel"];
    };

    gc.automatic = true;

    extraOptions = ''
      warn-dirty = false
    '';
  };
}
