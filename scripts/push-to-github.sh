#!/usr/bin/env bash
# Run this script in YOUR terminal (Cursor → Terminal). It cannot be completed
# by a bot: GitHub needs you to sign in once in the browser.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

resolve_gh() {
  if command -v gh >/dev/null 2>&1; then
    command -v gh
    return
  fi
  local ver="2.92.0"
  local cache="${HOME}/.cache/seads-gh"
  local bin="${cache}/gh_${ver}_linux_amd64/bin/gh"
  mkdir -p "$cache"
  if [[ ! -x "$bin" ]]; then
    echo "Downloading GitHub CLI (${ver}) to ${cache} ..."
    local url="https://github.com/cli/cli/releases/download/v${ver}/gh_${ver}_linux_amd64.tar.gz"
    curl -fsSL -o "${cache}/gh.tgz" "$url"
    tar -xzf "${cache}/gh.tgz" -C "$cache"
    chmod +x "$bin"
    rm -f "${cache}/gh.tgz"
  fi
  echo "$bin"
}

GH="$(resolve_gh)"
echo "Using: $GH"
"$GH" --version

echo ""
echo "=== Step 1: Log in to GitHub (browser will open) ==="
"$GH" auth login -h github.com -p https -w

echo ""
echo "=== Step 2: Make git use this login for github.com ==="
"$GH" auth setup-git

echo ""
echo "=== Step 3: Push this repo ==="
git push origin main

echo ""
echo "Done. On your other PC: git pull"
