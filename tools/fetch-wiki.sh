#!/bin/bash
# Fetch NESdev wiki pages to .webcache/nesdevwiki/

BASE="https://www.nesdev.org/wiki"
CACHE_DIR="$(dirname "$0")/../.webcache/nesdevwiki"

# Ensure cache directory exists
mkdir -p "$CACHE_DIR"

for page in "$@"; do
    wget -q -O "$CACHE_DIR/${page}.html" "$BASE/$page" && echo "✓ $page" || echo "✗ $page"
done
