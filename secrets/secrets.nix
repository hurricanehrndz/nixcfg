let
  # set ssh public keys here for your system and user
  machineKeys = {
    lucy = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINF+1D/p54Xvp1lOrbl84UvY4VNtncU7SHCBdwXBCg2F";
    deepthought = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE9OP9bpbUbe4TWX9zRs2Yg4t3VY2Ef8GkohWvO6m/Aw";
    LH9KCR6DJX = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDZGnhXNa4z8Ty4NtnR56yz6kuoCBcBgFNCg3EbnMEIY";
    HX7YG952H5 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJx4/mWsYx2CEjDrffAW0UqlFzkG7Kz7NIIb28KSrHxd";
    hal9000 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPfL9zUyDVULTUhNZzlEi8z7nHguRBzIkxzJbxUeDupg";
  };
  userKeys = {
    hurricane = "age1vagysxgt3udd2ctpvpcn7sm04dg382tvzmn9ss83v9apg450pu4skplnde";
  };
  deepKeys = [
    machineKeys.deepthought
    userKeys.hurricane
  ];
  darwin_Keys = [
    machineKeys.LH9KCR6DJX
    machineKeys.HX7YG952H5
    userKeys.hurricane
  ];
in {
  "darwin/env/zsh_vars.age".publicKeys = darwin_Keys;
  "darwin/aws/auth_config.age".publicKeys = darwin_Keys;
  "darwin/mods/conf.yml.age".publicKeys = darwin_Keys;

  "services/snapraid-runner/apprise.yaml.age".publicKeys = deepKeys;
  "services/traefik/env.age".publicKeys = deepKeys ++ [machineKeys.hal9000];
  "services/homarr/env.age".publicKeys = deepKeys;
}
