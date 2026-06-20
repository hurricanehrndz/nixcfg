# Nix Configuration

This repository is home to the nix code that builds my systems.

## Why Nix?

Nix allows for easy to manage, collaborative, reproducible deployments. This
means that once something is setup and configured once, it works forever. If
someone else shares their configuration, anyone can make use of it.

This flake is configured with the use of several flake helpers. Have a look at
the inputs for a full comprehensive list.

See [ARCHITECTURE.md](ARCHITECTURE.md) for a detailed explanation of how the
repository is organized.

## Prerequisites

This configuration uses [Lix](https://lix.systems/), a modern, community-driven
Nix implementation with flakes and nix-command experimental features enabled by
default. If you're using standard Nix, you'll need to enable these features
manually or add `--extra-experimental-features "flakes nix-command"` to commands.

## Quick Reference

### Build & Apply

| Action | Darwin (macOS) | NixOS (Linux) |
| --- | --- | --- |
| Build | `nix build '.#darwinConfigurations.<host>.system' --accept-flake-config` | `nix build '.#nixosConfigurations.<host>.system' --accept-flake-config` |
| Apply | `darwin-rebuild switch --flake .#<host>` | `nixos-rebuild switch --flake .#<host>` |
| Build + switch | `just build-switch <host>` | `just build-switch <host>` |

### Development

```console
nix develop          # enter devshell
nix fmt              # format code (nixfmt via treefmt)
nix flake check      # validate flake
just update          # update flake inputs
just gc              # garbage collection
```

## Secrets

Secrets are managed with [agenix](https://github.com/ryantm/agenix) and a
[`git-age-filter`](per-system/pkgs/by-name/git-age-filter/README.md) that keeps
files encrypted at rest. Both the Linux and macOS bootstrap flows reference the
subsections below.

### Decrypt repository secrets (git-age-filter)

Some files in this repo are encrypted at rest with `git-age-filter` and check
out as ciphertext on a fresh clone. The filter is configured per-repo, so
`install` must run first. The `git-age-filter` and `age` tools come from the
devshell, so enter it first. To decrypt (one-time Yubikey touch):

```console
nix develop --impure                       # enter devshell (provides git-age-filter, age)
git-age-filter install                     # configure the per-repo filter
age -d -i "$PRJ_ROOT/identities/age/yubikey-id-5f449e60.txt" "$PRJ_ROOT/.age/local-key.age" > "$PRJ_ROOT/.age/local-key"
chmod 600 "$PRJ_ROOT/.age/local-key"
git-age-filter unlock                      # decrypt the working tree
```

See the [git-age-filter README](per-system/pkgs/by-name/git-age-filter/README.md)
for how the filter works and its day-to-day commands.

### Onboard a new host

A new host needs its SSH public key added to the secrets config so agenix can
rekey secrets for it.

1. **Retrieve the host SSH public key:**
   ```console
   # macOS only: generate the host key first if it doesn't exist
   sudo /usr/libexec/sshd-keygen-wrapper

   cat /etc/ssh/ssh_host_ed25519_key.pub
   ```

2. **Add the host key to secrets configuration:**
   - Edit `secrets/secrets.nix` and add the new host's public key
   - Rekey all secrets:
     ```console
     agenix --rekey
     ```

## Bootstrapping a new Linux system

### Initial Installation

The bootstrap process uses a special flag to disable agenix secrets during the
initial install, since the host SSH keys don't exist yet.

#### Automated Installation with nixos-anywhere

**WARNING:** This will completely erase the target disk and create a new
partition scheme using disko.

1. **Boot the target machine** into a NixOS installer ISO

2. **Ensure SSH access** to the target machine

3. **Deploy with nixos-anywhere:**

   ```console
   nix run github:nix-community/nixos-anywhere -- \
     --flake '.#<hostname>' \
     --override-input bootstrap github:boolean-option/true \
     root@<target-ip>
   ```

   Replace `<hostname>` with your machine name (e.g., DeepThought) and
   `<target-ip>` with the target machine's IP address.

   The command will:
   - Use disko to partition and format the disk according to `disk-config.nix`
   - Install NixOS with the bootstrap flag enabled (secrets disabled)
   - Deploy your system configuration
   - override-input might not work

4. **Restarting a failed nixos-anywhere run:**

   If `nixos-anywhere` does not complete and rerunning fails because the target
   disk is in a partial state, wipe the target disk from the installer shell and
   rerun the deployment:

   ```console
   [root@nixos:~]# umount -R /mnt || true
   [root@nixos:~]# swapoff -a || true
   [root@nixos:~]# wipefs -a /dev/sda
   [root@nixos:~]# sgdisk --zap-all /dev/sda
   [root@nixos:~]# partprobe /dev/sda || true
   ```

   Verify `/dev/sda` is the intended target disk before running these commands.

#### Manual Installation

For manual partitioning and install (kept for historical reference), see
[docs/manual-nixos-install.md](docs/manual-nixos-install.md).

### After First Boot

1. [Onboard the new host](#onboard-a-new-host) — add its SSH key and rekey
   secrets.

2. **Switch to production configuration:**
   ```console
   sudo nixos-rebuild switch --flake .#<hostname>
   ```

   This rebuild uses the default configuration (without the bootstrap flag),
   enabling all secrets.

### Enter chroot after install

```console
sudo nixos-enter
```

## Bootstrapping a new macOS system

### Prerequisites

> **Grant your terminal Full Disk Access first.** The Lix/Nix installer needs
> to write to protected locations (e.g. `/nix`, `/etc`); without it the install
> fails. Add your terminal (Terminal.app, iTerm, Ghostty, etc.) under **System
> Settings → Privacy & Security → Full Disk Access**, then restart the terminal.

1. **Install Lix:**
   ```console
   curl -sSf -L https://install.lix.systems/lix | sh -s -- install
   ```

2. **Install Homebrew:**
   ```console
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

### Initial Installation

1. **Clone this repository and enter the development shell:**
   ```console
   git clone <repository-url>
   cd nixcfg
   nix develop --impure
   ```

   The devshell provides agenix (with yubikey support), darwin-rebuild, and
   other necessary tools.

2. **Decrypt repository secrets:**

   Follow [Decrypt repository secrets (git-age-filter)](#decrypt-repository-secrets-git-age-filter)
   to install the filter and unlock the working tree.

3. [Onboard this host](#onboard-a-new-host) — add its SSH key and rekey secrets.

4. **Add yourself as a trusted Nix user:**

   Edit `/etc/nix/nix.custom.conf` and set `trusted-users` to match the value
   in `flake.nix`:

   ```console
   # adjust according to flake.nix
   trusted-users = root chernand @admin
   ```

5. **Build the Darwin configuration:**
   ```console
   nix build ".#darwinConfigurations.$(hostname).system" --accept-flake-config
   ```

6. **Apply the configuration:**
   ```console
   sudo ./result/sw/bin/darwin-rebuild switch --flake ".#$(hostname)"
   ```

### Subsequent Updates

After the initial setup, use the standard darwin-rebuild command:

```console
darwin-rebuild switch --flake .#<hostname>
```
