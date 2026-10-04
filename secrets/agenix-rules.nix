let
  # set ssh public keys here for your system and user
  machineKeys = {
    Lucy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKkRFf/Ko2VicwQFmGxLfBMcNyNiKPV2RGPy3Kx4qMn";
    DeepThought = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFGfyxfjRIvGOAC70fSG6Xe6DTZkvzhYa+iqeG9Fp7ff";
    LH9KCR6DJX = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDZGnhXNa4z8Ty4NtnR56yz6kuoCBcBgFNCg3EbnMEIY";
    HX7YG952H5 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAcp1c7b48MG7QwMIt7Sgv32JajcbdPG/f/f4+1AH7CB";
    HHY314TN61 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIBVjEb2tV4daRlqt2lXspKqXFav2Prg1IVSZA71A3qY";
    hal = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOWYoQyoNQ4dFZfPIyzZ/bRDnUo/dSQFu+gxr626kHua";
    mastercontrol = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICHjbHviKroSd7V8Vz31UJr+eBSPYy5C2BGbUxjQKY0f";
    muthur = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINDOG7UKi459w67vwfpmmljkZq0wiQRkOQ7SFIsIGpIH";
  };
  yubikeys = {
    yubikey-5cNFC-20497165 = "age1yubikey1q2tegcah05hmykj02tnefl9kggdvudu0x2ehhqkkcar8ermqzfsky94kqzz";
    # yubikey-5cNFC-20497186 + yubikey-5NFC-10327455 pub key
    yubikey-shared = "age1yubikey1qvwg4wvk0ealn3xexe6qg54c4xf00cvk0eam8t0nwg6fhf2zk4vq2lf9z34";
  };
  deepthoughtKeys = [
    machineKeys.DeepThought
  ]
  ++ (builtins.attrValues yubikeys);
  darwin_Keys = [
    machineKeys.LH9KCR6DJX
    machineKeys.HX7YG952H5
    machineKeys.HHY314TN61
  ]
  ++ (builtins.attrValues yubikeys);
in
{
  "darwin/aws/auth_config.age".publicKeys = darwin_Keys;

  "home/zsh/env_vars.age".publicKeys =
    (builtins.attrValues machineKeys) ++ (builtins.attrValues yubikeys);

  "home/agent-notifications/config.toml.age".publicKeys =
    (builtins.attrValues machineKeys) ++ (builtins.attrValues yubikeys);

  "services/snapraid-runner/apprise.yaml.age".publicKeys = deepthoughtKeys;
  "services/ingress/env.age".publicKeys = deepthoughtKeys ++ [ machineKeys.hal ];
  "services/homarr/env.age".publicKeys = deepthoughtKeys;
  "services/media-app-stack/skey.age".publicKeys = deepthoughtKeys;
  "services/media-app-stack/rkey.age".publicKeys = deepthoughtKeys;
  "services/searxng/env.age".publicKeys = deepthoughtKeys;

  # Syncthing device keys. The matching cert.pem files are public and sit next
  # to these unencrypted; together they fix each host's device ID.
  "services/syncthing/DeepThought/key.pem.age".publicKeys = deepthoughtKeys;
  "services/syncthing/DeepThought/gui-password.age".publicKeys = deepthoughtKeys;
  "services/syncthing/muthur/key.pem.age".publicKeys = [
    machineKeys.muthur
  ]
  ++ (builtins.attrValues yubikeys);
  "services/syncthing/LH9KCR6DJX/key.pem.age".publicKeys = [
    machineKeys.LH9KCR6DJX
  ]
  ++ (builtins.attrValues yubikeys);

  # added 2026-07-19 + 30 day expiration
  "services/tailscale/auth.age".publicKeys = deepthoughtKeys ++ [
    machineKeys.Lucy
    machineKeys.hal
    machineKeys.mastercontrol
  ];

  # Scrutiny Telegram notification URL (Shoutrrr). Notifier runs on the
  # DeepThought scrutiny web instance, so only DeepThought needs to decrypt it.
  "services/scrutiny/notify-url.age".publicKeys = deepthoughtKeys;
}
