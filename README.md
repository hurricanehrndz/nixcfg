# Nix Configuration

This repository is home to the nix code that builds my systems.

## Why Nix?

Nix allows for easy to manage, collaborative, reproducible deployments. This
means that once something is setup and configured once, it works forever. If
someone else shares their configuration, anyone can make use of it.

This flake is configured with the use of several flake helpers. Have a look at
the inputs for a full comprehensive list.

## Prerequisites

This configuration uses [Determinate Nix](https://determinate.systems/nix/), which has flakes and nix-command experimental features enabled by default. If you're using standard Nix, you'll need to enable these features manually or add `--extra-experimental-features "flakes nix-command"` to commands.

## Bootstrapping a new Linux system

### Initial Installation

The bootstrap process uses a special flag to disable agenix secrets during the initial install, since the host SSH keys don't exist yet.

#### Option 1: Automated Installation (Destructive)

**WARNING:** This script will completely erase the target disk and create a new partition scheme.

1. **Run the install script** with your target device and hostname:

   ```console
   nix run --accept-flake-config .\#nixos-install-init /dev/sda Hal9000
   ```

   Note: If not using Determinate Nix, add `--extra-experimental-features "flakes nix-command"` to the command.

   The script will:
   - **Erase all data on the target disk**
   - Create a GPT partition table with BTRFS root, swap, and EFI boot partitions
   - Create BTRFS subvolumes (home, var, nix, tmp, srv, opt, root)
   - Generate hardware configuration
   - Prompt you to run `nixos-install` with the bootstrap flag

#### Option 2: Manual Partitioning

If you prefer a custom partition scheme, follow the [NixOS manual partitioning guide](https://nixos.org/manual/nixos/stable/#sec-installation-manual-partitioning) using the [Determinate Nix installer ISO](https://determinate.systems/posts/determinate-nix-installer/).

After partitioning and mounting your filesystems to `/mnt`:

1. Generate hardware configuration:
   ```console
   nixos-generate-config --root /mnt
   ```

2. Copy the generated `hardware-configuration.nix` to your machine's directory in this repo

3. Continue with step 2 below

#### Completing Installation

2. **Install with bootstrap mode enabled** (as prompted by the script):

   ```console
   sudo nixos-install --root /mnt --no-root-passwd --flake "${HOME}/nixcfg#Hal9000" --override-input bootstrap path:./bootstrap-flags/true
   ```

   The `--override-input bootstrap path:./bootstrap-flags/true` flag disables all agenix secrets during installation.

### After First Boot

1. **Retrieve the host SSH public key:**
   ```console
   cat /etc/ssh/ssh_host_ed25519_key.pub
   ```

2. **Add the host key to secrets configuration:**
   - Edit `secrets/secrets.nix` and add the new host's public key
   - Rekey all secrets:
     ```console
     agenix --rekey
     ```

3. **Switch to production configuration:**
   ```console
   sudo nixos-rebuild switch --flake .#Hal9000
   ```

   This rebuild uses the default configuration (without the bootstrap flag), enabling all secrets.

## Enter chroot after install

```console
sudo nixos-enter
```
