#!/bin/zsh
# Keep Kiki's reusable chrome on its shared spacing, opacity, radius and color
# system. A deliberate value may stay on a line with `token-exempt: <reason>`.
set -u
cd "${0:A:h}/.."

# Callers may pass an explicit file list (used by the fixture tests). Otherwise
# check every Swift source except the file that defines the tokens themselves.
if (( $# > 0 )); then
  files=("$@")
else
  files=()
  for file in Sources/**/*.swift(N); do
    [[ "$file" == "Sources/KikiDesign/KikiDesignTokens.swift" ]] && continue
    files+=("$file")
  done
fi

# Token names contain no numeric values, so these patterns identify raw values
# in SwiftUI chrome regardless of the expression around them.
patterns=(
  '\.padding\([^)]*[1-9]'
  'spacing:[^,)]*[1-9]'
  'cornerRadius:[^,)]*[0-9]'
  '\.opacity\([^)]*[0-9]\.[0-9]'
  '\.system\([[:space:]]*size[[:space:]]*:'
  'Color\([[:space:]]*(red|white|hue)[[:space:]]*:'
  '#[0-9A-Fa-f]{6}\b'
  '0x[0-9A-Fa-f]{6}'
)
pattern="${(j:|:)patterns}"

for file in "${files[@]}"; do
  if [[ ! -r "$file" ]]; then
    print -u2 "check_design_tokens: cannot read $file"
    exit 2
  fi
done

hits=$(grep -nHE "$pattern" "${files[@]}" | grep -v 'token-exempt:')
if [[ -n "$hits" ]]; then
  print -u2 "Raw design values in Kiki sources (use KikiDesignTokens, a system style, or mark token-exempt with a reason):"
  print -u2 -- "$hits"
  exit 1
fi
print "Design tokens: OK (${#files} files)"
