#!/usr/bin/env bash
# Regenerate WALLPAPERS.md (and its 2/3-column variants, and tags/*.md)
# from the contents of wallpapers/.
# When a wallpaper has both a static png and an animated gif (same
# basename), only one row is emitted, previewed with the gif.

set -uo pipefail

wallpapers_dir="wallpapers"
tags_dir="tags"

if [[ ! -d "$wallpapers_dir" ]]; then
  exit 0
fi

# Each entry: name<TAB>basename<TAB>preview<TAB>raw_tags(underscore-joined)
build_entries() {
  shopt -s nullglob
  declare -A seen
  for file in "$wallpapers_dir"/*.png "$wallpapers_dir"/*.gif; do
    filename=$(basename "$file")
    base="${filename%.*}"

    [[ -n "${seen[$base]:-}" ]] && continue
    seen[$base]=1

    preview="$file"
    if [[ -f "$wallpapers_dir/$base.gif" ]]; then
      preview="$wallpapers_dir/$base.gif"
    fi

    name="${base%%_*}"
    tags=""
    if [[ "$base" == *_* ]]; then
      tags="${base#*_}"
    fi

    printf '%s\t%s\t%s\t%s\n' "$name" "$base" "$preview" "$tags"
  done | sort -t $'\t' -k1,1
}

mapfile -t entries < <(build_entries)

# Collect the sorted, de-duplicated list of tags, and which entries have them.
declare -A tag_seen
all_tags=()
for entry in "${entries[@]}"; do
  IFS=$'\t' read -r _ _ _ tags_raw <<<"$entry"
  [[ -z "$tags_raw" ]] && continue
  IFS='_' read -ra tokens <<<"$tags_raw"
  for t in "${tokens[@]}"; do
    if [[ -z "${tag_seen[$t]:-}" ]]; then
      tag_seen[$t]=1
      all_tags+=("$t")
    fi
  done
done
mapfile -t sorted_tags < <(printf '%s\n' "${all_tags[@]}" | sort)

entry_has_tag() {
  local tags_raw="$1" tag="$2" t
  IFS='_' read -ra tokens <<<"$tags_raw"
  for t in "${tokens[@]}"; do
    [[ "$t" == "$tag" ]] && return 0
  done
  return 1
}

# tags_links <raw_tags> <tag-link-prefix>
# Turns "foo_bar-baz" into "[foo](<prefix>foo.md), [bar-baz](<prefix>bar-baz.md)"
tags_links() {
  local tags_raw="$1" tag_prefix="$2"
  [[ -z "$tags_raw" ]] && return
  local -a tokens
  IFS='_' read -ra tokens <<<"$tags_raw"
  local out="" t first=1
  for t in "${tokens[@]}"; do
    ((first)) || out+=", "
    first=0
    out+="[${t}](${tag_prefix}${t}.md)"
  done
  printf '%s' "$out"
}

# render_table <cols> <preview-prefix> <tag-link-prefix> <entries...>
render_table() {
  local cols="$1" prefix="$2" tag_prefix="$3"
  shift 3
  local -a items=("$@")

  local header="|" sep="|"
  local i
  for ((i = 0; i < cols; i++)); do
    header+=" Preview | Name | Tags |"
    sep+="---------|------|------|"
  done
  echo "$header"
  echo "$sep"

  local total=${#items[@]}
  local idx=0
  while ((idx < total)); do
    local line="|"
    local c
    for ((c = 0; c < cols; c++)); do
      if ((idx < total)); then
        local name base preview tags_raw tags_display
        IFS=$'\t' read -r name base preview tags_raw <<<"${items[idx]}"
        tags_display="$(tags_links "$tags_raw" "$tag_prefix")"
        line+=" ![${base}](${prefix}${preview}) | ${name} | ${tags_display} |"
        ((idx++))
      else
        line+="  |  |  |"
      fi
    done
    echo "$line"
  done
}

# render_grid <cols> <preview-prefix> <tag-link-prefix> <entries...>
# Like render_table, but each cell stacks the image with its name and
# tags underneath instead of using separate Name/Tags columns.
render_grid() {
  local cols="$1" prefix="$2" tag_prefix="$3"
  shift 3
  local -a items=("$@")

  local header="|" sep="|"
  local i
  for ((i = 0; i < cols; i++)); do
    header+=" |"
    sep+=":---:|"
  done
  echo "$header"
  echo "$sep"

  local total=${#items[@]}
  local idx=0
  while ((idx < total)); do
    local line="|"
    local c
    for ((c = 0; c < cols; c++)); do
      if ((idx < total)); then
        local name base preview tags_raw tags_display cell
        IFS=$'\t' read -r name base preview tags_raw <<<"${items[idx]}"
        tags_display="$(tags_links "$tags_raw" "$tag_prefix")"
        cell="![${base}](${prefix}${preview})<br>${name}"
        [[ -n "$tags_display" ]] && cell+="<br>${tags_display}"
        line+=" ${cell} |"
        ((idx++))
      else
        line+="  |"
      fi
    done
    echo "$line"
  done
}

nav_block() {
  echo "[1 Column](WALLPAPERS.md) · [2 Columns](WALLPAPERS-2COL.md) · [3 Columns](WALLPAPERS-3COL.md)"
}

tags_block() {
  local prefix="$1"
  echo "<details>"
  echo "<summary>Tags</summary>"
  echo
  local t
  for t in "${sorted_tags[@]}"; do
    echo "- [${t}](${prefix}${tags_dir}/${t}.md)"
  done
  echo
  echo "</details>"
}

generate_main() {
  local file="$1" cols="$2"
  {
    echo "# Wallpapers"
    echo
    nav_block
    echo
    tags_block ""
    echo
    if ((cols > 1)); then
      render_grid "$cols" "" "${tags_dir}/" "${entries[@]}"
    else
      render_table "$cols" "" "${tags_dir}/" "${entries[@]}"
    fi
  } >"$file"
  git add "$file"
}

generate_main "WALLPAPERS.md" 1
generate_main "WALLPAPERS-2COL.md" 2
generate_main "WALLPAPERS-3COL.md" 3

rm -rf "$tags_dir"
mkdir -p "$tags_dir"
for t in "${sorted_tags[@]}"; do
  tag_items=()
  for entry in "${entries[@]}"; do
    IFS=$'\t' read -r _ _ _ tags_raw <<<"$entry"
    if entry_has_tag "$tags_raw" "$t"; then
      tag_items+=("$entry")
    fi
  done
  {
    echo "# Tag: ${t}"
    echo
    echo "[← All wallpapers](../WALLPAPERS.md)"
    echo
    render_table 1 "../" "" "${tag_items[@]}"
  } >"$tags_dir/$t.md"
done
git add "$tags_dir"

echo "Generated WALLPAPERS.md, WALLPAPERS-2COL.md, WALLPAPERS-3COL.md and $tags_dir/"
