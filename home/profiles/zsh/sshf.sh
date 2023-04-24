#!/usr/bin/env bash
# shellcheck shell=bash

args=("$@")
if [[ "${args[1]}" =~ [0-9]+ ]]; then
    uid="${args[1]}"
    args=("${args[@]:1}")
else
    uid=1000
fi
extra_socket="$(gpgconf --list-dirs agent-extra-socket)"
ssh -R /run/user/"$uid"/gnupg/S.gpg-agent:"$extra_socket" -A "${args[@]}"
