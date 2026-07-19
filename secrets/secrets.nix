let
  # set ssh public keys here for your system and user
  machineKeys = {
    Lucy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKkRFf/Ko2VicwQFmGxLfBMcNyNiKPV2RGPy3Kx4qMn";
    DeepThought = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFGfyxfjRIvGOAC70fSG6Xe6DTZkvzhYa+iqeG9Fp7ff";
    LH9KCR6DJX = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDZGnhXNa4z8Ty4NtnR56yz6kuoCBcBgFNCg3EbnMEIY";
    HX7YG952H5 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAcp1c7b48MG7QwMIt7Sgv32JajcbdPG/f/f4+1AH7CB";
    HHY314TN61 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIBVjEb2tV4daRlqt2lXspKqXFav2Prg1IVSZA71A3qY";
    hal = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOWYoQyoNQ4dFZfPIyzZ/bRDnUo/dSQFu+gxr626kHua";
  };
  yubikeys = {
    yubikey-5cNFC-20497165 = "age1yubikey1q2tegcah05hmykj02tnefl9kggdvudu0x2ehhqkkcar8ermqzfsky94kqzz";
    yubikey-5cNFC-20497186 = "age1yubikey1qtl8vgsdswdzxkksnr088ezlgj8vu7t632a4x8fckgzs7yxkufrk676gs7r";
    yubikey-5NFC-10327455 = "age1yubikey1q0v4s9zc0c7jtkqmfkhfmmyay00typ05rz3wvak5uw7gjejz944xsjf8uys";
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

  # added 2026-07-19 + 30 day expiration
  "services/tailscale/auth.age".publicKeys = deepthoughtKeys ++ [ machineKeys.Lucy machineKeys.hal];

  # Scrutiny Telegram notification URL (Shoutrrr). Notifier runs on the
  # DeepThought scrutiny web instance, so only DeepThought needs to decrypt it.
  "services/scrutiny/notify-url.age".publicKeys = deepthoughtKeys;
}
