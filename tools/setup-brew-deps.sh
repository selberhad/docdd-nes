#!/bin/bash
# Setup NES development Homebrew dependencies for macOS ARM64

set -e

# Required packages
REQUIRED=(sdl2 cc65)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== NES Development Toolchain Setup (Homebrew) ==="
echo

# Check Homebrew installed
if ! command -v brew &> /dev/null; then
    echo -e "${RED}✗ Homebrew not found${NC}"
    echo "Install from: https://brew.sh"
    exit 1
fi
echo -e "${GREEN}✓ Homebrew installed${NC}"

# Check architecture
ARCH=$(arch)
if [ "$ARCH" != "arm64" ]; then
    echo -e "${YELLOW}⚠ Warning: Not running on ARM64 (detected: $ARCH)${NC}"
    echo "  This script is optimized for Apple Silicon Macs"
fi

echo

# Check and install each package
INSTALLED=0
MISSING=0

for pkg in "${REQUIRED[@]}"; do
    if brew list "$pkg" &> /dev/null; then
        echo -e "${GREEN}✓ $pkg${NC} - already installed"
        INSTALLED=$((INSTALLED + 1))
    else
        echo -e "${YELLOW}⚠ $pkg${NC} - not installed, installing..."
        if brew install "$pkg"; then
            echo -e "${GREEN}✓ $pkg${NC} - installed successfully"
            INSTALLED=$((INSTALLED + 1))
        else
            echo -e "${RED}✗ $pkg${NC} - installation failed"
            MISSING=$((MISSING + 1))
        fi
    fi
done

echo
echo "=== Summary ==="
echo "Installed: $INSTALLED/${#REQUIRED[@]}"
[ $MISSING -gt 0 ] && echo -e "${RED}Failed: $MISSING${NC}"

echo
echo "=== Next Steps ==="

# Check if Mesen2 installed
if [ -d "/Applications/Mesen.app" ] || [ -d "$HOME/Applications/Mesen.app" ]; then
    echo -e "${GREEN}✓ Mesen2${NC} - found in Applications"
    echo
    echo "=== Toolchain Complete! ==="
    echo "Ready to build first ROM. See STUDY_PLAN.md Option A."
else
    echo "1. Download Mesen2 (native ARM64):"
    echo "   https://github.com/SourMesen/Mesen2/releases"
    echo "   Get: Mesen_2.1.1_macOS_ARM64_AppleSilicon.zip"
    echo "   Extract to Applications"
    echo
fi

echo "Optional: Compile asm6f for simpler syntax"
echo "  (cc65 works, but syntax differs from wiki examples)"
echo
echo "See CLAUDE.md for full toolchain details"

[ $MISSING -eq 0 ] && exit 0 || exit 1
