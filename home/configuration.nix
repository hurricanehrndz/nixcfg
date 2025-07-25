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
  moduleWithSystem,
  pkgs,
  ...
}: let
  inherit (self) inputs;
  inherit (inputs) haumea;
  l = inputs.nixpkgs.lib // builtins // self.lib;

  homeModules = l.rakeLeaves ./modules;
  profiles = l.rakeLeaves ./profiles;
  roles = import ./roles {inherit profiles;};

  defaultModules =
    (l.recAttrValues homeModules)
    ++ roles.base
    ++ [
      # inputs.flatpaks.homeManagerModules.default
      (moduleWithSystem ({
        inputs',
        packages,
        ...
      }: args: {
        _module.args = {inherit inputs' packages;};
      }))
    ];

  extraSpecialArgs = {inherit self inputs profiles roles;};

  settingsModule.home-manager = {
    inherit extraSpecialArgs;
    sharedModules = defaultModules;
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "bak";
  };
in {
  flake = {
    #
    # make roles and poriles available to nixos configs and darwin configs
    #

    homeModules.homeManagerSettings = settingsModule;
  };

  perSystem = {
    pkgs,
    inputs',
    system,
    ...
  }: let
    makeHomeConfiguration = username: hmArgs: let
      homePrefix = hmArgs.providedhomePrefix or (l.homePrefix system);
    in (inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules =
        defaultModules
        ++ [
          (moduleArgs: {
            home.username = username;
            home.homeDirectory = "${homePrefix}/${username}";
            _module.args = {
              inherit inputs';
              isNixos =
                (moduleArgs.nixosConfig ? hardware)
                # We only care if the option exists -- its value doesn't matter.
                && (moduleArgs.nixosConfig.hardware.enableRedistributableFirmware
                  -> true);
            };
          })
        ]
        ++ (hmArgs.modules or []);
      inherit extraSpecialArgs;
    });
  in {
    homeConfigurations = {
      traveller = makeHomeConfiguration "chernand" {
        providedhomePrefix = "/nail/home";
        modules = with roles; remote ++ [{home.stateVersion = "22.11";}];
      };
    };
  };
}
