#!/usr/bin/env bash
set -euo pipefail

mkdir -p release
cp artifacts/iso-*/*.iso release/
cat artifacts/iso-*/SHA256SUMS > release/SHA256SUMS
cat artifacts/iso-*/SHA512SUMS > release/SHA512SUMS

if ! ls release/*.iso &>/dev/null; then
  echo "ERROR: No ISO files found in release directory"
  exit 1
fi

X86_ISO=$(ls release/*x86_64*.iso 2>/dev/null | head -1)
if [[ -n "$X86_ISO" ]]; then
  NixOS_VERSION=$(basename "$X86_ISO" | sed 's/^nixos-gnome-//;s/-x86_64-linux\.iso$//')
else
  NixOS_VERSION="unknown"
fi

SHORT_SHA=$(git rev-parse --short HEAD)
VERSION="${NixOS_VERSION}-${SHORT_SHA}"
echo "VERSION=$VERSION" >> "$GITHUB_ENV"
echo "NIXOS_VERSION=$NixOS_VERSION" >> "$GITHUB_ENV"

# Generate changelog from commits since last release tag
PREV_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [[ -n "$PREV_TAG" ]]; then
  CHANGELOG=$(git log --oneline "${PREV_TAG}..HEAD" --format="- %s")
else
  CHANGELOG=$(git log --oneline -20 --format="- %s")
fi

{
  echo 'CHANGELOG<<CHANGELOG_EOF'
  echo "$CHANGELOG"
  echo 'CHANGELOG_EOF'
} >> "$GITHUB_ENV"
