#!/usr/bin/env bash
set -uo pipefail

WORKSHOP_DIR="/home/alejandro/.local/share/Steam/steamapps/workshop/content/431960"

if [ ! -d "$WORKSHOP_DIR" ]; then
  echo "No existe $WORKSHOP_DIR" >&2
  exit 1
fi

declare -A id_by_label

for dir in "$WORKSHOP_DIR"/*/; do
  id=$(basename "$dir")
  project_json="$dir/project.json"
  [ -f "$project_json" ] || continue

  title=$(jq -r '.title // "sin titulo"' "$project_json" 2>/dev/null)
  type=$(jq -r '.type // "?"' "$project_json" 2>/dev/null)

  label="$title [$type] ($id)"
  id_by_label["$label"]="$id"
done

if [ "${#id_by_label[@]}" -eq 0 ]; then
  echo "No se encontró ningún wallpaper con project.json válido" >&2
  exit 1
fi

chosen_label=$(printf '%s\n' "${!id_by_label[@]}" | sort | wofi --dmenu --prompt "Wallpaper Engine:")
[ -z "$chosen_label" ] && exit 0

chosen_id="${id_by_label[$chosen_label]}"
echo "Elegido: $chosen_label -> $chosen_id"

mon=$(hyprctl monitors -j | jq -r '(.[] | select(.focused==true) // .[0]) | .name')

pkill -f "linux-wallpaperengine" 2>/dev/null
nohup linux-wallpaperengine --screen-root "$mon" --silent --fps 30 "$chosen_id" \
  >/tmp/we-engine.log 2>&1 &
disown
