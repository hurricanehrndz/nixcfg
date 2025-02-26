#!/usr/bin/env bash

if  ! grep -q strongbox .gitattributes 2>&1 /dev/null; then
cat <<EOF >>.gitattributes
secrets/* filter=strongbox diff=strongbox merge=strongbox
EOF
fi


if [[ ! -f "$PWD/.strongbox_recipient" ]]; then
    awk -F': ' '/# public key: /{print $2}' "$HOME/.strongbox_identity" > \
        "$PWD/.strongbox_recipient"
fi

git config filter.strongbox.clean "strongbox -clean %f"
git config filter.strongbox.smudge "strongbox -smudge %f"
git	config filter.strongbox.required true
git config diff.strongbox.textconv "strongbox -diff"
