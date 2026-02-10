#!/usr/bin/env bash
set -euo pipefail

PROG="git-age-filter"
RECIPIENTS_FILE=".age-recipients"
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

recipients_file() {
  local root
  root="$(repo_root)"
  echo "$root/$RECIPIENTS_FILE"
}

require_identity() {
  [[ -n "${AGE_IDENTITY:-}" ]] || die "AGE_IDENTITY env var not set (path to age identity file)"
  [[ -f "$AGE_IDENTITY" ]] || die "AGE_IDENTITY file not found: $AGE_IDENTITY"
}

require_recipients() {
  local rf
  rf="$(recipients_file)"
  [[ -f "$rf" ]] || die "$RECIPIENTS_FILE not found in repo root"
}

##: install

cmd_install() {
  local root rf
  root="$(repo_root)"
  local patterns=("${@:-.secrets/*}")

  # Configure git filter
  git config filter.age.clean "git-age-filter clean %f"
  git config filter.age.smudge "git-age-filter smudge"
  git config filter.age.required true
  git config diff.age.textconv "git-age-filter diff"
  echo "$PROG: configured git filter" >&2

  # Create .age-recipients if missing
  rf="$root/$RECIPIENTS_FILE"
  if [[ ! -f "$rf" ]]; then
    cat <<'EOF' >"$rf"
# age recipients — one per line
# Public keys of anyone who should be able to decrypt
EOF
    echo "$PROG: created $RECIPIENTS_FILE (add recipient public keys)" >&2
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
  new_hash="$(tee "$tmpinput" < /dev/stdin | sha256sum | cut -d' ' -f1)"

  # Already encrypted — pass through as-is (e.g. after lock)
  local first_line
  first_line="$(head -1 "$tmpinput")"
  if [[ "$first_line" == "age-encryption.org"* ]]; then
    cat "$tmpinput"
    return 0
  fi

  # Try to get existing ciphertext from git index and compare hashes
  local tmpindex
  tmpindex="$(mktmp)"
  if git show ":$filepath" > "$tmpindex" 2>/dev/null && [[ -s "$tmpindex" ]]; then
    local index_header
    index_header="$(head -1 "$tmpindex")"
    if [[ "$index_header" == "age-encryption.org"* ]]; then
      require_identity
      local old_hash
      old_hash="$(age -d -i "$AGE_IDENTITY" < "$tmpindex" 2>/dev/null | sha256sum | cut -d' ' -f1)" || old_hash=""

      if [[ -n "$old_hash" && "$new_hash" == "$old_hash" ]]; then
        # Plaintext unchanged — reuse existing ciphertext
        cat "$tmpindex"
        return 0
      fi
    fi
  fi

  # Encrypt the new plaintext
  age -R "$rf" < "$tmpinput"
}

##: smudge — decrypt (stdin ciphertext -> stdout plaintext)

cmd_smudge() {
  require_identity

  local tmpinput
  tmpinput="$(mktmp)"
  cat > "$tmpinput"

  # If input isn't age-encrypted, pass through unchanged
  local first_line
  first_line="$(head -1 "$tmpinput")"
  if [[ "$first_line" == "age-encryption.org"* ]]; then
    age -d -i "$AGE_IDENTITY" < "$tmpinput"
  else
    cat "$tmpinput"
  fi
}

##: diff — textconv (file path -> stdout plaintext)

cmd_diff() {
  local filepath="${1:?diff requires filepath argument}"
  require_identity

  if [[ -f "$filepath" ]]; then
    local header
    header="$(head -1 "$filepath")"
    if [[ "$header" == "age-encryption.org"* ]]; then
      age -d -i "$AGE_IDENTITY" < "$filepath"
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
    if [[ "$attrs" == *": filter: age" ]]; then
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

  if [[ -z "$files" ]]; then
    echo "$PROG: no files with filter=age found" >&2
    return 0
  fi

  local count=0
  while IFS= read -r f; do
    rm -f "$root/$f"
    git checkout -- "$f"
    count=$((count + 1))
    echo "$PROG: unlocked $f" >&2
  done <<< "$files"

  echo "$PROG: unlocked $count file(s)" >&2
}

##: lock — replace working tree files with encrypted blobs from index

cmd_lock() {
  local root
  root="$(repo_root)"

  local files
  files="$(age_files)"

  if [[ -z "$files" ]]; then
    echo "$PROG: no files with filter=age found" >&2
    return 0
  fi

  local count=0
  while IFS= read -r f; do
    local fullpath="$root/$f"
    local tmpblob
    tmpblob="$(mktmp)"
    if git show ":$f" > "$tmpblob" 2>/dev/null && [[ -s "$tmpblob" ]]; then
      cp "$tmpblob" "$fullpath"
      # Re-add so git updates its stat cache (clean filter passes through ciphertext)
      git add "$f"
      count=$((count + 1))
      echo "$PROG: locked $f" >&2
    else
      echo "$PROG: skipped $f (not in index)" >&2
    fi
  done <<< "$files"

  echo "$PROG: locked $count file(s)" >&2
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
  *)
    echo "Usage: $PROG <install|clean|smudge|diff|unlock|lock> [args...]" >&2
    echo "" >&2
    echo "Commands:" >&2
    echo "  install [pattern...] Set up git filter config (default: .secrets/*)" >&2
    echo "  clean <file>       Encrypt filter (used by git)" >&2
    echo "  smudge             Decrypt filter (used by git)" >&2
    echo "  diff <file>        Textconv filter for diffs (used by git)" >&2
    echo "  unlock             Decrypt all filter=age files in working tree" >&2
    echo "  lock               Restore encrypted blobs from index to working tree" >&2
    echo "" >&2
    echo "Environment:" >&2
    echo "  AGE_IDENTITY       Path to age identity file (required for decrypt)" >&2
    echo "" >&2
    echo "Files:" >&2
    echo "  .age-recipients    Recipient public keys (repo root)" >&2
    exit 1
    ;;
esac
