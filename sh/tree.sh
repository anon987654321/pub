#!/usr/bin/env zsh
# Displays a tree of directories and files.
# Usage: ./tree.sh [folder] [-a]

set -e
setopt globdots

include_hidden=false
folder="."
for arg in "$@"; do
  if [[ "$arg" == "-a" ]]; then
    include_hidden=true
  else
    folder="$arg"
  fi
done

if [[ ! -d "$folder" ]]; then
  echo "Error: '$folder' is not a directory"
  exit 1
fi

print_tree() {
  local dir="$1" indent="${2:-}"
  for entry in "$dir"/*(N); do
    if [[ ! -e "$entry" ]]; then
      continue
    fi
    
    if [[ -d "$entry" ]]; then
      echo "${indent}+-- ${entry:t}/"
      print_tree "$entry" "${indent}|   "
    else
      echo "${indent}+-- ${entry:t}"
    fi
  done
}

print_tree "$folder"
