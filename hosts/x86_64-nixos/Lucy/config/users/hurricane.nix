{ pkgs, ... }:
let
  username = "hurricane";
in
{
  users.users."${username}" = {
    description = "Carlos Hernandez";
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "input"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDMa/rzAQl4OIi9NT8QAsWfAg4tdnZCHbDHBtw9RJbUVVXYdzBfivttwq+3YNL0j2EPNqg9cBn0Oa37btTMNqQJJLhnIi03dBNILWrIEtpTLjTSayjSz+1oU7Ksv8vin5dSqeipRd/D0LXTH8liEr2YnDqYhrHQrtWE/o3fKzE4kqEUfafF/pksobe1NkyztajC+kVG5o8QmFKJRJY7saCpgNzCn4PmWs3/Qqjf/off0EL3yst1S9YAQKyk/SlznDPkypGiNiFc2dKvI1oUNgRsmY43zkO3ap7ZxFtAY//sNXuw+htTexmxNZG9Uca6SnKBKvo9nQJ1JqVfqBgkQPSqGB0GAnS1tj3GpXoNpk8paSm4TvlgzRRY884ipBxj9pbB+nwYElgoxT1/B1uJ4hY0jywE11+Mt915D9d8LBmT/2THR73Czw2QPEtYdXwjhhB2OVyrPMhExXtEsdJjZ3iFieatx7QnW+/6x9aUA4wRbEhnUYgxRE8Ybudtuz+bnLzzTaxIdaoip4qK2AzIifXm5ByjYlGnEwmGKj/k7A0VW/iToew9lESLNypRsbwgxeykix0BwkL8UCoWUhtmRxyxGxfV6yAVdRyWnXIgTaOPzXOU8l6vzPigI/GFTnE74llCXJT0GVsb/Tl5b2WRl9pgSkPHHBW3XFJx7MRyQTNDrQ=="
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIOfSTexDlSXywRhG/jkTWqpC4Irth8sW1SLbc0MD2EH"
    ];
    shell = pkgs.zsh;
    hashedPassword = "$6$Fxu/FWVSUIJozHug$qjfA65Jk8nuKvikY11bAlk6TaN6akgNoZVmjZqaW8uWA/nsjjSfoarZ.RsIu/Bo8707R2aPpuWi1Y/Q2fqPzu1";
  };

  security.sudo.extraRules = [
    {
      users = [ username ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  hrndz = {
    roles.guiDeveloper.enable = true;
    tooling.ai.enable = true;
  };
}
