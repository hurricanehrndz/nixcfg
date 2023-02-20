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
    inherit homeModules;
    nixosModules.homeManagerSettings = settingsModule;
    darwinModules.homeManagerSettings = settingsModule;
    # homeConfigurations = l.mkBefore (
    #   (mkHomeConfigurations nixosConfigurations)
    #   // (mkHomeConfigurations darwinConfigurations)
    # );
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
          if isDarwin
          then "/Users"
          else "/home";
      in (inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules =
          defaultModules
          ++ [
            (moduleArgs: {
              home.stateVersion = "22.11";
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
        modules = with roles; base;
      };
    in {
      inherit traveller;
    };
  };
}
