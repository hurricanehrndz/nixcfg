# git-age-filter

Transparent file encryption in git using [age](https://age-encryption.org/) and
[age-plugin-yubikey](https://github.com/str4d/age-plugin-yubikey). Files are
encrypted on `git add` (clean filter) and decrypted on `git checkout` (smudge
filter), so the repo always stores ciphertext while the working tree has
plaintext.

## Setup

```sh
git-age-filter install          # default pattern: .secrets/*
git-age-filter install '*.enc'  # or specify a custom pattern
```

This does three things:

1. Configures the `age` clean/smudge/diff filters in `.git/config`
2. Creates `.age/recipients` if it doesn't exist
3. Appends the pattern to `.gitattributes`

Next, add master recipient public keys (one per line) to `.age/recipients` —
these are keys that can recover the local key (e.g. Yubikey identities, team
member keys). Then generate the local keypair:

```sh
git-age-filter keygen
git add .age/ .gitattributes .gitignore
git commit -m 'chore: set up git-age-filter'
```

## Environment

| Variable | Description |
|---|---|
| `AGE_IDENTITY` | Optional override. Path to an age identity file. When set, used instead of auto-discovered `.age/local-key`. |

## Commands

### Filter commands (called by git)

| Command | Description |
|---|---|
| `clean <file>` | Encrypts plaintext from stdin. Used by `git add`. |
| `smudge` | Decrypts ciphertext from stdin. Used by `git checkout`. |
| `diff <file>` | Textconv filter — outputs plaintext for `git diff`. |

### User commands

| Command | Description |
|---|---|
| `install [pattern]` | Set up the filter in the current repo. |
| `lock` | Replace working tree files with their encrypted form from the index. Leaves `git status` clean. |
| `unlock` | Decrypt all filtered files in the working tree via `git checkout`. |
| `keygen` | Generate a local age keypair for Yubikey-free day-to-day use. |
| `rekey-masters` | Re-encrypt `.age/local-key.age` for the current `.age/recipients`. |

## How it works

### Encryption (clean filter)

When `git add` runs the clean filter:

1. If the input is already age-encrypted (e.g. after `lock`), pass it through
   unchanged.
2. Otherwise, hash the new plaintext and compare it against the decrypted
   content from the index. If they match, reuse the existing ciphertext — this
   avoids re-encryption and keeps diffs stable.
3. If the content changed (or the file is new), encrypt with
   `age -R .age/local-key.pub`.

### Decryption (smudge filter)

When `git checkout` runs the smudge filter, it decrypts with the auto-discovered
identity (`.age/local-key`, or `AGE_IDENTITY` if set). Non-encrypted content
passes through unchanged.

### lock / unlock

`lock` copies the encrypted blob from the git index into the working tree and
runs `git add` to update the stat cache, so `git status` stays clean. No
encryption or decryption happens — just a file copy.

`unlock` deletes the working tree file and runs `git checkout`, which triggers
the smudge filter to decrypt.

### keygen / rekey-masters

`keygen` generates a local age keypair so day-to-day operations (clean, smudge,
diff, unlock) work without a Yubikey touch. It creates four files under `.age/`:

- `local-key` — plaintext identity (gitignored, chmod 600)
- `local-key.pub` — public key (used as the recipient for the clean filter)
- `local-key.age` — identity encrypted to `.age/recipients` (master keys)

The plaintext key never leaves the machine. The encrypted copy lets you recover
on another machine with a single Yubikey touch.

`rekey-masters` re-encrypts `.age/local-key.age` using the current
`.age/recipients`. Run it after adding a new team member or master key:

```sh
echo "age1xxxteammate..." >> .age/recipients
git-age-filter rekey-masters
git add .age/ && git commit -m 'chore: add teammate to master recipients'
```

Bootstrap on a new machine (one-time Yubikey touch):

```sh
age -d -i ~/.age/yubikey-identity.txt .age/local-key.age > .age/local-key
chmod 600 .age/local-key
git-age-filter unlock
```

## Repo files

| File | Checked in | Description |
|---|---|---|
| `.age/recipients` | Yes | Master public keys (Yubikey, team members). Used to encrypt the local key. |
| `.age/local-key` | No | Local age identity (plaintext, gitignored). |
| `.age/local-key.age` | Yes | Encrypted copy of the local identity. |
| `.age/local-key.pub` | Yes | Public key of the local identity. Used by the clean filter. |
| `.gitattributes` | Yes | Maps file patterns to the `age` filter. |
