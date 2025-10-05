# Toy Model 0: Toolchain Specification

Validate cc65 build workflow and Mesen2 debugging for NES development on macOS ARM64.

## Overview

**What it does:** Proves we can assemble 6502 code (ca65), link to bootable .nes ROM (ld65), and debug in Mesen2 emulator. No gameplay, graphics, or input handling.

**Key principles:**
- Minimal scope: reset vector + infinite loop only
- Build automation: Makefile for repeatability
- Debug validation: symbol files + breakpoint testing
- Documentation first: capture exact workflow for future toys

**Scope:** Single axis of complexity — build toolchain validation only. No PPU, APU, controller, or game logic.

**Integration context:** None (toy0 is foundation, no dependencies on other toys)

## Data Model

**Assembly source** (`hello.s`):
```asm
; NROM vectors at $FFFA-$FFFF
.segment "VECTORS"
    .word nmi_handler  ; $FFFA-$FFFB
    .word reset        ; $FFFC-$FFFD
    .word irq_handler  ; $FFFE-$FFFF

; PRG-ROM code
.segment "CODE"
reset:
    SEI           ; Disable interrupts
    CLD           ; Clear decimal mode
loop:
    JMP loop      ; Infinite loop

nmi_handler:
irq_handler:
    RTI
```

**Linker output** (`hello.nes`):
- Byte 0-15: iNES header (`4E 45 53 1A` + mapper/size flags)
- Byte 16-16399: PRG-ROM (16KB, code from .segment "CODE")
- Byte 16400-24591: CHR-ROM (8KB, empty/zero-filled)
- Total: 24592 bytes

**Debug symbols** (`hello.dbg`, optional):
- Label addresses (reset, loop, nmi_handler, irq_handler)
- Segment layout mapping
- Source line → address correlation

## Core Operations

### Build Operation
**Syntax:** `make` or `ca65 hello.s -o hello.o && ld65 hello.o -C nes.cfg -o hello.nes`

**Behavior:**
1. ca65 assembles hello.s → hello.o (object file with relocatable code)
2. ld65 links hello.o using nes.cfg → hello.nes (24592 byte ROM)
3. iNES header auto-generated or explicit in linker config
4. CHR-ROM section zero-filled (8KB)

**Validation:**
- Exit code 0 on success
- Output file exactly 24592 bytes
- Header bytes: `4E 45 53 1A 01 01 00 00 ...` (NROM, 16KB PRG, 8KB CHR)

### Debug Operation
**Syntax:** `open -a Mesen toys/toy0_toolchain/hello.nes`

**Behavior:**
1. Mesen2 loads ROM
2. CPU starts at address in $FFFC-$FFFD (reset vector)
3. Debugger shows disassembly, registers, memory
4. User can set breakpoints, step instructions, inspect state

**Validation:**
- No load errors
- PC (program counter) points to reset handler
- Can set breakpoint at reset address
- Memory viewer shows code at $8000+ (PRG-ROM mirror)

## Test Scenarios

### Simple: Minimal Build
**Input:** hello.s (reset vector + loop), empty nes.cfg using defaults
**Expected:** 24592 byte hello.nes, boots in Mesen2, infinite loop at reset handler
**Validation:** hexdump header, file size, emulator loads without error

### Complex: Build with Debug Symbols
**Input:** hello.s with labels, ca65 `-g` flag, ld65 `--dbgfile` flag
**Expected:** hello.nes + hello.dbg symbol file, Mesen2 shows source labels in debugger
**Validation:** Breakpoint on `reset:` label works, disassembly shows label names

### Error: Invalid Assembly
**Input:** hello.s with syntax error (undefined label, bad instruction)
**Expected:** ca65 exits non-zero, error message shows file:line, build stops
**Validation:** make fails cleanly, error is human-readable

### Error: Missing Linker Config
**Input:** ld65 without `-C nes.cfg`
**Expected:** Linker error about missing memory layout
**Validation:** Build fails with clear message about config requirement

## Success Criteria

**Build workflow validated** (Q1.1):
- [ ] ca65 assembles hello.s → hello.o without errors
- [ ] ld65 links hello.o → hello.nes with valid iNES header
- [ ] Confirm 16-byte header + 16KB PRG + 8KB CHR = 24592 bytes total
- [ ] Document exact ca65/ld65 flags used

**Debug workflow validated** (Q1.2, Q1.3):
- [ ] Symbol file generated (if possible with ca65/ld65)
- [ ] Mesen2 loads ROM successfully
- [ ] Can set breakpoint at RESET handler
- [ ] Can inspect CPU registers (A, X, Y, PC, SP, flags)
- [ ] Can view memory ($0000-$07FF RAM, $8000+ PRG-ROM)

**Build automation working** (Q1.6):
- [ ] `make` builds hello.nes from source
- [ ] `make clean` removes build artifacts
- [ ] `make run` opens ROM in Mesen2 (if feasible)
- [ ] Makefile documents cc65 installation path assumptions

**Documented for future toys**:
- [ ] LEARNINGS.md captures exact build command sequence
- [ ] Notes on ca65 syntax differences from asm6f (wiki examples)
- [ ] Any macOS-specific paths or Homebrew assumptions
