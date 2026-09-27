# audio: the audio panel's helpers, ported from Omarchy's
# omarchy-audio-sink-availability and omarchy-audio-{input,output}-set-default.
#   audio sink-availability                   <sink><TAB><1|0> per sink
#   audio set-default input|output <id> <name> make it the default and move
#                                              the running streams onto it

# A sink with ports is available when any port is; one without ports always is.
sink_availability() {
  pactl list sinks 2>/dev/null | awk '
    function emit() { if (name != "") print name "\t" ((ports == 0 || available) ? 1 : 0) }
    /^Sink #/ { emit(); name = ""; in_ports = 0; ports = 0; available = 0; next }
    /^[[:space:]]*Name:/ { name = $2; next }
    /^[[:space:]]*Ports:$/ { in_ports = 1; next }
    in_ports && /^\tActive Port:/ { in_ports = 0; next }
    in_ports && /^\t\t/ { ports++; if ($0 !~ /not available/) available = 1; next }
    END { emit() }
  '
}

set_default() {
  local direction=$1 id=$2 name=$3
  timeout 2 wpctl set-default "$id" 2>/dev/null || true

  if [[ $direction == input ]]; then
    pactl set-default-source "$name" 2>/dev/null || true
    pactl list short source-outputs 2>/dev/null | awk '{ print $1 }' | while read -r output; do
      pactl move-source-output "$output" "$name" 2>/dev/null || true
    done
    return
  fi

  timeout 2 pactl set-default-sink "$name" 2>/dev/null || true
  # Only application streams: a DSP filter's own output is a sink input too,
  # and moving it would rewire the processing.
  timeout 2 pactl list sink-inputs 2>/dev/null | awk '
    /^Sink Input #/ { id = substr($3, 2) }
    /application\.name = / {
      app = $0
      sub(/.*application\.name = "/, "", app)
      sub(/"$/, "", app)
      if (app != "EasyEffects") print id
    }' | while read -r input; do
    timeout 2 pactl move-sink-input "$input" "$name" 2>/dev/null || true
  done
}

case ${1:-} in
sink-availability) sink_availability ;;
set-default)
  if [[ ${2:-} =~ ^(input|output)$ && -n ${3:-} && -n ${4:-} ]]; then
    set_default "$2" "$3" "$4"
  else
    echo "usage: audio set-default input|output <node-id> <name>" >&2
    exit 2
  fi
  ;;
*)
  echo "usage: audio sink-availability | set-default input|output <node-id> <name>" >&2
  exit 2
  ;;
esac
