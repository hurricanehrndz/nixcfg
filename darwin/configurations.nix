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
}: let
  inherit
    (self)
    inputs
    sharedProfiles
    ;
  inherit
    (inputs.digga.lib)
    flattenTree
    rakeLeaves
    ;

  inherit (self.darwinModules) homeManagerSettings;

  l = inputs.nixpkgs.lib // builtins;

  roles = import ./roles.nix {inherit sharedProfiles darwinProfiles;};

  darwinModules = rakeLeaves ./modules;
  darwinMachines = rakeLeaves ./machines;
  darwinProfiles = rakeLeaves ./profiles;

  defaultModules = [
    sharedProfiles.core
    darwinProfiles.core
    homeManagerSettings
    inputs.home-manager.darwinModules.home-manager
  ];

  makeDarwinSystem = hostName: darwinArgs @ {system, ...}:
    withSystem system (
      ctx @ {
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
            ++ (l.attrValues (flattenTree darwinModules))
            ++ roles.workstation
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
in {
  flake.darwinConfigurations = {
    CarlosslMachine = makeDarwinSystem "CarlosslMachine" {
      system = "aarch64-darwin";
      modules = [];
    };
    VPXK04PX7G = makeDarwinSystem "VPXK04PX7G" {
      system = "aarch64-darwin";
      modules = [];
    };
  };
}
