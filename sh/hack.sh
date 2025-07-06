#!/usr/bin/env zsh
# Finds text files matching a pattern and opens them in Vim.
# Usage: ./hack.sh [pattern]

set -e
setopt nullglob extendedglob

pattern="$1"
if [[ -n "$pattern" ]]; then
  pattern=$(echo "$pattern" | sed 's/[.[\*^$]/\\&/g')
fi

typeset -a files_to_open

for file in **/*(.N); do
  is_text=$(file -b "$file" | grep -q "text"; echo $?)
  if [[ $is_text -eq 0 ]]; then
  
    if [[ -z "$pattern" ]]; then
      files_to_open+=("$file")
    elif grep -q "$pattern" "$file" 2>/dev/null; then
      files_to_open+=("$file")
    fi
  fi
done

if (( ${#files_to_open} > 0 )); then
  echo "Files found:"
  printf "  %s\n" "${files_to_open[@]}"
  
  echo "Open in Vim? (Y/n)"
  read -r response
  if [[ "${response:-Y}" =~ ^[Yy]$ ]]; then
    vim "${files_to_open[@]}"
  else
    echo "Cancelled."
  fi
else
  echo "No matching files."
fi
