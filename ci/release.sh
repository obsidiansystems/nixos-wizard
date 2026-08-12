#!/usr/bin/env bash
set -euo pipefail

mkdir -p release
cp artifacts/iso-*/*.iso release/
cat artifacts/iso-*/SHA256SUMS > release/SHA256SUMS
cat artifacts/iso-*/SHA512SUMS > release/SHA512SUMS

X86_ISO=$(ls release/*x86_64*.iso 2>/dev/null | head -1)
if [[ -n "$X86_ISO" ]]; then
  NixOS_VERSION=$(basename "$X86_ISO" | sed 's/^nixos-gnome-//;s/-x86_64-linux\.iso$//')
else
  NixOS_VERSION="unknown"
fi

VERSION="${NixOS_VERSION}-${GITHUB_RUN_NUMBER:-0}"
echo "VERSION=$VERSION" >> "$GITHUB_ENV"
echo "NIXOS_VERSION=$NixOS_VERSION" >> "$GITHUB_ENV"
