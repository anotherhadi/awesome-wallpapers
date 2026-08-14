#!/usr/bin/env bash
# Every gif in wallpapers/ must have a same-named static .png counterpart
# (see README.md). This hook generates the missing ones from the gif's
# first frame and stages them, so a commit adding a gif automatically
# gets its png alongside it.

set -uo pipefail

wallpapers_dir="wallpapers"
changed=0

if [[ ! -d "$wallpapers_dir" ]]; then
  exit 0
fi

if ! command -v magick >/dev/null 2>&1; then
  echo "❌ imagemagick (magick) is required but was not found in PATH"
  exit 1
fi

shopt -s nullglob
for gif in "$wallpapers_dir"/*.gif; do
  basename="${gif%.gif}"
  png="$basename.png"

  if [[ -f "$png" ]]; then
    continue
  fi

  echo "Generating $png from $(basename "$gif")"
  if ! magick "${gif}[0]" "$png"; then
    echo "❌ Failed to generate $png"
    exit 1
  fi
  git add "$png"
  changed=1
done

if [[ "$changed" -eq 1 ]]; then
  echo "New static png(s) were generated and staged, please commit again."
  exit 1
fi

exit 0
