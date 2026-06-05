#!/usr/bin/env bash
set -euo pipefail

mkdir -p release
cp artifacts/iso-*/*.iso release/
cat artifacts/iso-*/SHA256SUMS > release/SHA256SUMS
cat artifacts/iso-*/SHA512SUMS > release/SHA512SUMS
