# Focuses the first Hyprland window whose class matches <app-name>
# (case-insensitive regex). Exits 1 when there is none.
app=${1:?usage: focus-app <app-name>}

address=$(hyprctl clients -j 2>/dev/null |
  jq -r --arg pattern "$app" 'first(.[] | select((.class // "") | test($pattern; "i"))).address // empty')

[[ -n $address ]] || exit 1
hyprctl dispatch "hl.dsp.focus({ window = \"address:$address\" })" >/dev/null
