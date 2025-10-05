# toy0_toolchain

Minimal NES ROM build to validate cc65 toolchain and Mesen2 debugging on macOS ARM64.

## Purpose

First test ROM proving we can assemble 6502 code (ca65), link to bootable .nes file (ld65), and debug in Mesen2 emulator. Validates build workflow before implementing any NES subsystems (no graphics, input, or audio). Answers Q1.1, Q1.2, Q1.3, Q1.6 from `learnings/.docdd/5_open_questions.md`.

## Key Operations

```bash
# Build ROM from source
make                  # Assembles hello.s → hello.o → hello.nes

# Run in emulator
make run              # Opens hello.nes in Mesen2

# Clean build artifacts
make clean            # Removes *.o, *.nes, *.dbg
```

## Core Concepts

- **ca65 segments**: `.segment "CODE"` for PRG-ROM code, `.segment "VECTORS"` for reset/NMI/IRQ vectors at $FFFA-$FFFF
- **ld65 config**: Maps segments to NROM memory layout (16KB PRG, 8KB CHR), generates iNES header
- **Debug symbols**: `ca65 -g` + `ld65 --dbgfile` produces .dbg file for Mesen2 label support
- **NROM mapper**: Simplest layout, 16KB PRG-ROM mirrored at $8000-$BFFF/$C000-$FFFF

## Gotchas

- **ca65 syntax ≠ asm6f**: Wiki examples use asm6f (`.bank`, `.org`). ca65 uses `.segment` directives.
- **Homebrew paths**: Assumes cc65 at `/opt/homebrew/bin/`, Mesen at `/Applications/Mesen.app`.
- **CHR-ROM required**: Even with CHR-RAM games, NROM needs 8KB CHR section in ROM (can be empty).
- **Symbol loading**: Mesen2 may require specific .dbg format. Test breakpoints by address if labels don't work.

## Quick Test

```bash
cd toys/toy0_toolchain
make clean && make && make run
# Mesen2 should load ROM, show black screen, infinite loop in debugger
```
