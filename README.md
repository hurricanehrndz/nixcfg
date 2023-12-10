# Nix Configuration

This repository is home to the nix code that builds my systems.

## Why Nix?

Nix allows for easy to manage, collaborative, reproducible deployments. This
means that once something is setup and configured once, it works forever. If
someone else shares their configuration, anyone can make use of it.

This flake is configured with the use of several flake helpers. Have a look at
the inputs for a full comprehensive list.

## Bootstrapping a new Linux system

Within the default development shell, run, modifying the arguments to specific
device.

```console
sudo nix run --accept-flake-config github:hurricanehrndz/nixcfg\#nixos-install-init /dev/sda Lucy

```

All agenix secrets should be commented out. Once the new OS is booted, update
the secrets configuration with host's new ssh public key and rekey the secrets.

## Setting up secrets before first boot

This method is not recommend, but it is here for documentation and reference
purposes.

Copy user private id_ed25519 age key to bootstrap instance, place in the usual
place `/home/hurricane/.ssh`.

```console
sudo nixos-enter
ssh_keygen=$(systemctl cat sshd | awk -F'=' '/sshd-pre-start/{print $2}')
$ssh_keygen
exit
```

Update secrets.nix with the new pub key of the host, rekey, and rerun install

```console
export PRIVATE_KEY=/home/hurricane/.ssh/id_25519
agenix --rekey
sudo nixos-install --root /mnt --no-root-passwd --flake "/mnt/etc/nixos#$FLAKE_HOST"
```

## Enter chroot after install

```console
sudo nixos-enter
```
