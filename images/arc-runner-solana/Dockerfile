# syntax=docker/dockerfile:1
#
# Runner image for the 3tock-quote CI lanes (`contract` and `clock-lane`).
#
# It reproduces the toolchains that docs/dev/ci.md lists for the old `r86s`
# runner, installed under /home/runner so the workflow steps that add
# $HOME/.cargo/bin and $HOME/.local/share/solana/install/active_release/bin to
# PATH work unchanged. Node is not baked in: actions/setup-node installs it.
#
# The base tag floats on purpose; a weekly rebuild (arc-runner-image.yml) follows it.
FROM ghcr.io/actions/actions-runner:latest

# Versions required by 3tock-quote docs/dev/ci.md and .github/workflows/qa.yml.
ARG RUST_MIN_VERSION=1.97.1
ARG CARGO_BUILD_SBF_VERSION=4.4.0
ARG PLATFORM_TOOLS_VERSION=v1.57
ARG AGAVE_VERSION=4.3.0

# C toolchain, pkg-config and the OpenSSL headers (companion build).
USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential pkg-config libssl-dev \
 && rm -rf /var/lib/apt/lists/*

USER runner
WORKDIR /home/runner

# Host Rust (stable) in ~/.cargo/bin; fail the build if it is older than required.
RUN curl --proto '=https' --tlsv1.2 -sSfL https://sh.rustup.rs \
      | sh -s -- -y --profile minimal --default-toolchain stable --no-modify-path \
 && export PATH="$HOME/.cargo/bin:$PATH" \
 && rust="$(rustc --version | cut -d' ' -f2)" \
 && oldest="$(printf '%s\n%s\n' "$RUST_MIN_VERSION" "$rust" | sort -V | head -n1)" \
 && if [ "$oldest" != "$RUST_MIN_VERSION" ]; then \
      echo "Rust $rust is older than required $RUST_MIN_VERSION" >&2; exit 1; \
    fi

# cargo-build-sbf, then its platform-tools into ~/.cache/solana/<version>.
# The scratch crate makes --install-only independent of any workspace.
RUN export PATH="$HOME/.cargo/bin:$PATH" \
 && cargo install cargo-build-sbf --version "$CARGO_BUILD_SBF_VERSION" --locked \
 && scratch="$(mktemp -d)" && cd "$scratch" \
 && cargo init --lib --name sbf_probe --quiet \
 && cargo-build-sbf --install-only --tools-version "$PLATFORM_TOOLS_VERSION" \
 && test -d "$HOME/.cache/solana/$PLATFORM_TOOLS_VERSION" \
 && rm -rf "$scratch" "$HOME/.cargo/registry" "$HOME/.cargo/git"

# Agave CLI (solana-test-validator is only ever asked for --version by the lane).
RUN curl -sSfL "https://release.anza.xyz/v${AGAVE_VERSION}/install" | sh \
 && test -x "$HOME/.local/share/solana/install/active_release/bin/solana-test-validator"

LABEL org.opencontainers.image.description="GitHub Actions runner with Rust, cargo-build-sbf, platform-tools and Agave for 3tock-quote CI"
