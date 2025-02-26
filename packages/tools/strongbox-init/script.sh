#!/usr/bin/env bash

cat <<EOF >>.gitattributes
secrets/* filter=strongbox diff=strongbox merge=strongbox
EOF

awk -F': ' '/# public key: /{print $2}' "$HOME/.config/sops/age/keys.txt" > \
    "$PWD/.strongbox_recipient"
