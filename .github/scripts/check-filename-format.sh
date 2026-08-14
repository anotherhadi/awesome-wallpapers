#!/usr/bin/env bash
# Validate wallpaper filenames against the naming convention described in README.md:
#   wallpaper-name_tag1_tag2.png
# - name: lowercase letters/digits, words separated by "-"
# - tags: lowercase letters, words separated by "-", tags separated by "_"
# - only .png and .gif are accepted
# - gifs must carry the "animated" tag
# - every gif must have a same-named .png counterpart

set -uo pipefail

wallpapers_dir="wallpapers"
name_re='^[a-z0-9]+(-[a-z0-9]+)*(_[a-z]+(-[a-z]+)*)*$'
status=0

if [[ ! -d "$wallpapers_dir" ]]; then
  echo "No $wallpapers_dir directory found, skipping."
  exit 0
fi

shopt -s nullglob
for file in "$wallpapers_dir"/*; do
  [[ -f "$file" ]] || continue
  filename=$(basename "$file")
  basename="${filename%.*}"
  ext="${filename##*.}"

  if [[ "$ext" != "png" && "$ext" != "gif" ]]; then
    echo "❌ $filename: only .png and .gif files are accepted"
    status=1
    continue
  fi

  if [[ ! "$basename" =~ $name_re ]]; then
    echo "❌ $filename: invalid name/tags, expected wallpaper-name_tag1_tag2 (lowercase, '-' separated words, '_' separated tags)"
    status=1
    continue
  fi

  if [[ "$ext" == "gif" ]]; then
    IFS='_' read -r -a parts <<<"$basename"
    has_animated=0
    for tag in "${parts[@]:1}"; do
      [[ "$tag" == "animated" ]] && has_animated=1
    done
    if [[ "$has_animated" -eq 0 ]]; then
      echo "❌ $filename: gif files must include the 'animated' tag"
      status=1
    fi

    if [[ ! -f "$wallpapers_dir/$basename.png" ]]; then
      echo "❌ $filename: missing matching static $basename.png"
      status=1
    fi
  fi
done

if [[ "$status" -eq 0 ]]; then
  echo "✅ All wallpaper filenames are valid."
fi

exit "$status"
