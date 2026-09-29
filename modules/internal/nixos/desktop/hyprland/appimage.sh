# appimage: keeps downloaded AppImages in one place, each with a menu entry.
# Everything it writes is named after the app id, so `remove` finds it all:
#   ~/Applications/<id>.AppImage
#   ~/.local/share/applications/appimage-<id>.desktop
#   ~/.local/share/icons/appimage-<id>.<ext>
# The binfmt registration runs the AppImage through appimage-run, which
# unpacks it into ~/.cache/appimage-run/<sha256>; that copy is removed when
# the AppImage is replaced or removed.

apps_dir="$HOME/Applications"
data_dir="${XDG_DATA_HOME:-$HOME/.local/share}"
desktop_dir="$data_dir/applications"
icon_dir="$data_dir/icons"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/appimage-run"

usage() {
  cat <<'USAGE'
usage: appimage add <file.AppImage> [--name <id>]
       appimage remove <id>
       appimage list

  add     move the AppImage to ~/Applications and add it to the app menu,
          replacing an installed one with the same id. The id comes from the
          AppImage's own .desktop file unless --name is given.
  remove  delete the AppImage, its menu entry, icon and unpacked cache
  list    show installed AppImages by id
USAGE
}

die() {
  echo "appimage: $*" >&2
  exit 1
}

clear_cache() {
  [ -f "$1" ] || return 0
  rm -rf "${cache_dir:?}/$(sha256sum "$1" | cut -d' ' -f1)"
}

add() {
  local src="" id=""
  while [ $# -gt 0 ]; do
    case "$1" in
    --name)
      [ $# -ge 2 ] || die "--name needs a value"
      id="$2"
      shift 2
      ;;
    -*) die "unknown option: $1" ;;
    *)
      [ -z "$src" ] || die "one AppImage at a time"
      src="$1"
      shift
      ;;
    esac
  done
  [ -n "$src" ] || {
    usage
    exit 1
  }
  [ -f "$src" ] || die "no such file: $src"
  src="$(realpath "$src")"

  local tmp
  tmp="$(mktemp -d)"
  # shellcheck disable=SC2064 # expand now: tmp is local
  trap "rm -rf '$tmp'" EXIT
  # appimage-run prints and exits 0 for a file that isn't an AppImage, so
  # check that something was unpacked.
  appimage-run -x "$tmp/root" "$src" >/dev/null
  [ -d "$tmp/root" ] || die "not an AppImage: $src"

  local entry
  entry="$(find "$tmp/root" -maxdepth 1 -name '*.desktop' -print -quit)"
  [ -n "$entry" ] || die "no .desktop file inside $src"
  if [ -z "$id" ]; then
    id="$(basename "$entry" .desktop)"
  fi
  case "$id" in
  "" | */* | .*) die "bad id: $id" ;;
  esac

  local dest="$apps_dir/$id.AppImage"
  mkdir -p "$apps_dir" "$desktop_dir" "$icon_dir"

  # The icon named by the entry, else the AppImage's .DirIcon.
  local icon_name icon="" ext
  icon_name="$(sed -n 's/^Icon=//p' "$entry" | head -n1)"
  for ext in svg png xpm; do
    if [ -n "$icon_name" ] && [ -f "$tmp/root/$icon_name.$ext" ]; then
      icon="$tmp/root/$icon_name.$ext"
      break
    fi
  done
  if [ -z "$icon" ] && [ -e "$tmp/root/.DirIcon" ]; then
    icon="$tmp/root/.DirIcon"
    ext=png
    if grep -q '<svg' "$icon" 2>/dev/null; then ext=svg; fi
  fi

  if [ "$src" != "$dest" ]; then
    clear_cache "$dest"
    mv -f "$src" "$dest"
  fi
  chmod +x "$dest"

  # Point every Exec (actions included) at the installed AppImage, keeping its
  # arguments; drop TryExec, which names a binary that isn't on PATH.
  local edits=(-e "s|^Exec=[^ ]*|Exec=\"$dest\"|" -e '/^TryExec=/d')
  rm -f "$icon_dir/appimage-$id".*
  if [ -n "$icon" ]; then
    cp -L "$icon" "$icon_dir/appimage-$id.$ext"
    edits+=(-e "s|^Icon=.*|Icon=$icon_dir/appimage-$id.$ext|")
  fi
  sed "${edits[@]}" "$entry" >"$desktop_dir/appimage-$id.desktop"

  echo "installed $id: $dest"
}

remove() {
  [ $# -eq 1 ] || {
    usage
    exit 1
  }
  local id="$1" dest="$apps_dir/$1.AppImage"
  [ -f "$dest" ] || [ -f "$desktop_dir/appimage-$id.desktop" ] || die "not installed: $id"
  clear_cache "$dest"
  rm -f "$dest" "$desktop_dir/appimage-$id.desktop" "$icon_dir/appimage-$id".*
  echo "removed $id"
}

list() {
  local f
  for f in "$apps_dir"/*.AppImage; do
    [ -e "$f" ] || continue
    basename "$f" .AppImage
  done
}

case "${1:-}" in
add)
  shift
  add "$@"
  ;;
remove)
  shift
  remove "$@"
  ;;
list) list ;;
-h | --help | help) usage ;;
*)
  usage
  exit 1
  ;;
esac
