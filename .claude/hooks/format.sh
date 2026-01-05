#!/bin/bash
# Auto-format files after Write/Edit/MultiEdit operations

set -euo pipefail

# Read JSON from stdin and extract file_path
FILE_PATH=$(cat | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]]; then
  exit 0
fi

EXT="${FILE_PATH##*.}"

case "$EXT" in
  go)
    gofmt -w "$FILE_PATH" 2>/dev/null && echo "Formatted: $FILE_PATH"
    ;;
  rs)
    rustfmt "$FILE_PATH" 2>/dev/null && echo "Formatted: $FILE_PATH"
    ;;
  ts|tsx|js|jsx)
    if [[ -f "biome.json" || -f "biome.jsonc" ]]; then
      npx @biomejs/biome format --write "$FILE_PATH" 2>/dev/null && echo "Formatted with Biome: $FILE_PATH"
    elif [[ -f "node_modules" ]]; then
      echo "No formatter configured for: $FILE_PATH"
    else
      deno fmt "$FILE_PATH" 2>/dev/null && echo "Formatted with Deno: $FILE_PATH"
    fi
    ;;
  json)
    jq . "$FILE_PATH" > "$FILE_PATH.tmp" && mv "$FILE_PATH.tmp" "$FILE_PATH" && echo "Formatted: $FILE_PATH"
    ;;
esac

exit 0
