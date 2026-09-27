# ambient-set: installs the ambient video the screensaver, lock screen and
# login screen play, and the still frame the wallpaper shows.
# AMBIENT_DIR comes from the NixOS module (ambient.nix).

usage() {
  cat <<'USAGE'
usage: ambient-set <file|url> [--at <time>] [--format <yt-dlp format>]
       ambient-set --clear

  <file|url>   a local video, or a page yt-dlp can download from (YouTube...).
               Only the video track is kept; the ambient video is muted.
  --at <time>  take the still from this moment ([[HH:]MM:]SS[.ms]) instead of
               the best-scoring frame; playback starts there too
  --format     yt-dlp format selector, instead of the best stream this GPU
               decodes in hardware
  --clear      remove the video; everything falls back to the Stylix image or
               colour
USAGE
}

dir=$AMBIENT_DIR
# The best video-only stream in a codec the GPU decodes: highest resolution,
# then frame rate, then codec (yt-dlp ranks AV1 over VP9 over HEVC over H.264).
# CEILING: the codec list is the decoders VCN 3 (RX 6800) and most current
# GPUs have; it does not know H.264 stops at 4096 wide in hardware, which only
# matters for sites offering H.264 above 4K. Pass --format for other hardware.
format="bv[vcodec~='^(av01|vp0?9|hev1|hvc1|avc1)']"

source="" at="" clear=0
while (($#)); do
  case $1 in
  --at)
    at=${2:?--at needs a time}
    shift
    ;;
  --format)
    format=${2:?--format needs a selector}
    shift
    ;;
  --clear) clear=1 ;;
  -h | --help)
    usage
    exit 0
    ;;
  -*)
    usage >&2
    exit 2
    ;;
  *) source=$1 ;;
  esac
  shift
done

if [[ ! -w $dir ]]; then
  echo "ambient-set: $dir is not writable; the ambient group applies from your next login." >&2
  exit 1
fi

reload() {
  hrndz-shell ipc ambient reload >/dev/null 2>&1 || true
}

if ((clear)); then
  rm -f "$dir/video" "$dir/still.png" "$dir/still.jpg" "$dir/start"
  # Keeps the boot-time default (ambient.default) from reinstalling one.
  touch "$dir/cleared"
  reload
  exit 0
fi
[[ -n $source ]] || {
  usage >&2
  exit 2
}

# Staged next to the files it replaces, so each replacement is one rename.
work=$(mktemp -d "$dir/.incoming.XXXXXX")
trap 'rm -rf "$work"' EXIT

if [[ $source == *://* ]]; then
  yt-dlp --no-playlist --no-part -f "$format" -S res,fps,vcodec -o "$work/download.%(ext)s" "$source"
  source=$(find "$work" -maxdepth 1 -name 'download.*' -print -quit)
elif [[ ! -r $source ]]; then
  echo "ambient-set: cannot read $source" >&2
  exit 1
fi

# Video track only, in Matroska, which holds any codec it may be.
ffmpeg -loglevel error -i "$source" -map 0:v:0 -c copy -an "$work/video.mkv"

seconds() {
  awk -F: '{ s = 0; for (i = 1; i <= NF; i++) s = s * 60 + $i; printf "%.3f\n", s }' <<<"$1"
}

# The still: one frame most people would pick as a wallpaper. Candidates are
# key frames only, which encoders place at scene changes and every few
# seconds: playback then seeks to the still exactly, and decoding one frame
# per candidate (in parallel, at 640 px) is quick where decoding a whole 4K
# video is not. ffmpeg's thumbnail filter keeps the most representative (by
# histogram) of every 8, dropping flashes and one-off frames. Each is scored:
#   rejected  mean luma (YAVG) outside 40-200: too dark or too bright
#             luma spread (YHIGH-YLOW) under 60: a fade, haze or flat frame
#             blurdetect over 8: soft focus or motion blur
#   score     spread / (1 + blur): contrasty and sharp wins
# With no survivor the best score among the rejects is used.
# CEILING: at most 240 key frames, evenly spaced, are looked at, which keeps a
# long video to a minute or so; raise it if a pick misses a better moment.
pick() {
  local keys
  keys=$(ffprobe -v error -select_streams v:0 -show_entries packet=pts_time,flags -of csv=p=0 "$work/video.mkv" |
    awk -F, '$2 ~ /K/ { print $1 }')
  keys=$(awk -v n="$(wc -l <<<"$keys")" 'BEGIN { step = int((n + 239) / 240) } (NR - 1) % step == 0' <<<"$keys")
  mkdir "$work/frames"
  # $BASH, not sh: a systemd service's PATH (ambient-default) has no sh.
  # shellcheck disable=SC2016 # the positional parameters are the inner shell's
  awk '{ printf "%04d %s\n", NR, $0 }' <<<"$keys" |
    xargs -P "$(nproc)" -L1 "$BASH" -c \
      'ffmpeg -loglevel error -nostdin -ss "$4" -i "$1" -frames:v 1 -vf scale=640:-2 "$2/$3.png"' \
      _ "$work/video.mkv" "$work/frames"
  # Frame n of the image sequence sits at pts n-1; the nth key time maps it back.
  ffmpeg -loglevel error -framerate 1 -i "$work/frames/%04d.png" \
    -vf "thumbnail=8,signalstats,blurdetect,metadata=print:file=-" -f null - |
    awk -v keys="$keys" '
      BEGIN { split(keys, key, "\n") }
      function flush() {
        if (n == "") return
        spread = high - low
        score = spread / (1 + blur)
        ok = avg >= 40 && avg <= 200 && spread >= 60 && blur <= 8
        printf "%s %.2f %d avg=%.0f spread=%.0f blur=%.2f\n", key[n + 1], score, ok, avg, spread, blur
      }
      /pts_time:/ { flush(); n = $NF; sub("pts_time:", "", n) }
      /lavfi.signalstats.YAVG=/ { avg = substr($0, index($0, "=") + 1) + 0 }
      /lavfi.signalstats.YLOW=/ { low = substr($0, index($0, "=") + 1) + 0 }
      /lavfi.signalstats.YHIGH=/ { high = substr($0, index($0, "=") + 1) + 0 }
      /lavfi.blur=/ { blur = substr($0, index($0, "=") + 1) + 0 }
      END { flush() }
    ' | sort -k3,3nr -k2,2nr
}

if [[ -n $at ]]; then
  start=$(seconds "$at")
else
  candidates=$(pick)
  [[ -n $candidates ]] || {
    echo "ambient-set: no frames to pick a still from" >&2
    exit 1
  }
  printf 'still candidates (time score accepted stats):\n%s\n' "$candidates" | head -n 11
  start=$(head -n1 <<<"$candidates" | cut -d' ' -f1)
fi
echo "still at ${start}s"

# Lossless, at the stream's full resolution: the wallpaper is this frame.
ffmpeg -loglevel error -ss "$start" -i "$work/video.mkv" -frames:v 1 -pix_fmt rgb24 "$work/still.png"
echo "$start" >"$work/start"

chmod 0644 "$work/video.mkv" "$work/still.png" "$work/start"
mv -f "$work/video.mkv" "$dir/video"
mv -f "$work/still.png" "$dir/still.png"
rm -f "$dir/still.jpg"
mv -f "$work/start" "$dir/start"
rm -f "$dir/cleared"
reload
echo "ambient video installed in $dir"
