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
  self,
  withSystem,
  ...
}:
let
  inherit (self) inputs sharedProfiles;
  inherit (self.homeModules) homeManagerSettings;

  l = inputs.nixpkgs.lib // builtins // self.lib;

  darwinModules = l.rakeLeaves ./modules;
  darwinMachines = l.rakeLeaves ./machines;
  darwinProfiles = l.rakeLeaves ./profiles;

  roles = import ./roles.nix { inherit sharedProfiles darwinProfiles; };

  defaultModules = [
    sharedProfiles.core
    darwinProfiles.core
    homeManagerSettings
    inputs.home-manager.darwinModules.home-manager
    inputs.agenix.darwinModules.age
    inputs.determinate.darwinModules.default
  ];

  makeDarwinSystem =
    hostName:
    darwinArgs@{ system, ... }:
    withSystem system (
      ctx@{
        inputs',
        packages,
        pkgs,
        ...
      }:
      l.makeOverridable inputs.darwin.lib.darwinSystem {
        inherit system;
        pkgs = darwinArgs.pkgs or pkgs;
        modules =
          defaultModules
          ++ (l.recAttrValues darwinModules)
          ++ roles.workstation
          ++ (darwinArgs.modules or [ ])
          ++ [
            {
              _module.args = {
                inherit inputs';
                inherit (ctx.config) packages;
                isNixos = false;
              };
              networking.hostName = hostName;
              networking.computerName = hostName;
            }
            darwinMachines.${hostName}
          ];
        specialArgs = {
          inherit
            self
            inputs
            packages
            system
            ;
          inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux isMacOS;
        };
      }
    );
in
{
  flake.darwinModules = darwinModules;
  flake.darwinConfigurations = {
    HX7YG952H5 = makeDarwinSystem "HX7YG952H5" {
      system = "aarch64-darwin";
      modules = [ ];
    };
    LH9KCR6DJX = makeDarwinSystem "LH9KCR6DJX" {
      system = "aarch64-darwin";
      modules = [ ];
    };
  };
}
