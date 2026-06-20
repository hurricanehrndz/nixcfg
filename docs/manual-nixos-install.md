# Manual NixOS Installation

> Kept for historical reference. The preferred path is the automated
> [nixos-anywhere flow](../README.md#automated-installation-with-nixos-anywhere).

If you prefer manual control, follow the
[NixOS manual partitioning guide](https://nixos.org/manual/nixos/stable/#sec-installation-manual-partitioning).

After partitioning and mounting your filesystems to `/mnt`:

1. Generate hardware configuration:
   ```console
   nixos-generate-config --root /mnt
   ```

2. Copy the generated `hardware-configuration.nix` to your machine's directory
   in this repo.

3. Install with bootstrap mode enabled:
   ```console
   sudo nixos-install --root /mnt --no-root-passwd \
     --flake .#<hostname> \
     --override-input bootstrap github:boolean-option/true
   ```

   The bootstrap flag disables agenix secrets during the initial install, since
   the host SSH keys don't exist yet.

## Enter chroot after install

Unlike the automated nixos-anywhere flow (which reboots into the installed
system automatically), a manual install drops you back in the installer. To
inspect or fix the freshly installed system before rebooting, chroot into it:

```console
sudo nixos-enter
```

## After first boot

Once the system boots, onboard it to secrets and switch to the production
configuration — see [Secrets](../README.md#secrets) in the main README:

1. [Onboard the new host](../README.md#onboard-a-new-host) (add its SSH key and
   rekey).

2. Switch to the production configuration (without the bootstrap flag, enabling
   all secrets):
   ```console
   sudo nixos-rebuild switch --flake .#<hostname>
   ```
