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
  flake-parts-lib,
  ...
}: let
  inherit
    (lib)
    mapAttrs
    mkOption
    optionalAttrs
    types
    ;
  inherit
    (flake-parts-lib)
    mkSubmoduleOptions
    mkPerSystemOption
    ;
in {
  options = {
    flake = mkSubmoduleOptions {
      homeConfigurations = mkOption {
        type = types.lazyAttrsOf (types.lazyAttrsOf types.raw);
        default = {};
        description = ''
          Per system an attribute set of standalone home-manager configurations.
          <literal>nix build .#&lt;name></literal> will build <literal>homeConfigurations.&lt;system>.&lt;name></literal>.
        '';
      };
    };

    perSystem = mkPerSystemOption (_: {
      _file = ./homeConfigurations.nix;
      options = {
        homeConfigurations = mkOption {
          type = types.lazyAttrsOf types.raw;
          default = {};
          description = ''
            An attribute set of standalone home-manager configurations to be built by <literal>nix build .#&lt;name></literal>.
            <literal>nix build .#&lt;name></literal> will build <literal>homeConfigurations.&lt;name></literal>.
          '';
        };
      };
    });
  };
  config = {
    flake.homeConfigurations =
      mapAttrs
      (_k: v: v.homeConfigurations or {})
      config.allSystems;

    perInput = system: flake:
      optionalAttrs (flake ? homeConfigurations.${system}) {
        homeConfigurations = flake.homeConfigurations.${system};
      };
  };
}
