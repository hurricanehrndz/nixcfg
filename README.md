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

#### Automated Installation with nixos-anywhere

**WARNING:** This will completely erase the target disk and create a new partition scheme using disko.

1. **Boot the target machine** into a NixOS installer ISO (recommend [Determinate Nix installer ISO](https://determinate.systems/posts/determinate-nix-installer/))

2. **Ensure SSH access** to the target machine

3. **Deploy with nixos-anywhere:**

   ```console
   nixos-anywhere --flake .#<hostname> --override-input bootstrap path:./bootstrap-flags/true root@<target-ip>
   ```

   Replace `<hostname>` with your machine name (e.g., DeepThought) and `<target-ip>` with the target machine's IP address.

   The command will:
   - Use disko to partition and format the disk according to `disk-config.nix`
   - Install NixOS with the bootstrap flag enabled (secrets disabled)
   - Deploy your system configuration

#### Manual Installation

If you prefer manual control, follow the [NixOS manual partitioning guide](https://nixos.org/manual/nixos/stable/#sec-installation-manual-partitioning).

After partitioning and mounting your filesystems to `/mnt`:

1. Generate hardware configuration:
   ```console
   nixos-generate-config --root /mnt
   ```

2. Copy the generated `hardware-configuration.nix` to your machine's directory in this repo

3. Install with bootstrap mode enabled:

   ```console
   sudo nixos-install --root /mnt --no-root-passwd --flake .#<hostname> --override-input bootstrap path:./bootstrap-flags/true
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
