{
  self,
  config,
  lib,
  pkgs,
  isBootstrap ? false,
  ...
}:
let
  user = config.system.primaryUser;
  group = if pkgs.stdenv.hostPlatform.isDarwin then "staff" else "users";
in
{
  age.secrets = lib.mkIf (!isBootstrap) (
    {
      "home/zsh/env_vars" = {
        owner = user;
        inherit group;
        file = "${self}/secrets/home/zsh/env_vars.age";
        # Decrypt to the default agenix runtime dir (/run/agenix/...). Do NOT
        # symlink into ~/.config/zsh: that dir is home-manager's zsh dotDir, and
        # agenix (running as root) would create it root-owned, breaking
        # home-manager's later `mkdir ~/.config/zsh/plugins` for user plugins.
      };
    }
    // lib.optionalAttrs config.hrndz.tooling.ai.enable {
      "home/agent-notifications/config.toml" = {
        owner = user;
        inherit group;
        file = "${self}/secrets/home/agent-notifications/config.toml.age";
      };
    }
  );
}
