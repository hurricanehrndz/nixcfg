# hrndz-shell: the one command bindings, menus and scripts call for what the
# desktop shell provides.
#   hrndz-shell <feature> [args]            see usage below
#   hrndz-shell ipc <target> <method> [args] raw IPC into the running shell

# The Quickshell config name Home Manager installs the shell under, and the
# user unit programs.quickshell runs it as.
config=hrndz-shell
unit=quickshell.service
state="$HOME/.local/state/hrndz-shell"
# The running screen recording's pid and file, and its region for the webcam.
# Private to the user: stop reads the file back as a path.
runtime="${XDG_RUNTIME_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/hrndz-shell}"
recording="$runtime/hrndz-screenrecord"
recording_region="$recording-region"

usage() {
  cat <<'USAGE'
usage: hrndz-shell <feature> [args]

  start                       start the shell (a no-op once it runs)
  launcher | menu | system-menu
  keybindings                 searchable list of the key bindings
  clipboard | emoji
  lock [--wait]               lock; --wait returns once the lock is secure
  bar                         show or hide the bar
  osd volume|microphone|brightness
  notifications dismiss-one|dismiss-all|invoke-last|history
  panel audio|bluetooth|network|power|display|calendar
  screenshot [smart|region|window|screen]
  screenrecord [region|screen] [--audio] [--mic] [--webcam]
      [--webcam-device=<dev>] [--webcam-size=small|medium|large]
                              start, or stop the running recording; --webcam
                              asks which camera when there are several
  webcam list                 the cameras, as "<device>  <name>"; a
                              /dev/v4l/by-id path also works as --webcam-device
  webcam smaller|larger|reset|small|medium|large
                              resize the recording's webcam overlay
  ocr | qr                    copy the text or QR code in a region
  color-picker
  ipc <target> <method> [args...]
USAGE
}

ipc() {
  # qs matches instances by display. A caller from outside the session (ssh,
  # desktop-vnc) has none, so recover it from the newest compositor socket.
  if [[ -z ${WAYLAND_DISPLAY:-} ]]; then
    local socket
    socket=$(find "${XDG_RUNTIME_DIR:-/run/user/$UID}" -maxdepth 1 -name 'wayland-[0-9]*' ! -name '*.lock' -printf '%T@ %f\n' 2>/dev/null |
      sort -rn | head -n1 | cut -d' ' -f2)
    [[ -n $socket ]] && export WAYLAND_DISPLAY=$socket
  fi

  # qs reports connection failures with a nonzero exit, but IPC-level ones
  # (unknown target, bad arguments) on stdout with exit 0.
  local output
  if ! output=$(timeout --kill-after=1s 2s qs ipc -n -c "$config" call -- "$@" 2>/dev/null); then
    echo "hrndz-shell: the shell is not running" >&2
    return 1
  fi
  case $output in
  "Target not found." | "Function not found." | "Too few arguments provided"* | "Too many arguments provided"* | "Not ready to accept queries yet"*)
    echo "hrndz-shell: $output" >&2
    return 1
    ;;
  esac
  [[ -z $output ]] || printf '%s\n' "$output"
}

toggle() {
  ipc shell toggle "$1" "${2:-"{}"}" >/dev/null
}

menu() {
  toggle omarchy.menu "$(jq -nc --arg menu "$1" '{menu: $menu}')"
}

# Pick one line from stdin in the menu; prints the pick, exits 1 on cancel.
# `select_line <prompt> <width> <max-height>` sizes the card to its rows;
# `select_line <prompt> palette` gives it the launcher palette's size and place.
select_line() {
  local prompt=$1 width=${2:-300} height=${3:-0} layout='' dir payload status=0
  if [[ $width == palette ]]; then
    layout=palette width=0
  fi
  dir=$(mktemp -d)
  payload=$(jq -Rsc --arg prompt "$prompt" --arg sel "$dir/selection" --arg donefile "$dir/done" \
    --argjson width "$width" --argjson height "$height" --arg layout "$layout" \
    '{mode: "select", prompt: $prompt, options: (split("\n") | map(select(length > 0))),
      selectionFile: $sel, doneFile: $donefile, width: $width, maxHeight: $height, layout: $layout}')
  if ipc shell summon omarchy.menu "$payload" >/dev/null; then
    while [[ ! -e $dir/done ]]; do sleep 0.05; done
    [[ -s $dir/selection ]] && cat "$dir/selection" || status=1
  else
    status=1
  fi
  rm -rf "$dir"
  return "$status"
}

lock() {
  if [[ ${1:-} != --wait ]]; then
    [[ $(ipc lock lock) == ok ]]
    return
  fi

  # The lock is asynchronous, and a shell that is still starting refuses it
  # or is not answering yet; ask until the session reports secure.
  local deadline=$((SECONDS + 30)) status
  while ((SECONDS < deadline)); do
    status=$(ipc lock status 2>/dev/null |
      jq -r 'if .secure then "secure" elif .requested then "locking" else "idle" end' 2>/dev/null) || status=""
    case $status in
    secure) return 0 ;;
    locking) ;;
    *) ipc lock lock >/dev/null 2>&1 || true ;;
    esac
    sleep 0.1
  done
  echo "hrndz-shell: the session did not lock" >&2
  return 1
}

toggle_bar() {
  local flag="$state/toggles/bar-off"
  if [[ -e $flag ]]; then
    rm -f "$flag"
  else
    mkdir -p "${flag%/*}"
    touch "$flag"
  fi
  # The shell's watch on the toggles directory can miss quick flips.
  ipc omarchy.bar syncHidden >/dev/null 2>&1 || true
}

# osd <icon> <percent>
show_osd() {
  ipc osd show "$(jq -nc --arg icon "$1" --arg value "$2" \
    '{icon: $icon, message: "", value: $value, progressText: ($value + "%"), max: "100", duration: ""}')" >/dev/null
}

osd() {
  local out percent device
  case ${1:-} in
  volume | microphone)
    device=$([[ $1 == volume ]] && echo @DEFAULT_AUDIO_SINK@ || echo @DEFAULT_AUDIO_SOURCE@)
    # "Volume: 0.45" or "Volume: 0.45 [MUTED]"
    out=$(wpctl get-volume "$device") || return 1
    percent=$(awk '{ printf "%d", $2 * 100 + 0.5 }' <<<"$out")
    if [[ $out == *MUTED* ]]; then
      show_osd "$([[ $1 == volume ]] && echo volume-muted || echo microphone-muted)" "$percent"
    else
      # An empty icon lets the OSD pick the volume glyph by level.
      show_osd "$([[ $1 == volume ]] && echo "" || echo microphone)" "$percent"
    fi
    ;;
  brightness)
    # "device,class,current,percent%,max"; no backlight means nothing to show.
    out=$(brightnessctl -m 2>/dev/null) || return 0
    percent=$(cut -d, -f4 <<<"$out")
    show_osd brightness "${percent%\%}"
    ;;
  *)
    usage >&2
    return 2
    ;;
  esac
}

notifications() {
  local method
  case ${1:-} in
  dismiss-one) method=dismissOne ;;
  dismiss-all) method=dismissAll ;;
  invoke-last) method=invokeLast ;;
  history) method=showHistory ;;
  *)
    usage >&2
    return 2
    ;;
  esac
  ipc notifications "$method" >/dev/null
}

panel() {
  local id
  case ${1:-} in
  audio | bluetooth | network | power) id=omarchy.$1 ;;
  display) id=omarchy.monitor ;;
  calendar) id=omarchy.clock ;;
  *)
    usage >&2
    return 2
    ;;
  esac
  toggle "$id"
}

keybindings() {
  local list="${XDG_CONFIG_HOME:-$HOME/.config}/hrndz-shell/keybindings.txt"
  [[ -r $list ]] || {
    echo "hrndz-shell: no $list" >&2
    return 1
  }
  # CEILING: a read-only reference; picking a row only closes the menu.
  # Dispatching the pick would need the bind's action next to each line.
  select_line Keybindings palette <"$list" >/dev/null || true
}

# omasnap saves to ~/Pictures/Screenshots, copies, and shows a preview whose
# Edit button opens the annotation editor.
screenshot() {
  local mode=${1:-smart}
  case $mode in
  smart | region) ;;
  window) mode=windows ;;
  screen) mode=fullscreen ;;
  *)
    usage >&2
    return 2
    ;;
  esac
  exec omasnap "$mode"
}

# Omarchy's omarchy-capture-text and omarchy-capture-qr (omacom/omarchy, MIT,
# rev 97a9fce54f5df007afe7b8637ddc09314f38ad00). hyprpicker freezes the screen
# so nothing moves under the selection; kill $freeze once grim has run.
freeze_select() {
  hyprpicker -r -z >/dev/null 2>&1 &
  freeze=$!
  sleep 0.1
  region=$(slurp 2>/dev/null) || region=
}

ocr() {
  local freeze region text=
  freeze_select
  if [[ -n $region ]]; then
    text=$(grim -g "$region" - |
      tesseract stdin stdout --oem 1 --psm 6 -l eng --dpi 300 -c preserve_interword_spaces=1 2>/dev/null) || text=
  fi
  kill "$freeze" 2>/dev/null || true
  [[ -n $text ]] || return 0
  printf '%s' "$text" | wl-copy
  omarchy-notification-send -g 󰴑 "Copied text from selection to clipboard"
}

# QR codes often carry secrets (2FA setup URIs), so the value only goes to
# the clipboard, marked sensitive: clipboard-capture leaves it out of the
# history. Only QR is decoded; other symbologies false-positive on screens.
qr() {
  local freeze region value=
  freeze_select
  if [[ -n $region ]]; then
    value=$(grim -g "$region" - | zbarimg -q --raw -Sdisable -Sqrcode.enable - 2>/dev/null) || value=
  fi
  kill "$freeze" 2>/dev/null || true
  [[ -n $region ]] || return 0
  if [[ -z $value ]]; then
    omarchy-notification-send -g 󰐲 -u critical "No QR code found" "Select a region containing a QR code"
    return 1
  fi
  printf '%s' "$value" | wl-copy --sensitive
  omarchy-notification-send -g 󰐲 "QR code copied to clipboard"
}

# Omarchy's webcam overlay (omacom/omarchy, MIT, rev as above), from
# omarchy-capture-webcam-list, omarchy-capture-screenrecording-with-webcam,
# omarchy-capture-screenrecording and omarchy-capture-webcam-resize: the
# camera cropped to 8:9 portrait in a pinned window (rules.nix) in the
# recorded area's bottom-right corner, where the recording picks it up.

# The first capture-capable node of each device, as "<device>  <name>".
webcam_list() {
  local line name='' device emitted=0
  while IFS= read -r line; do
    if [[ -n $line && $line != [[:space:]]* ]]; then
      name=$line
      emitted=0
    elif ((!emitted)); then
      device=${line#"${line%%[![:space:]]*}"}
      if [[ $device == /dev/video* ]] && webcam_capture_capable "$device"; then
        emitted=1
        printf '%s  %s\n' "$device" "$name"
      fi
    fi
  done < <(v4l2-ctl --list-devices 2>/dev/null)
}

webcam_capture_capable() {
  v4l2-ctl --device "$1" --info 2>/dev/null | awk '
    /^[[:space:]]*Device Caps[[:space:]]*:/ { inspect = 1; next }
    inspect && /^[[:space:]]*Video Capture/ { found = 1 }
    END { exit !found }
  '
}

# The only camera, or the one picked from the menu when there are several.
webcam_pick() {
  local selection
  local -a devices
  mapfile -t devices < <(webcam_list)
  if ((${#devices[@]} == 0)); then
    omarchy-notification-send "No webcam devices found" -u critical -t 3000
    return 1
  fi
  if ((${#devices[@]} == 1)); then
    selection=${devices[0]}
  else
    selection=$(printf '%s\n' "${devices[@]}" | select_line "Select Webcam" 520 520) || return 1
  fi
  printf '%s\n' "${selection%%[[:space:]]*}"
}

webcam_start() {
  local device=$1 size=$2 region=$3 formats resolution options=framerate=30 waited
  webcam_stop

  # The first of these 16:9 modes the camera offers.
  formats=$(v4l2-ctl --list-formats-ext -d "$device" 2>/dev/null) || true
  for resolution in 640x360 1280x720 1920x1080; do
    if [[ $formats == *"$resolution"* ]]; then
      options="video_size=$resolution,$options"
      break
    fi
  done

  mpv "av://v4l2:$device" --profile=low-latency --untimed --no-cache \
    --demuxer-lavf-o="$options" '--vf=lavfi=[crop=ih*8/9:ih]' \
    --title=WebcamOverlay --wayland-app-id="WebcamOverlay-$size" \
    --no-border --no-audio --no-osc --osd-level=0 --really-quiet &>/dev/null &
  for ((waited = 0; waited < 40; waited++)); do
    hyprctl clients -j | jq -e 'any(.[]; .title == "WebcamOverlay")' >/dev/null && break
    sleep 0.05
  done
  if ((waited == 40)); then
    webcam_stop
    omarchy-notification-send -u critical "Webcam overlay failed to start" "$device"
    return 1
  fi
  [[ -z $region ]] || printf '%s\n' "$region" >"$recording_region"
  webcam "$size"
  # Let the move settle, or the recording starts with it.
  sleep 0.6
}

webcam_stop() {
  pkill -f WebcamOverlay || true
  # Unlike upstream, force it after 2s: while the display sleeps mpv ignores
  # SIGTERM until it wakes, holding the camera (and its light) open.
  for _ in {1..20}; do
    pgrep -f WebcamOverlay >/dev/null || break
    sleep 0.1
  done
  pkill -KILL -f WebcamOverlay || true
  rm -f "$recording_region"
}

# List the cameras, or resize the overlay to one of three 8:9 sizes scaled
# from the recorded region's height (else its monitor's), kept $margin inside
# that area's bottom-right corner.
webcam() {
  local margin=40 action=${1:-} client address width height monitor_id monitor
  local x y w h region base available target_width target_height target_x target_y i j
  local -a heights widths
  case $action in
  list)
    webcam_list
    return
    ;;
  smaller | larger | reset | small | medium | large) ;;
  *)
    usage >&2
    return 2
    ;;
  esac

  client=$(hyprctl clients -j 2>/dev/null |
    jq -cer 'first(.[] | select(.title == "WebcamOverlay")) // empty' 2>/dev/null) || return 0
  read -r address width height monitor_id < <(jq -r '[.address, .size[0], .size[1], .monitor] | @tsv' <<<"$client")
  [[ -n $address && $width =~ ^[0-9]+$ && $height =~ ^[0-9]+$ && $monitor_id =~ ^[0-9]+$ ]] || return 0
  ((width > 0 && height > 0)) || return 0
  monitor=$(hyprctl monitors -j 2>/dev/null |
    jq -cer --argjson id "$monitor_id" 'first(.[] | select(.id == $id)) // empty' 2>/dev/null) || return 0
  read -r x y w h < <(jq -r '((.transform // 0) % 2 == 1) as $rotated |
    [.x, .y, (((if $rotated then .height else .width end) / .scale) | floor),
      (((if $rotated then .width else .height end) / .scale) | floor)] | @tsv' <<<"$monitor")
  [[ $x =~ ^-?[0-9]+$ && $y =~ ^-?[0-9]+$ && $w =~ ^[0-9]+$ && $h =~ ^[0-9]+$ ]] || return 0
  if [[ -f $recording_region ]] && region=$(<"$recording_region") &&
    [[ $region =~ ^([0-9]+)x([0-9]+)\+(-?[0-9]+)\+(-?[0-9]+)$ ]]; then
    w=${BASH_REMATCH[1]} h=${BASH_REMATCH[2]} x=${BASH_REMATCH[3]} y=${BASH_REMATCH[4]}
  fi

  # A narrow region scales from the height its width allows the large size.
  base=$h available=$((w - 2 * margin))
  if ((available > 0 && base * 3 / 10 > available)); then
    base=$((available * 10 / 3))
  fi
  heights=($(((base * 9 + 25) / 50)) $(((base + 2) / 4)) $(((base * 27 + 40) / 80)))
  for j in 0 1 2; do
    widths[j]=$(((heights[j] * 8 + 4) / 9))
  done

  # smaller: the largest size below the current width; larger: the smallest
  # above it. With neither, the overlay keeps its size and is re-anchored.
  i=-1
  case $action in
  small) i=0 ;;
  medium | reset) i=1 ;;
  large) i=2 ;;
  smaller)
    for j in 2 1 0; do
      ((widths[j] < width)) && i=$j && break
    done
    ;;
  larger)
    for j in 0 1 2; do
      ((widths[j] > width)) && i=$j && break
    done
    ;;
  esac
  target_width=$width target_height=$height
  if ((i >= 0)); then
    target_width=${widths[i]} target_height=${heights[i]}
  fi

  target_x=$((x + w - target_width - margin)) target_y=$((y + h - target_height - margin))
  ((target_x >= x + margin)) || target_x=$((x + margin))
  ((target_y >= y + margin)) || target_y=$((y + margin))
  address="address:$address"
  hyprctl dispatch "hl.dsp.window.resize({ window = \"$address\", x = $target_width, y = $target_height })" >/dev/null
  hyprctl dispatch "hl.dsp.window.move({ window = \"$address\", x = $target_x, y = $target_y })" >/dev/null
}

# Omarchy's omarchy-capture-screenrecording without the loudness pass, bar
# indicator or smart region picker. The recorder's pid and file live in $recording between the start
# and stop calls.
screenrecord() {
  local pid file preview dir mode region='' sources='' webcam='' device='' size=medium
  local -a target audio=()

  if [[ -r $recording ]] && read -r pid file <"$recording" && kill -0 "$pid" 2>/dev/null; then
    # SIGINT lets it finish the file.
    kill -INT "$pid"
    for _ in {1..50}; do
      kill -0 "$pid" 2>/dev/null || break
      sleep 0.1
    done
    rm -f "$recording"
    webcam_stop
    if kill -0 "$pid" 2>/dev/null; then
      kill -KILL "$pid"
      omarchy-notification-send -u critical "Screen recording failed" "The recorder had to be killed; $file may be unplayable."
      return 1
    fi
    preview="$recording.png"
    ffmpeg -y -loglevel quiet -ss 0.1 -i "$file" -frames:v 1 "$preview" || preview=
    omarchy-notification-send -t 10000 ${preview:+--image "$preview"} \
      "Screen recording saved" "Click to play" --exec xdg-open "$file"
    return
  fi

  mode=${1:-region}
  case $mode in
  region | screen) ;;
  *)
    usage >&2
    return 2
    ;;
  esac
  shift || true
  for arg; do
    case $arg in
    --audio) sources+=${sources:+|}default_output ;;
    --mic) sources+=${sources:+|}default_input ;;
    --webcam) webcam=1 ;;
    --webcam-device=*) device=${arg#*=} ;;
    --webcam-size=*) size=${arg#*=} ;;
    *)
      usage >&2
      return 2
      ;;
    esac
  done
  case $size in
  small | medium | large) ;;
  *)
    echo "Invalid webcam size: $size (expected small, medium, or large)" >&2
    return 1
    ;;
  esac
  # One mixed track: most players only play the first of several.
  [[ -n $sources ]] && audio=(-a "$sources" -ac aac)
  if [[ -n $webcam && -z $device ]]; then
    device=$(webcam_pick) || return 1
  fi

  if [[ $mode == region ]]; then
    region=$(slurp -d -f '%wx%h+%x+%y') || return 0
    target=(-w region -region "$region")
  else
    target=(-w "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')")
  fi

  mkdir -p "$runtime"
  [[ -n ${XDG_RUNTIME_DIR:-} ]] || chmod 700 "$runtime"
  if [[ -n $webcam ]]; then
    webcam_start "$device" "$size" "$region" || return 1
  fi

  dir="${XDG_VIDEOS_DIR:-$HOME/Videos}"
  mkdir -p "$dir"
  file="$dir/screenrecording-$(date +%Y-%m-%d_%H-%M-%S).mp4"
  gpu-screen-recorder "${target[@]}" -f 60 -k auto -fm cfr -fallback-cpu-encoding yes \
    "${audio[@]}" -o "$file" >/dev/null 2>&1 &
  pid=$!
  while kill -0 "$pid" 2>/dev/null && [[ ! -f $file ]]; do
    sleep 0.2
  done
  if ! kill -0 "$pid" 2>/dev/null; then
    webcam_stop
    omarchy-notification-send -u critical "Screen recording failed to start"
    return 1
  fi
  printf '%s %s\n' "$pid" "$file" >"$recording"
  omarchy-notification-send -t 3000 "Recording" "Alt+Print stops it"
}

feature=${1:-}
shift || true
case $feature in
start) systemctl --user start "$unit" ;;
launcher | menu) menu root ;;
system-menu) menu system ;;
keybindings) keybindings ;;
clipboard) toggle omarchy.clipboard ;;
emoji) toggle omarchy.emojis ;;
lock) lock "$@" ;;
bar) toggle_bar ;;
osd) osd "$@" ;;
notifications) notifications "$@" ;;
panel) panel "$@" ;;
screenshot) screenshot "$@" ;;
screenrecord) screenrecord "$@" ;;
webcam) webcam "$@" ;;
ocr) ocr ;;
qr) qr ;;
color-picker) pkill hyprpicker || hyprpicker -a ;;
ipc) ipc "$@" ;;
-h | --help | help) usage ;;
*)
  usage >&2
  exit 2
  ;;
esac
