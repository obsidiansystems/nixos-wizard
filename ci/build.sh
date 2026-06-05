#!/usr/bin/env bash
set -euo pipefail

ARCH="${1:?usage: build.sh <arch>}"
TARGET="isoImageGraphical-${ARCH}"

nix build ".#${TARGET}"

mkdir -p out
cp result/iso/*.iso out/
cd out
sha256sum *.iso > SHA256SUMS
sha512sum *.iso > SHA512SUMS
