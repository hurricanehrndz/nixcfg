#!/usr/bin/env bash

if ! grep -q strongbox .gitattributes /dev/null 2>&1; then
  cat <<EOF >>.gitattributes
secrets/* filter=strongbox diff=strongbox merge=strongbox
EOF
  echo "Strongbox: setup gitattributes" 1>&2
fi

if [[ ! -f "$PWD/.strongbox_recipient" ]]; then
  awk -F': ' '/# public key: /{print $2}' "$HOME/.strongbox_identity" > \
    "$PWD/.strongbox_recipient"
  echo "Strongbox: configured recipient" 1>&2
fi

if ! git config --local --list | grep -q strongbox; then
  git config filter.strongbox.clean "strongbox -clean %f"
  git config filter.strongbox.smudge "strongbox -smudge %f"
  git config filter.strongbox.required true
  git config diff.strongbox.textconv "strongbox -diff"
  echo "Strongbox: configured filter locally"
fi
