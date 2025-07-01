#!/bin/bash

# Check if a filename was provided
if [ -z "$1" ]; then
  echo "Usage: $0 <yaml_file>"
  exit 1
fi

input="$1"
temp_file=$(mktemp)

awk '
  /- code:/ {
    code_val = $3
    print
    next
  }
  /definition: metadata_not_provided/ {
    sub("metadata_not_provided", code_val)
  }
  { print }
' "$input" > "$temp_file" && mv "$temp_file" "$input"

echo "File '$input' updated successfully."
