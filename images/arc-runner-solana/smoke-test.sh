#!/usr/bin/env bash
# Run inside the built image. Mirrors what the 3tock-quote CI lanes assume:
# GITHUB_PATH lines are prepended in order, so ~/.cargo/bin ends up first on PATH
# and cargo-build-sbf 4.4.0 must win over the Agave bundle's copy.
set -euo pipefail

export PATH="$HOME/.cargo/bin:$HOME/.local/share/solana/install/active_release/bin:$PATH"

echo "== user: $(id -un) (uid $(id -u)), HOME=$HOME"

echo "== tools"
for tool in git bash curl jq cc pkg-config cargo rustc rustup cargo-build-sbf solana-test-validator; do
  printf '%-22s' "$tool"
  command -v "$tool"
done

echo "== versions"
git --version
cargo --version
rustc --version
cargo-build-sbf --version
solana-test-validator --version

if [ "$(command -v cargo-build-sbf)" != "$HOME/.cargo/bin/cargo-build-sbf" ]; then
  echo "cargo-build-sbf must come from ~/.cargo/bin, not the Agave bundle." >&2
  exit 1
fi

echo "== platform-tools"
ls -d "$HOME/.cache/solana/v1.57"

echo "== openssl headers"
pkg-config --exists openssl
pkg-config --modversion openssl

echo "== host build and test (proves the C toolchain and linker work; offline)"
scratch="$(mktemp -d)"
cd "$scratch"
cargo init --lib --name smoke --quiet
cargo test --offline --quiet

echo "smoke test passed"
