{
  self,
  lib,
  osConfig,
  ...
}:
let
  inherit (osConfig.networking) hostName;
  hub = "DeepThought";

  # Devices sync only with the hub. Discovery and relays are off, so the hub's
  # addresses are listed: LAN first, then Tailscale for when away from home.
  devices = {
    DeepThought = {
      id = "5C3QJNI-G5ASDY7-BFKW2EY-A52GXQN-SAEISAQ-P6RNPIG-5XZNYKX-NNONDAI";
      addresses = [
        "tcp://172.24.224.15:22000"
        "tcp://deepthought.long-bee.ts.net:22000"
      ];
    };
    muthur.id = "QTIVQ3Q-H3PPVYG-PPJMBGX-OJ6GE6A-BKXEJVO-J6RJPJH-ZG4BTR7-GQ4IYA2";
    LH9KCR6DJX.id = "JAKDKYR-KKKU3YG-CUZOS3O-MSVRUXD-ISY36EP-EFR7D46-ORDKZ6C-5RDUYQZ";
    mastercontrol.id = "QXO7FGO-PNAXSDL-MSVDSTR-W3G2XGH-2YGYL7V-B3PZCJ6-ONX77VJ-AWYJEQH";
  };
  peers = if hostName == hub then lib.attrNames (removeAttrs devices [ hub ]) else [ hub ];
in
{
  # The device key is absent in bootstrap mode, so Syncthing stays off with it.
  config = lib.mkIf (osConfig.age.secrets ? syncthing-key) {
    services.syncthing = {
      enable = true;
      cert = "${self}/secrets/services/syncthing/${hostName}/cert.pem";
      key = osConfig.age.secrets.syncthing-key.path;
      settings = {
        options = {
          globalAnnounceEnabled = false;
          localAnnounceEnabled = false;
          relaysEnabled = false;
          natEnabled = false;
          urAccepted = -1;
        };
        devices = lib.getAttrs peers devices;
        folders.personal = {
          path = lib.mkDefault "~/vaults/personal";
          devices = peers;
        };
      };
    };

    # Obsidian rewrites its pane layout constantly, and Lean Terminal saves
    # every session's scrollback; syncing either only breeds conflict copies.
    home.file."vaults/personal/.stignore" = lib.mkIf (hostName != hub) {
      text = ''
        .obsidian/workspace.json
        .obsidian/workspace-mobile.json
        .obsidian/plugins/lean-terminal/data.json
      '';
    };
  };
}
