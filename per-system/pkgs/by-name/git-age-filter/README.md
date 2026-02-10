# git-age-filter

Transparent file encryption in git using [age](https://age-encryption.org/) and
[age-plugin-yubikey](https://github.com/str4d/age-plugin-yubikey). Files are
encrypted on `git add` (clean filter) and decrypted on `git checkout` (smudge
filter), so the repo always stores ciphertext while the working tree has
plaintext.

## Setup

```sh
export AGE_IDENTITY=~/.age/yubikey-identity.txt
git-age-filter install          # default pattern: secrets/*
git-age-filter install '*.enc'  # or specify a custom pattern
```

This does three things:

1. Configures the `age` clean/smudge/diff filters in `.git/config`
2. Creates `.age-recipients` if it doesn't exist
3. Appends the pattern to `.gitattributes`

Add recipient public keys (one per line) to `.age-recipients` and commit both
`.age-recipients` and `.gitattributes`.

## Environment

| Variable | Description |
|---|---|
| `AGE_IDENTITY` | Path to an age identity file (required for decrypt). Works with plain age keys, Yubikey identity files, or any age-compatible identity. |

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

## How it works

### Encryption (clean filter)

When `git add` runs the clean filter:

1. If the input is already age-encrypted (e.g. after `lock`), pass it through
   unchanged.
2. Otherwise, hash the new plaintext and compare it against the decrypted
   content from the index. If they match, reuse the existing ciphertext — this
   avoids re-encryption and unnecessary Yubikey touches.
3. If the content changed (or the file is new), encrypt with
   `age -R .age-recipients`.

### Decryption (smudge filter)

When `git checkout` runs the smudge filter, it decrypts with
`age -d -i $AGE_IDENTITY`. Non-encrypted content passes through unchanged.

### lock / unlock

`lock` copies the encrypted blob from the git index into the working tree and
runs `git add` to update the stat cache, so `git status` stays clean. No
encryption or decryption happens — just a file copy.

`unlock` deletes the working tree file and runs `git checkout`, which triggers
the smudge filter to decrypt.

## Repo files

| File | Checked in | Description |
|---|---|---|
| `.age-recipients` | Yes | One age public key per line. Everyone listed can encrypt. |
| `.gitattributes` | Yes | Maps file patterns to the `age` filter. |
