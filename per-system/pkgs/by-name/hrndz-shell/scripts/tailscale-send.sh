# tailscale-send <machine> [file...]: Taildrop files to a tailnet machine,
# ported from Omarchy's omarchy-tailscale-send. With no files it asks for
# them with the GTK file chooser.

machine=${1:?usage: tailscale-send <machine> [file...]}
shift
# Talk about the machine by its short name, not its MagicDNS name.
name=${machine%%.*}
files=("$@")

notify() {
  notify-send -a Tailscale "$@"
}

if ((${#files[@]} == 0)); then
  # zenity exits 1 when the chooser is cancelled, other codes when it failed.
  status=0
  picked=$(zenity --file-selection --multiple --separator=$'\n' --title="Send to $name" 2>/dev/null) || status=$?
  if ((status > 1)); then
    notify -u critical "Could not send to $name" "The file chooser did not open"
    exit 1
  fi
  [[ -n $picked ]] || exit 0
  readarray -t files <<<"$picked"
fi

if ((${#files[@]} == 1)); then
  what=$(basename "${files[0]}")
else
  what="${#files[@]} files"
fi

if error=$(tailscale file cp --update-interval=0 -- "${files[@]}" "$machine:" 2>&1); then
  notify "Sent to $name" "$what"
else
  notify -u critical "Could not send to $name" "${error:-Taildrop transfer failed}"
  exit 1
fi
