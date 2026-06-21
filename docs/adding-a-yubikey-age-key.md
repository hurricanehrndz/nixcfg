# Adding a new YubiKey age identity

This walks through provisioning a new YubiKey as an
[age](https://age-encryption.org/) identity and wiring its recipient into this
repo, so the new key can decrypt:

1. the **git-age-filter** local key (`.age/local-key.age`), and
2. **agenix** secrets under `secrets/`.

These are two independent recipient lists — adding a key means updating both.

## Prerequisites

Enter the devshell, which provides `age`, `age-plugin-yubikey`, `agenix` (wired
to the YubiKey identity), and `git-age-filter`:

```sh
nix develop --impure
```

You also need the new YubiKey plugged in, and an *existing* trusted identity (a
YubiKey already listed as a recipient, or the decrypted `.age/local-key`) so you
can re-encrypt secrets for the expanded recipient set.

> The PIV applet must be initialized on the YubiKey. A factory-fresh key works
> out of the box; if you have changed the PIV PIN/PUK/management key you will be
> prompted for them during generation.

## 1. Generate the identity on the YubiKey

Generate a new age identity backed by the YubiKey's PIV slot. The private key
material never leaves the hardware — only a plugin stub identity and the public
recipient are exported.

```sh
age-plugin-yubikey --generate \
  --name "age" \
  --touch-policy cached \
  --pin-policy once
```

Match the existing key's policy (`touch: cached`, `pin: once`) unless you have a
reason to differ. The command prints, and the slot now stores:

- a **recipient** line — `age1yubikey1…` (the public key), and
- an **identity** stub — `AGE-PLUGIN-YUBIKEY-1…` (a pointer to the slot, not
  secret key material).

Note the YubiKey serial number and the slot used — they appear in the output and
in the identity file's comment header.

## 2. Save the identity file

Export the identity stub to `identities/age/`, following the existing naming
convention `yubikey-id-<tag>.txt`. The `<tag>` is the short hex tag that
`age-plugin-yubikey --generate` suggests as the default filename
(`age-yubikey-identity-<tag>.txt`) — it is derived from the recipient
(public key), **not** from the serial number, so don't try to compute it from
the serial:

```sh
root="$(git rev-parse --show-toplevel)"
age-plugin-yubikey --identity > "$root/identities/age/yubikey-id-<tag>.txt"
```

This file is safe to commit — it contains only a slot pointer, not the private
key. The header records the serial, slot, and touch/PIN policy for reference.

Grab the recipient (public key) for the next steps:

```sh
age-plugin-yubikey --list                       # all compatible YubiKey keys
# or, for just the connected key:
age-plugin-yubikey --identity \
  -i "$root/identities/age/yubikey-id-<tag>.txt" | age-plugin-yubikey --list
```

## 3. Add the recipient to `.age/recipients`

`.age/recipients` holds the **master** public keys that can recover the
git-age-filter local key. Append the new recipient. Keep the commented metadata
header (device/serial/slot) consistent with the existing entries:

```sh
cat >> "$root/.age/recipients" <<'EOF'

# Device type: YubiKey 5C NFC
# Serial number: <serial>
# Firmware version: <fw>
# Form factor: Keychain (USB-C)
age1yubikey1…
EOF
```

Then re-encrypt the local key so the new YubiKey can recover it. This needs an
already-trusted identity present at `.age/local-key` (or `AGE_IDENTITY`):

```sh
git-age-filter rekey-masters
```

## 4. Add the recipient to agenix (`secrets/secrets.nix`)

agenix tracks its own recipient list, separate from `.age/recipients`. Add the
new key to the `yubikeys` attrset in
[`secrets/secrets.nix`](../secrets/secrets.nix):

```nix
yubikeys = {
  yubikey-5c-5f449e60 = "age1yubikey1q2tegcah05hmykj02tnefl9kggdvudu0x2ehhqkkcar8ermqzfsky94kqzz";
  yubikey-5c-<tag>    = "age1yubikey1…";   # new key
};
```

Because the `yubikeys` set feeds `darwin_Keys`, `deepthoughtKeys`, and the
`home/zsh/env_vars.age` recipient list, every secret that already grants a
YubiKey will pick up the new one. Re-encrypt all secrets for the updated
recipients. agenix resolves recipients from `./secrets.nix`, so run it from the
`secrets/` directory:

```sh
cd "$root/secrets"
agenix --rekey
cd "$root"
```

(`agenix` in the devshell is preconfigured with the existing YubiKey identity
via `--identity identities/age/yubikey-id-5f449e60.txt`, so rekeying will prompt
for a touch on that key.)

## 5. Commit

```sh
git add \
  identities/age/yubikey-id-<tag>.txt \
  .age/recipients .age/local-key.age \
  secrets/secrets.nix secrets/

git commit -m "feat(secrets): add YubiKey <tag> as an age recipient"
```

## Verify

Decrypt something with **only** the new YubiKey to confirm it works end to end.
With just the new key plugged in:

```sh
# git-age-filter local key
age -d -i "$root/identities/age/yubikey-id-<tag>.txt" \
  "$root/.age/local-key.age" >/dev/null && echo "local-key OK"

# an agenix secret (pick any that includes the yubikey recipients)
( cd "$root/secrets" && agenix -d home/zsh/env_vars.age \
    --identity "$root/identities/age/yubikey-id-<tag>.txt" >/dev/null ) \
  && echo "agenix OK"
```

A touch (and PIN, on first use of the session) confirms the new identity is in
play.

## Identify which YubiKey matches which id file

The filename tag (`5f449e60`) is an internal hash of the recipient and is **not**
printed by `age-plugin-yubikey --list` or any `ykman` command — so don't try to
match on it. Match on the **serial** or **recipient** instead; both appear in the
`--list` output *and* in each id file's header.

Name the id file for whatever key is currently plugged in:

```sh
root="$(git rev-parse --show-toplevel)"
grep -rl "$(age-plugin-yubikey --list | grep '^age1yubikey')" \
  "$root"/identities/age/yubikey-id-*.txt
```

Or eyeball the serial:

```sh
age-plugin-yubikey --list | grep Serial          # e.g. Serial: 20497165
grep -l "Serial: 20497165" "$root"/identities/age/yubikey-id-*.txt
```

(`ykman list` also reports connected serials, and `ykman piv info` confirms a key
has an age slot — look for `CN=AGE` under `Slot 82`/`RETIRED1`, which is age
"Slot 1" — but neither shows the age recipient or tag.)

## Recipient files at a glance

| Path | Tracked | Purpose |
|---|---|---|
| `.age/recipients` | Yes | Master keys that can recover the git-age-filter local key. Updated in step 3, then `git-age-filter rekey-masters`. |
| `secrets/secrets.nix` (`yubikeys`) | Yes | agenix recipients for `secrets/**.age`. Updated in step 4, then `agenix --rekey`. |
| `identities/age/yubikey-id-*.txt` | Yes | Per-YubiKey identity stub (slot pointer, not secret). One per key. |
| `identities/age/recipients.txt` | Yes | Reference copy of YubiKey recipient public keys. |

> **Note:** the root-level `.age-recipients` file is an unused, byte-for-byte
> duplicate of `.age/recipients` — no script, module, or config reads it. Prefer
> `.age/recipients`; the stray copy can be removed.

See the [git-age-filter README](../per-system/pkgs/by-name/git-age-filter/README.md)
for how the transparent-encryption filter works day to day.
