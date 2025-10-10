# NES Development Toolchain

**Document Status**: Priority 2.5 learnings - Toolchain overview from NESdev wiki
**Source**: `.webcache/Tools.html`, `.webcache/Emulators.html`, `.webcache/Emulator_tests.html`
**Last Updated**: 2025-10-05

## Overview

This document captures essential toolchain knowledge for NES development, covering assemblers, emulators, graphics tools, audio tools, and test ROMs. The goal is to make informed tool selection decisions for the ddd-nes project.

---

## 1. Assemblers

### Commonly Used Assemblers

**asm6** / **asm6f** (Recommended for beginners)
- **Author**: Loopy (asm6), freem (asm6f fork)
- **Why created**: "most other assemblers were either too finicky, had weird syntax, took too much work to set up, or too bug-ridden to be useful"
- **asm6f features** (enhanced fork):
  - Illegal opcode support
  - NES 2.0 header support
  - Symbol files for FCEUX/Mesen/Lua debugging
  - Windows binaries available in releases
- **Use case**: Simple, straightforward syntax; great for learning
- **Source**: https://github.com/freem/asm6f

**CC65**
- **Type**: Portable 6502/65c02/65c816 assembler, linker, AND C compiler
- **Platform**: Cross-platform (Win/Mac/Linux)
- **Use case**: If you want to write in C or need advanced linking capabilities
- **Trade-off**: More setup required, but powerful toolchain
- **Source**: https://cc65.github.io/cc65/

**NESASM (MagicKit)**
- **Authors**: Charles Doty, David Michel, J.H. Van Ornum
- **Variant**: NESASM CE (fork by Alexey Avdyukhin/Cluster) adds NES 2.0 headers, symbol files
- **Use case**: Established tool with long history
- **Note**: "Unofficial MagicKit" by zzo38 includes PPMCK support (music)

**WLA DX**
- **Type**: Portable macro assembler (GB-Z80/Z80/6502/6510/65816)
- **Platform**: Win/Linux/DOS
- **Use case**: If you're targeting multiple retro platforms

### Other Notable Assemblers

- **ACME**: Marco Baye's assembler with macros, local labels (Amiga/DOS/Linux)
- **dasm**: Matthew Dillon's assembler for 6502/6507/6803 etc.
- **Ophis**: Python-based 6502 assembler
- **nescom**: Joel Yliluoma's assembler (C++, based on xa65)

### Selection Criteria

For **ddd-nes** (beginner-friendly, learning focus):
- **Recommendation**: **asm6f**
  - Simple syntax (low learning curve)
  - Symbol file generation (debugging support)
  - NES 2.0 headers (modern format)
  - Active community usage

Alternative if C is needed: **CC65**

---

## 2. Emulators

### Mac-Compatible Options (Primary Target)

**Mesen** ★ Highly Recommended
- **Author**: Sour
- **Platform**: Win32, Linux/.NET (macOS via .NET runtime)
- **Features**: Excellent debugger, high accuracy
- **Use case**: Primary development emulator
- **Source**: https://github.com/SourMesen/Mesen
- **Note**: Considered one of the best debugging emulators

**FCEUX**
- **Authors**: Anthony Giorgio / Mark Doliner
- **Platform**: Win32, macOS, Linux
- **Features**: Mature, widely used, good debugging tools
- **Use case**: Secondary testing emulator
- **Source**: http://fceux.com/web/home.html

**higan**
- **Author**: Near (formerly byuu)
- **Platform**: Win32, FreeBSD, Linux, macOS
- **Features**: Cycle-accurate, high precision
- **Use case**: Accuracy validation
- **Trade-off**: Higher system requirements

**Nintaco**
- **Author**: zeroone
- **Platform**: Java (Windows, Linux, macOS)
- **Features**: Cross-platform via Java, API for automation
- **Use case**: Portable testing, scripting

### Debugging Features to Look For

1. **Breakpoints**: CPU address, memory write/read
2. **Step execution**: Step into/over/out
3. **Memory viewer**: RAM/ROM/PPU/OAM inspection
4. **Trace logging**: Instruction-by-instruction logs
5. **Symbol file support**: Named labels in debugger (asm6f generates these)

### Accuracy Levels

- **Cycle-accurate**: higan, Mesen (PPU/CPU timing precise)
- **High accuracy**: FCEUX, Nestopia UE
- **Good enough for dev**: Most modern emulators

### Emulator Selection Strategy

**For ddd-nes**:
1. **Primary**: Mesen (best debugger, high accuracy)
2. **Secondary**: FCEUX (cross-reference, widely used)
3. **Validation**: Test on real hardware eventually (via flash cart)

---

## 3. Graphics Tools

### General NES Graphics Studios (All-in-one)

**NEXXT** ★ Recommended
- **Author**: FrankenGraphics (continuation of NESST)
- **Features**:
  - Tile/CHR editing
  - Nametable/screen editing
  - Sprite/metasprite editing
  - Palette editing
  - Meta-tiles and collision data
  - Improved workflow and safety features
- **Use case**: Primary graphics tool
- **Source**: https://frankengraphics.itch.io/nexxt

**NES Assets Workshop (NAW)**
- **Author**: Nesrocks
- **Features**:
  - GameMaker-style GUI
  - Photoshop-like toolbox with hotkeys
  - "Overlay" mode (draw sprites on backgrounds)
- **Use case**: Alternative if NEXXT doesn't fit workflow
- **Source**: https://nesrocks.itch.io/naw

**NES Screen Tool (NESST)** (Deprecated, use NEXXT instead)
- **Note**: Original tool by Shiru, now superseded by NEXXT

### Asset Converters (Image to CHR/Nametable)

**I-CHR** (Kasumi)
- Converts PC images/sequences to NES tilesets/nametables
- Can produce ROM displaying graphics
- **Use case**: Import existing artwork

**NesTiler** (Cluster)
- Command-line converter (PC images → pattern tables, nametables, attributes, palettes)
- Handles multiple images with shared palettes
- **Lossy if image exceeds NES limits**
- **Use case**: Build-time asset pipeline
- **Source**: https://github.com/ClusterM/nestiler

**pilbmp2nes.py** (Damian Yerrick)
- Command-line BMP/PNG → tile format converter
- **Use case**: Scripted asset conversion

### Tile (CHR) Editors

**YY-CHR** (Popular in romhacking)
- Visual hex editor for tiles
- Works on assembled ROMs
- Provisional nametable support
- **Use case**: Quick tile edits, ROM inspection

**Nasu** (100 Rabbits)
- Minimalist tile editor
- Quick color selection via hotkeys
- Win/Mac/Linux (via UXN emulator)
- **Use case**: Pixel art focused workflow

### Selection for ddd-nes

**Recommended workflow**:
1. **NEXXT**: Primary graphics studio (CHR, nametables, sprites, palettes)
2. **NesTiler**: Build-time converter (if using external art tools)
3. **YY-CHR**: Quick inspection/tweaking

---

## 4. Audio Tools

### Trackers/Sequencers

**FamiTracker** ★ Most Popular
- Tracker-style music editor
- DMC sample import/export (.wav → .dmc)
- Industry standard for NES music
- **Source**: https://famitracker.org/

**PPMCK** (MML-based)
- Music Macro Language (MML) translator
- Text-based composition
- Includes driver + assembler (unofficial version by zzo38)
- **Use case**: If you prefer text/code-based music

**Nerd Tracker II**
- Alternative tracker
- **Source**: http://nesdev.org/nt2/

**NTRQ / Pulsar / Nijuu** (Neil Baldwin)
- Native NES trackers (run on actual NES hardware)
- NTRQ: Traditional tracker
- Pulsar: LSDJ-style (Game Boy inspired)
- Nijuu: MML assembler
- **Use case**: Compose directly on hardware

### DMC Conversion Tools

- **FamiTracker**: .wav → .dmc (built-in)
- **NSF Live!**: NSF player, can export DMC samples
- **Pin Eight NES Tools**: Command-line encoder/decoder

### Audio Driver Engines

See `Audio drivers` wiki page for runtime music/SFX engines (e.g., FamiTone, GGSound)

### Selection for ddd-nes

**Recommended**:
- **FamiTracker**: Primary music tool (most documentation, community support)
- **FamiTone2/5** (driver): Lightweight playback engine for game
- **Alternative**: PPMCK if text-based workflow preferred

---

## 5. Test ROMs and Validation

### Why Test ROMs Matter

NES hardware has **non-obvious behavior** (PPU timing, sprite 0 hit, scrolling edge cases). Test ROMs validate emulator/hardware accuracy BEFORE integrating features.

### Essential Test ROMs

**CPU Tests**
- **nestest** (kevtris): Comprehensive CPU test
  - Start at $C000, compare with known-good log
  - Best first test for new CPU emulator
  - Log: https://www.qmtpro.com/~nes/misc/nestest.log
- **instr_test_v5** (blargg): Official/unofficial instruction tests
- **cpu_interrupts_v2** (blargg): IRQ/NMI behavior and timing

**PPU Tests**
- **ppu_vbl_nmi** (blargg): VBL flag, NMI timing (1 PPU clock accuracy)
- **ppu_sprite_hit** (blargg): Sprite 0 hit behavior/timing
- **sprite_overflow_tests** (blargg): Sprite overflow flag
- **oam_stress** (blargg): OAM read/write ($2003/$2004)

**APU Tests**
- **apu_test** (blargg): CPU-visible APU behavior
- **blargg_apu_2005.07.30**: Length counters, frame counter, IRQ
- **dmc_tests**: DMC channel behavior

**Integration Tests**
- **sprdma_and_dmc_dma** (blargg): Sprite DMA + DMC DMA cycle stealing

### Test ROM Strategy for ddd-nes

**Discovery Mode workflow**:
1. Identify subsystem to learn (e.g., sprite DMA)
2. Run relevant test ROM on emulator
3. Study test ROM source (if available)
4. Document findings in LEARNINGS.md
5. Build minimal test ROM to validate understanding
6. Apply patterns to main game

**Test ROM archive**: Many ROMs archived at https://github.com/christopherpow/nes-test-roms

---

## 6. Disassemblers and Debugging

### Disassemblers

**da65** (part of CC65 suite)
- Intended for CC65 users (ca65 assembler)
- **Use case**: Reverse-engineering commercial games

**disasm6** (PHP-based)
- NES-oriented disassembler for asm6 syntax
- **Use case**: Generate asm6-compatible source from ROM

**GhidraNes** (Kyle Lacy)
- Ghidra extension for NES
- **Use case**: Advanced reverse-engineering with Ghidra's features

### Selection for ddd-nes

**Not needed initially** (greenfield project, writing from scratch)
**Future use**: Studying commercial game techniques

---

## 7. Compression Tools

**Huffmunch**
- Generic compression for NES/6502
- **Very low RAM requirements** (critical for 2KB NES RAM)
- **Source**: https://github.com/bbbradsmith/huffmunch

**Donut** (JRoatch)
- Fast/efficient CHR compression
- **Use case**: Compress pattern table data

**Compress Tools**
- Multi-algorithm compressor
- Extendable, scriptable
- **Use case**: Experimenting with different algorithms

### Strategy for ddd-nes

**Phase 1** (early dev): No compression (keep it simple)
**Phase 2** (ROM space tight): Evaluate Huffmunch for level data, Donut for CHR

---

## 8. Miscellaneous Tools

**Visual 2A03 / Visual 6502**
- Circuit simulators for 2A03/6502 chips
- **Use case**: Deep-dive understanding of CPU behavior
- **When**: Advanced optimization or curiosity-driven learning

**NEStress** (Flubba)
- Old test ROM (some tests intentionally fail on real hardware)
- **Use case**: Historical reference, not primary validation

**240p Test Suite** (tepples)
- NTSC/PAL display tests, aspect ratio, MDFourier audio
- **Use case**: TV/monitor calibration, capture card testing

---

## 9. Toolchain Selection Summary

### ddd-nes Recommended Stack

| Category | Tool | Reason |
|----------|------|--------|
| **Assembler** | asm6f | Simple syntax, symbol files, NES 2.0 support |
| **Primary Emulator** | Mesen | Best debugger, high accuracy, Mac-compatible |
| **Secondary Emulator** | FCEUX | Cross-reference, widely used |
| **Graphics** | NEXXT | All-in-one studio (CHR, nametables, sprites) |
| **Audio** | FamiTracker | Industry standard, extensive docs |
| **Audio Driver** | FamiTone2/5 | Lightweight playback engine |
| **Test ROMs** | blargg suite | Comprehensive CPU/PPU/APU validation |
| **Disassembler** | (defer) | Not needed for greenfield development |
| **Compression** | Huffmunch/Donut | Low RAM overhead (evaluate later) |

### Workflow Integration

**Development cycle**:
1. Write assembly in **asm6f** (with symbol generation)
2. Test in **Mesen** (use debugger with symbol files)
3. Validate in **FCEUX** (cross-check behavior)
4. Create graphics in **NEXXT** (export CHR/nametables)
5. Compose music in **FamiTracker** (export to FamiTone format)
6. Run **test ROMs** when implementing new subsystems
7. Document learnings in `LEARNINGS.md`

### Build Pipeline (Future)

```bash
# Assemble
asm6f main.asm game.nes -n -s game.dbg

# Convert graphics (if not using NEXXT exports)
nestiler graphics/title.png -o title.chr

# Run automated tests
mesen --run-test nestest.nes --compare nestest.log

# Test on hardware
# (flash to everdrive/powerpak)
```

---

## 10. Platform-Specific Notes

### macOS Development

**Emulators**:
- Mesen: Via .NET runtime (or use Windows version in Wine/Parallels)
- FCEUX: Native macOS build
- Nintaco: Java (cross-platform)

**Graphics Tools**:
- NEXXT: Check if Wine/Parallels needed (Windows-only)
- Alternative: Use browser-based tools if available

**Build Tools**:
- asm6f: Compile from source (C-based, portable)
- CC65: Homebrew available (`brew install cc65`)

### Windows Development

All tools have native Windows support.

### Linux Development

Most tools support Linux (asm6f, Mesen, FCEUX, NEXXT, CC65).

---

## 11. Test ROM Validation Strategy

### Automated Testing (from Emulator_tests.html)

**Concept**:
1. Record "movie" (button presses) while running test ROM
2. Take screenshots at key frames
3. Hash screenshots and log results
4. Re-run movie in fast-forward, compare hashes
5. Flag differences for review

**Tools supporting movies**:
- Mesen: TAS movie support
- FCEUX: .fm2 movie format
- BizHawk: Multi-system movie support

**Use case for ddd-nes**:
- Automate regression testing (ensure changes don't break old features)
- Record gameplay demos for documentation

---

## 12. Key Learnings and Constraints

### Assembler Constraints

- **asm6**: Simple but lacks some advanced features
- **CC65**: Powerful but more complex setup
- **Symbol files**: Critical for debugging (asm6f generates them)

### Emulator Constraints

- **Accuracy vs. speed**: Cycle-accurate emulators are slower
- **Debugger features**: Not all emulators have equal debugging tools
- **Platform support**: Check macOS compatibility (some are Windows-only)

### Graphics Constraints

- **NES palette**: 52 colors (4 palettes of 3 colors + backdrop)
- **Tile limits**: 256 tiles in pattern table (8KB CHR-ROM)
- **Attribute table**: 2x2 tile color groups (can't color individual tiles)
- **Sprite limits**: 8 sprites per scanline, 64 total

### Audio Constraints

- **5 channels**: 2 pulse, 1 triangle, 1 noise, 1 DMC
- **Expansion audio**: Only on Famicom (not NES) without mapper support
- **DMC samples**: Eat CPU cycles during playback

### Test ROM Constraints

- **Many ROMs need emulator fixes**: Not all emulators pass all tests
- **Hardware differences**: Some tests fail on certain console revisions
- **Test coverage**: No single ROM tests everything

---

## 13. Next Steps

### Immediate Actions

1. **Install asm6f**: Download from GitHub, compile/build
2. **Install Mesen**: Set up debugger, test with nestest.nes
3. **Download NEXXT**: Explore CHR/nametable editing
4. **Download FamiTracker**: Experiment with basic melodies
5. **Archive test ROMs**: Download blargg suite to `.webcache/test-roms/`

### Learning Priorities

1. **Assembler**: Write "Hello World" (display text on screen)
2. **Graphics**: Create simple CHR tiles, load into pattern table
3. **Test ROM**: Run nestest.nes, understand log format
4. **Audio**: Create simple beep/bloop sounds

### Documentation Updates

- Update `CODE_MAP.md` with tool paths and build commands
- Document assembler syntax patterns in `LEARNINGS.md`
- Create `TOOLS.md` for detailed tool usage notes

---

## References

- **asm6f**: https://github.com/freem/asm6f
- **Mesen**: https://www.mesen.ca/
- **NEXXT**: https://frankengraphics.itch.io/nexxt
- **FamiTracker**: https://famitracker.org/
- **Test ROM archive**: https://github.com/christopherpow/nes-test-roms

---

## Attribution

This document synthesizes information from the following NESdev Wiki pages:

- [Tools](https://www.nesdev.org/wiki/Tools)
- [Emulators](https://www.nesdev.org/wiki/Emulators)
- [Emulator_tests](https://www.nesdev.org/wiki/Emulator_tests)

