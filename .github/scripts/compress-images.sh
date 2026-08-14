#!/usr/bin/env bash
# Losslessly compress wallpapers before they are committed, so the repo
# doesn't grow larger than it needs to. Only files staged in this commit
# are touched, to keep the hook fast.

set -uo pipefail

wallpapers_dir="wallpapers"
changed=0

if [[ ! -d "$wallpapers_dir" ]]; then
  exit 0
fi

if ! command -v oxipng >/dev/null 2>&1; then
  echo "❌ oxipng is required but was not found in PATH"
  exit 1
fi
if ! command -v gifsicle >/dev/null 2>&1; then
  echo "❌ gifsicle is required but was not found in PATH"
  exit 1
fi

mapfile -t staged < <(git diff --cached --name-only --diff-filter=ACM -- "$wallpapers_dir")

for file in "${staged[@]}"; do
  [[ -f "$file" ]] || continue
  ext="${file##*.}"

  before=$(stat -c%s "$file")

  case "$ext" in
    png)
      oxipng -o max --strip safe -q "$file" >/dev/null
      ;;
    gif)
      gifsicle -O3 --batch "$file"
      ;;
    *)
      continue
      ;;
  esac

  after=$(stat -c%s "$file")
  if [[ "$after" -ne "$before" ]]; then
    echo "Compressed $file ($before -> $after bytes)"
    git add "$file"
    changed=1
  fi
done

if [[ "$changed" -eq 1 ]]; then
  echo "Image(s) were compressed and re-staged, please commit again."
  exit 1
fi

exit 0
