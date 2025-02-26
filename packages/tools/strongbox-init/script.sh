#!/usr/bin/env bash

cat <<EOF >>.gitattributes
secrets/* filter=strongbox diff=strongbox merge=strongbox
EOF

awk -F': ' '/# public key: /{print $2}' "$HOME/.strongbox_identity" > \
    "$PWD/.strongbox_recipient"
