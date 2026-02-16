#!/usr/bin/env bash
set -euo pipefail

PROG="git-age-filter"
AGE_DIR=".age"
TMPFILES=()
cleanup() { rm -f "${TMPFILES[@]}"; }
trap cleanup EXIT

mktmp() {
  local f
  f="$(mktemp)"
  TMPFILES+=("$f")
  echo "$f"
}

die() {
  echo "$PROG: $*" >&2
  exit 1
}

repo_root() {
  git rev-parse --show-toplevel 2>/dev/null || die "not a git repository"
}

age_dir() {
  echo "$(repo_root)/$AGE_DIR"
}

recipients_file() {
  echo "$(repo_root)/$AGE_DIR/local-key.pub"
}

identity_file() {
  local root
  root="$(repo_root)"
  if [[ -n ${AGE_IDENTITY:-} && -f $AGE_IDENTITY ]]; then
    echo "$AGE_IDENTITY"
  elif [[ -f "$root/$AGE_DIR/local-key" ]]; then
    echo "$root/$AGE_DIR/local-key"
  else
    die "no identity found: run '$PROG keygen' or set AGE_IDENTITY"
  fi
}

require_identity() {
  identity_file >/dev/null
}

require_recipients() {
  local rf
  rf="$(recipients_file)"
  [[ -f $rf ]] || die "$AGE_DIR/local-key.pub not found (run '$PROG keygen' first)"
}

##: install

cmd_install() {
  local root
  root="$(repo_root)"
  local patterns=("${@:-.secrets/*}")

  # Configure git filter
  git config filter.age.clean "git-age-filter clean %f"
  git config filter.age.smudge "git-age-filter smudge"
  git config filter.age.required true
  git config diff.age.textconv "git-age-filter diff"
  echo "$PROG: configured git filter" >&2

  # Create .age/recipients if missing
  local ad="$root/$AGE_DIR"
  local mrf="$ad/recipients"
  mkdir -p "$ad"
  if [[ ! -f $mrf ]]; then
    cat <<'EOF' >"$mrf"
# age master recipients — one per line
# Public keys of anyone who should be able to decrypt the local key
# (e.g. Yubikey identities, team member keys)
EOF
    echo "$PROG: created $AGE_DIR/recipients (add master public keys)" >&2
  fi

  # Add .gitattributes entries for each pattern
  local ga="$root/.gitattributes"
  local pattern
  for pattern in "${patterns[@]}"; do
    if ! grep -qF "$pattern filter=age" "$ga" 2>/dev/null; then
      echo "$pattern filter=age diff=age merge=age" >>"$ga"
      echo "$PROG: added pattern '$pattern' to .gitattributes" >&2
    fi
  done
}

##: clean — encrypt (stdin plaintext -> stdout ciphertext)

cmd_clean() {
  local filepath="${1:?clean requires filepath argument}"
  local rf
  rf="$(recipients_file)"
  require_recipients

  local tmpinput
  tmpinput="$(mktmp)"

  # Read stdin into tmpfile and compute hash in a single pass
  local new_hash
  new_hash="$(tee "$tmpinput" </dev/stdin | sha256sum | cut -d' ' -f1)"

  # Already encrypted — pass through as-is (e.g. after lock)
  local first_line
  first_line="$(head -1 "$tmpinput")"
  if [[ $first_line == "age-encryption.org"* ]]; then
    cat "$tmpinput"
    return 0
  fi

  # Try to get existing ciphertext from git index and compare hashes
  local tmpindex
  tmpindex="$(mktmp)"
  if git show ":$filepath" >"$tmpindex" 2>/dev/null && [[ -s $tmpindex ]]; then
    local index_header
    index_header="$(head -1 "$tmpindex")"
    if [[ $index_header == "age-encryption.org"* ]]; then
      local id
      id="$(identity_file 2>/dev/null)" || id=""
      if [[ -n $id ]]; then
        local old_hash
        old_hash="$(age -d -i "$id" <"$tmpindex" 2>/dev/null | sha256sum | cut -d' ' -f1)" || old_hash=""

        if [[ -n $old_hash && $new_hash == "$old_hash" ]]; then
          # Plaintext unchanged — reuse existing ciphertext
          cat "$tmpindex"
          return 0
        fi
      fi
    fi
  fi

  # Encrypt the new plaintext
  age -R "$rf" <"$tmpinput"
}

##: smudge — decrypt (stdin ciphertext -> stdout plaintext)

cmd_smudge() {
  local id
  id="$(identity_file)"

  local tmpinput
  tmpinput="$(mktmp)"
  cat >"$tmpinput"

  # If input isn't age-encrypted, pass through unchanged
  local first_line
  first_line="$(head -1 "$tmpinput")"
  if [[ $first_line == "age-encryption.org"* ]]; then
    age -d -i "$id" <"$tmpinput"
  else
    cat "$tmpinput"
  fi
}

##: diff — textconv (file path -> stdout plaintext)

cmd_diff() {
  local filepath="${1:?diff requires filepath argument}"
  local id
  id="$(identity_file)"

  if [[ -f $filepath ]]; then
    local header
    header="$(head -1 "$filepath")"
    if [[ $header == "age-encryption.org"* ]]; then
      age -d -i "$id" <"$filepath"
    else
      cat "$filepath"
    fi
  fi
}

##: age_files — list all tracked files with filter=age

age_files() {
  git ls-files | while IFS= read -r f; do
    local attrs
    attrs="$(git check-attr filter -- "$f" 2>/dev/null)"
    if [[ $attrs == *": filter: age" ]]; then
      echo "$f"
    fi
  done
}

##: unlock — decrypt all filter=age files in working tree

cmd_unlock() {
  local root
  root="$(repo_root)"
  require_identity

  local files
  files="$(age_files)"

  if [[ -z $files ]]; then
    echo "$PROG: no files with filter=age found" >&2
    return 0
  fi

  local count=0
  while IFS= read -r f; do
    rm -f "$root/$f"
    git checkout -- "$f"
    count=$((count + 1))
    echo "$PROG: unlocked $f" >&2
  done <<<"$files"

  echo "$PROG: unlocked $count file(s)" >&2
}

##: lock — replace working tree files with encrypted blobs from index

cmd_lock() {
  local root
  root="$(repo_root)"

  local files
  files="$(age_files)"

  if [[ -z $files ]]; then
    echo "$PROG: no files with filter=age found" >&2
    return 0
  fi

  local count=0
  while IFS= read -r f; do
    local fullpath="$root/$f"
    local tmpblob
    tmpblob="$(mktmp)"
    if git show ":$f" >"$tmpblob" 2>/dev/null && [[ -s $tmpblob ]]; then
      cp "$tmpblob" "$fullpath"
      # Re-add so git updates its stat cache (clean filter passes through ciphertext)
      git add "$f"
      count=$((count + 1))
      echo "$PROG: locked $f" >&2
    else
      echo "$PROG: skipped $f (not in index)" >&2
    fi
  done <<<"$files"

  echo "$PROG: locked $count file(s)" >&2
}

##: keygen — generate a local age keypair for Yubikey-free day-to-day use

cmd_keygen() {
  local root ad mrf
  root="$(repo_root)"
  ad="$root/$AGE_DIR"
  mrf="$ad/recipients"

  [[ -f $mrf ]] || die "$AGE_DIR/recipients not found (run '$PROG install' first)"
  [[ ! -f "$ad/local-key" ]] || die "$AGE_DIR/local-key already exists"
  [[ ! -f "$ad/local-key.age" ]] || die "$AGE_DIR/local-key.age already exists"

  # Generate keypair
  local tmpkey
  tmpkey="$(mktmp)"
  age-keygen -o "$tmpkey" 2>&1

  # Extract public key from comment line
  local pubkey
  pubkey="$(grep '^# public key:' "$tmpkey" | sed 's/^# public key: //')"
  [[ -n $pubkey ]] || die "failed to extract public key from generated key"

  # Save plaintext identity (restricted permissions)
  cp "$tmpkey" "$ad/local-key"
  chmod 600 "$ad/local-key"
  echo "$PROG: created $AGE_DIR/local-key" >&2

  # Save public key
  echo "$pubkey" >"$ad/local-key.pub"
  echo "$PROG: created $AGE_DIR/local-key.pub" >&2

  # Encrypt identity to master recipients (Yubikey + team keys)
  age -R "$mrf" <"$ad/local-key" >"$ad/local-key.age"
  echo "$PROG: created $AGE_DIR/local-key.age" >&2

  # Append .age/local-key to .gitignore if not already present
  local gi="$root/.gitignore"
  if ! grep -qxF "$AGE_DIR/local-key" "$gi" 2>/dev/null; then
    echo "$AGE_DIR/local-key" >>"$gi"
    echo "$PROG: added $AGE_DIR/local-key to .gitignore" >&2
  fi

  echo "" >&2
  echo "Next steps:" >&2
  echo "  git add $AGE_DIR/ .gitignore && git commit -m 'chore: set up git-age-filter'" >&2
}

##: rekey-masters — re-encrypt local key for current master recipients

cmd_rekey_masters() {
  local root ad mrf
  root="$(repo_root)"
  ad="$root/$AGE_DIR"
  mrf="$ad/recipients"

  [[ -f "$ad/local-key" ]] || die "$AGE_DIR/local-key not found (decrypt it first or run '$PROG keygen')"
  [[ -f $mrf ]] || die "$AGE_DIR/recipients not found"

  age -R "$mrf" <"$ad/local-key" >"$ad/local-key.age"
  echo "$PROG: re-encrypted $AGE_DIR/local-key.age for current master recipients" >&2
}

##: main

case "${1:-}" in
install)
  shift
  cmd_install "$@"
  ;;
clean)
  shift
  cmd_clean "$@"
  ;;
smudge)
  shift
  cmd_smudge "$@"
  ;;
diff)
  shift
  cmd_diff "$@"
  ;;
unlock)
  shift
  cmd_unlock "$@"
  ;;
lock)
  shift
  cmd_lock "$@"
  ;;
keygen)
  shift
  cmd_keygen "$@"
  ;;
rekey-masters)
  shift
  cmd_rekey_masters "$@"
  ;;
*)
  echo "Usage: $PROG <command> [args...]" >&2
  echo "" >&2
  echo "Commands:" >&2
  echo "  install [pattern...]  Set up git filter config (default: .secrets/*)" >&2
  echo "  clean <file>          Encrypt filter (used by git)" >&2
  echo "  smudge                Decrypt filter (used by git)" >&2
  echo "  diff <file>           Textconv filter for diffs (used by git)" >&2
  echo "  unlock                Decrypt all filter=age files in working tree" >&2
  echo "  lock                  Restore encrypted blobs from index to working tree" >&2
  echo "  keygen                Generate a local age keypair for Yubikey-free use" >&2
  echo "  rekey-masters         Re-encrypt local key for current master recipients" >&2
  echo "" >&2
  echo "Environment:" >&2
  echo "  AGE_IDENTITY          Path to age identity file (optional override)" >&2
  echo "" >&2
  echo "Files:" >&2
  echo "  .age/recipients       Master public keys (encrypts the local key)" >&2
  echo "  .age/local-key        Local age identity (plaintext, gitignored)" >&2
  echo "  .age/local-key.age    Encrypted copy of local identity (committed)" >&2
  echo "  .age/local-key.pub    Public key of local identity (committed)" >&2
  exit 1
  ;;
esac
