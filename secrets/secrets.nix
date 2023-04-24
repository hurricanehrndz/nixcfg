let
  # set ssh public keys here for your system and user
  machineKeys = {
    lucy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINF+1D/p54Xvp1lOrbl84UvY4VNtncU7SHCBdwXBCg2F";
    deepthought = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE9OP9bpbUbe4TWX9zRs2Yg4t3VY2Ef8GkohWvO6m/Aw";
    VPXK04PX7G = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHX3wEseTg/3ha2mvdx/rBGj/UyjLK30pDFxmwDOjFGH";
  };
  userKeys = {
    hurricane = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPFyXsPXbWMk433W+o+VwH7PasFbReJAEjHxcgUKhJ4P";
  };
  lucyKeys = [
    machineKeys.lucy
    userKeys.hurricane
  ];
  deepKeys = [
    machineKeys.deepthought
    userKeys.hurricane
  ];
  VPXK04PX7G_Keys= [
    machineKeys.VPXK04PX7G
    userKeys.hurricane
  ];
in
{
  "darwin/env/zsh_vars.age".publicKeys = VPXK04PX7G_Keys;
  "darwin/aws/sso_config.age".publicKeys = VPXK04PX7G_Keys;
  "darwin/aws/auth_config.age".publicKeys = VPXK04PX7G_Keys;

  "services/snapraid-runner/apprise.yaml.age".publicKeys = deepKeys;
  "services/traefik/env.age".publicKeys = deepKeys;
}
