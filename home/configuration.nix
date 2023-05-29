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
  ...
}: let
  inherit
    (self)
    inputs
    nixosConfigurations
    darwinConfigurations
    ;
  inherit
    (inputs.digga.lib)
    flattenTree
    mkHomeConfigurations
    rakeLeaves
    ;
  l = inputs.nixpkgs.lib // builtins;

  homeModules = flattenTree (rakeLeaves ./modules);
  profiles = rakeLeaves ./profiles;
  roles = import ./roles {inherit profiles;};

  defaultModules =
    (l.attrValues homeModules)
    ++ roles.base
    ++ [
      (moduleWithSystem (
        {
          inputs',
          packages,
          ...
        }: args: {
          _module.args = {
            inherit
              inputs'
              packages
              ;
          };
        }
      ))
    ];

  platformSpecialArgs = hostPlatform: {
    inherit
      self
      inputs
      profiles
      roles
      ;
    inherit
      (hostPlatform)
      isDarwin
      isLinux
      isMacOS
      system
      ;
  };

  settingsModule = moduleWithSystem ({pkgs, ...}: osArgs: let
    inherit ((osArgs.pkgs or pkgs).stdenv) hostPlatform;
  in {
    home-manager = {
      extraSpecialArgs = platformSpecialArgs hostPlatform;
      sharedModules = defaultModules;
      useGlobalPkgs = true;
      useUserPackages = true;
    };
  });
in {
  flake = {
    # inherit homeModules;
    nixosModules.homeManagerSettings = settingsModule;
    darwinModules.homeManagerSettings = settingsModule;
    homeConfigurations = l.mkBefore (
      # (mkHomeConfigurations nixosConfigurations)
      (mkHomeConfigurations darwinConfigurations)
    );
  };

  perSystem = {
    pkgs,
    inputs',
    system,
    ...
  }: {
    homeConfigurations = let
      makeHomeConfiguration = username: hmArgs: let
        inherit (pkgs.stdenv) hostPlatform;
        inherit (hostPlatform) isDarwin;
        inherit pkgs;
        homePrefix =
          if builtins.hasAttr providedhomePrefix hmArgs.providedhomePrefix
          then "${hmArgs.providedhomePrefix}"
          else if isDarwin
          then "/Users"
          else "/home";
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
                  && (moduleArgs.nixosConfig.hardware.enableRedistributableFirmware -> true);
              };
            })
          ]
          ++ (hmArgs.modules or []);
        extraSpecialArgs = platformSpecialArgs hostPlatform;
      });

      traveller = makeHomeConfiguration "chernand" {
        providedhomePrefix = "/nail/home";
        modules = with roles;
          base
          ++ [
            {
              home.stateVersion = "22.11";
            }
          ];
      };
    in {
      inherit traveller;
    };
  };
}
