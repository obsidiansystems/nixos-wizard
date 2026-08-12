#!/usr/bin/env bash
set -euo pipefail

ARCH="${1:?usage: build.sh <arch>}"
TARGET="isoImageGraphical-${ARCH}"

nix build ".#${TARGET}"

SHORT_SHA=$(git rev-parse --short HEAD)

mkdir -p out
for iso in result/iso/*.iso; do
  # Replace nixpkgs hash with our git short hash in the filename
  newname=$(basename "$iso" | sed "s/\.[a-f0-9]\{7\}-/.${SHORT_SHA}-/")
  cp "$iso" "out/${newname}"
done
cd out
sha256sum *.iso > SHA256SUMS
sha512sum *.iso > SHA512SUMS
