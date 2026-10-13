#!/bin/zsh
# Keep Kiki's reusable chrome on its shared spacing, opacity, radius and color
# system. A deliberate value may stay on a line with `token-exempt: <reason>`;
# the reason is required.
#
# Apps reuse this check with their own file list:
#   ../Kiki_mackit/script/check_design_tokens.sh App/Views/*.swift
# Exit status: 0 clean, 1 raw values found, 2 a file could not be read.
set -u

# Callers may pass an explicit file list (apps, and the fixture tests).
# Otherwise check every Kiki Swift source except the file that defines the
# tokens themselves.
if (( $# > 0 )); then
  files=("$@")
else
  cd "${0:A:h}/.."
  files=()
  for file in Sources/**/*.swift(N); do
    [[ "$file" == "Sources/KikiDesign/KikiDesignTokens.swift" ]] && continue
    files+=("$file")
  done
fi

for file in "${files[@]}"; do
  if [[ ! -f "$file" || ! -r "$file" ]]; then
    print -u2 "check_design_tokens: cannot read $file"
    exit 2
  fi
done

# Whole files, not lines: a value written on the line after `.padding(` is
# still a raw value. Token names contain no digits, so any non-zero number
# inside these arguments is one, whatever the spacing around it.
hits=$(perl -e '
  use strict; use warnings;
  my @patterns = (
    qr/\.padding\([^)]*[1-9]/,
    qr/spacing:[^,)]*[1-9]/,
    qr/cornerRadius:[^,)]*[0-9]/,
    qr/\.opacity\([^)]*[0-9]\.[0-9]/,
    qr/\.system\(\s*size\s*:/,
    qr/Color\(\s*(?:red|white|hue)\s*:/,
    qr/#[0-9A-Fa-f]{6}\b/,
    qr/0x[0-9A-Fa-f]{6}/,
  );
  for my $file (@ARGV) {
    open(my $fh, "<", $file) or do { print STDERR "check_design_tokens: cannot read $file: $!\n"; exit 2 };
    my $text = do { local $/; <$fh> };
    close $fh;
    my @lines = split /\n/, $text, -1;
    my %seen;
    for my $re (@patterns) {
      while ($text =~ /$re/g) {
        my ($start, $end) = ($-[0], $+[0]);
        my $first = 1 + (substr($text, 0, $start) =~ tr/\n//);
        my $last = $first + (substr($text, $start, $end - $start) =~ tr/\n//);
        next if grep { $lines[$_ - 1] =~ /token-exempt:\s*\S/ } $first .. $last;
        next if $seen{$first}++;
        print "$file:$first:$lines[$first - 1]\n";
      }
    }
  }
' -- "${files[@]}")
scan_status=$?
if (( scan_status != 0 )); then
  print -u2 "check_design_tokens: scan failed ($scan_status)"
  exit 2
fi

if [[ -n "$hits" ]]; then
  print -u2 "Raw design values (use KikiDesignTokens, a system style, or mark token-exempt with a reason):"
  print -u2 -- "$hits"
  exit 1
fi
print "Design tokens: OK (${#files} files)"
