let
  # set ssh public keys here for your system and user
  machineKeys = {
    Lucy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINF+1D/p54Xvp1lOrbl84UvY4VNtncU7SHCBdwXBCg2F";
    DeepThought = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFGfyxfjRIvGOAC70fSG6Xe6DTZkvzhYa+iqeG9Fp7ff";
    LH9KCR6DJX = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDZGnhXNa4z8Ty4NtnR56yz6kuoCBcBgFNCg3EbnMEIY";
    HX7YG952H5 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAcp1c7b48MG7QwMIt7Sgv32JajcbdPG/f/f4+1AH7CB";
    hal = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOWYoQyoNQ4dFZfPIyzZ/bRDnUo/dSQFu+gxr626kHua";
  };
  yubikeys = {
    yubikey-5c-5f449e60 = "age1yubikey1q2tegcah05hmykj02tnefl9kggdvudu0x2ehhqkkcar8ermqzfsky94kqzz";
  };
  deepthoughtKeys = [
    machineKeys.DeepThought
  ]
  ++ (builtins.attrValues yubikeys);
  darwin_Keys = [
    machineKeys.LH9KCR6DJX
    machineKeys.HX7YG952H5
  ]
  ++ (builtins.attrValues yubikeys);
in
{
  "darwin/aws/auth_config.age".publicKeys = darwin_Keys;

  "home/zsh/env_vars.age".publicKeys = (builtins.attrValues machineKeys) ++ (builtins.attrValues yubikeys);

  "services/snapraid-runner/apprise.yaml.age".publicKeys = deepthoughtKeys;
  "services/ingress/env.age".publicKeys = deepthoughtKeys ++ [ machineKeys.hal ];
  "services/homarr/env.age".publicKeys = deepthoughtKeys;
  "services/media-app-stack/skey.age".publicKeys = deepthoughtKeys;
  "services/media-app-stack/rkey.age".publicKeys = deepthoughtKeys;
  "services/searxng/env.age".publicKeys = deepthoughtKeys;

  # Scrutiny Telegram notification URL (Shoutrrr). Notifier runs on the
  # DeepThought scrutiny web instance, so only DeepThought needs to decrypt it.
  "services/scrutiny/notify-url.age".publicKeys = deepthoughtKeys;
}
