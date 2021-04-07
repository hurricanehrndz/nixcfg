{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.hurricane.configs.zplugins;
  pluginsDir = ".config/zsh/plugins" ;
  pluginModule = types.submodule ({ config, ... }: {
    options = {
      src = mkOption {
        type = types.path;
        description = ''
          Path to the plugin folder.
          Will be added to <envar>fpath</envar> and <envar>PATH</envar>.
        '';
      };

      name = mkOption {
        type = types.str;
        description = ''
          The name of the plugin.
          Don't forget to add <option>file</option>
          if the script name does not follow convention.
        '';
      };

      file = mkOption {
        type = types.str;
        description = "The plugin script to source.";
      };

      apply = mkOption {
        type = types.str;
        default = "";
        description = "Apply a string before source.";
      };

    };

    config.file = mkDefault "${config.name}.plugin.zsh";
  });
in
{
  options.hurricane.configs = {
    zplugins.enable = mkEnableOption "my zsh plugins";

    zplugins.plugins = mkOption {
      type = types.listOf pluginModule;
      default = [];
      example = literalExample ''
        [
          {
            # will source zsh-autosuggestions.plugin.zsh
            name = "zsh-autosuggestions";
            src = pkgs.fetchFromGitHub {
              owner = "zsh-users";
              repo = "zsh-autosuggestions";
              rev = "v0.4.0";
              sha256 = "0z6i9wjjklb4lvr7zjhbphibsyx51psv50gm07mbb0kj9058j6kc";
            };
          }
          {
            name = "enhancd";
            file = "init.sh";
            src = pkgs.fetchFromGitHub {
              owner = "b4b4r07";
              repo = "enhancd";
              rev = "v2.2.1";
              sha256 = "0iqa9j09fwm6nj5rpip87x3hnvbbz9w9ajgm6wkrd5fls8fn8i5g";
            };
          }
        ]
      '';
      description = "Plugins to source in <filename>.zshrc</filename>.";
    };
  };
  config = mkIf cfg.enable (mkMerge [
    {
      programs.zsh.initExtra = ''
        ${concatStrings (map (plugin: ''
          path+="$HOME/${pluginsDir}/${plugin.name}"
          fpath+="$HOME/${pluginsDir}/${plugin.name}"
        '') cfg.plugins)}

        ${concatStrings (map (plugin: ''
          ${if plugin.apply != "" then "${plugin.apply} " else ""}source "$HOME/${pluginsDir}/${plugin.name}/${plugin.file}"
        '') cfg.plugins)}

        source "${pkgs.grc}/etc/grc.zsh"
      '';
      home.packages = with pkgs; [
        # colorizer
        grc
      ];
    }
    (mkIf (cfg.plugins != []) {
      home.file =
        foldl' (a: b: a // b) {}
        (map (plugin: { "${pluginsDir}/${plugin.name}".source = plugin.src; })
        cfg.plugins);
    })

  ]);
}
