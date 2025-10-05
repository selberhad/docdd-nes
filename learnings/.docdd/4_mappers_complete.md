# Phase 4 — Mappers Study Complete (All Core Priorities Done!)

**Date**: October 2025
**Phase**: Priority 5 (Mappers) complete
**Status**: All core study priorities complete - ready for practical work

---

## What We Studied

### Priority 5: Mappers (4 pages)
**Documented in**: `learnings/mappers.md`

- Programming_mappers - Overview of mapper progression
- CHR-ROM_vs_CHR-RAM - Critical design decision (speed vs flexibility)
- Programming_UNROM - Simple bank switching with bus conflicts
- Programming_MMC1 - Nintendo's first ASIC mapper with serial protocol

---

## Key Insights Gained

### Mappers Solve ROM Size Limits

**Base NES** (NROM - Mapper 0):
- 32KB PRG-ROM max ($8000-$FFFF)
- 8KB CHR-ROM/RAM max ($0000-$1FFF in PPU space)

**Problem**: Complex games need more (Super Mario Bros. 3 = 384KB PRG)

**Solution**: Mappers add **bank switching** hardware to cartridge.

### CHR-ROM vs CHR-RAM is a Critical Early Decision

**CHR-ROM** (Fixed tiles, bank switched):
- **Advantages**: Instant switching, mid-frame changes, simpler init
- **Use cases**: Action games, platformers, shooters with pre-made tilesets
- **Examples**: Super Mario Bros. 3 (status bar separation), Smash TV (large title screens)

**CHR-RAM** (CPU-writable tiles):
- **Advantages**: Fine-grained control, compression, runtime generation (VWF, compositing)
- **Use cases**: RPGs, puzzle games, anything needing text/dynamic graphics
- **Cost**: Requires vblank time (~160 bytes/frame = 10 tiles)
- **Examples**: Final Fantasy, Elite (vector graphics), Cocoron (compositing)

**Decision rule**:
- CHR-ROM if you have pre-made tilesets and need speed
- CHR-RAM if you need flexibility, compression, or runtime tile generation

### UNROM = Beginner-Friendly Bank Switching

**Specs**:
- 64KB-256KB PRG-ROM (16KB switchable at $8000, 16KB fixed at $C000)
- 8KB CHR-RAM (must be loaded by CPU)

**Programming model**:
```asm
banktable: .byte $00, $01, $02, $03, $04, $05, $06, $07

bankswitch_y:
  sty current_bank
  tya
  sta banktable, y  ; read from table, write same value (bus conflict workaround)
  rts
```

**Key pattern**: Fixed bank ($C000-$FFFF) contains vectors, reset code, NMI/IRQ handlers, bankswitch routine.

**Bus conflict gotcha**: Discrete logic means CPU and ROM both drive bus. **Must write value that matches ROM contents** (hence lookup table).

### MMC1 = More Powerful but More Complex

**Specs**:
- Up to 512KB PRG-ROM (three banking modes: fixed $C000, fixed $8000, 32KB)
- CHR-ROM (up to 128KB, 4KB/8KB banks) or CHR-RAM (8KB)
- Mirroring control (horizontal, vertical, one-screen)
- PRG-RAM support (8KB-32KB for save games)

**Serial protocol** (5-bit shift register):
```asm
lda #$0E      ; vertical mirroring, fixed $C000, 8KB CHR
sta $8000     ; write bit 0
lsr a
sta $8000     ; write bit 1
lsr a
sta $8000     ; write bit 2
lsr a
sta $8000     ; write bit 3
lsr a
sta $8000     ; write bit 4 (completes write)
```

**Interrupt safety problem**: If NMI/IRQ interrupts mid-write, mapper state corrupts.

**Solutions**:
1. **Retry flag**: Clear flag before writes, check after, retry if interrupted
2. **Save/restore + reset**: Reset mapper ($8000 = $80) before every write

**Power-on quirk**: Some MMC1 revisions don't guarantee fixed-$C000 at power-on.

**Workaround**: Put reset stub at end of every 16KB bank:
```asm
reset_stub:
  sei
  ldx #$FF
  txs
  stx $8000   ; reset mapper
  jmp reset   ; jump to actual init in $C000+

.addr nmiHandler, reset_stub, irqHandler  ; at $xFFA-$xFFF
```

### Fixed Bank Strategy (Universal Pattern)

**Fixed bank** contains:
- Interrupt vectors (NMI, RESET, IRQ)
- Reset/init code
- Bankswitch routine
- Common subroutines (controller read, OAM DMA, etc.)

**Switchable banks** contain:
- Level data
- Enemy logic
- Menu screens
- Compressed graphics (for CHR-RAM)

**Critical rule**: Never `jsr` between fixed and switchable banks without restoring bank.

### Converting NROM → CHR-RAM (Migration Path)

1. Check PRG space (need 8300+ bytes free for CHR data)
2. Remove CHR-ROM from build
3. Update iNES header (CHR banks = 0)
4. Add CHR copy routine (in init, before PPU on)
5. Rebuild (should be 32,784 bytes = 16 header + 32,768 PRG)

**Note**: NROM board physically expects CHR-ROM chip. For CHR-RAM, use BNROM (iNES Mapper 34) or rewire.

---

## Questions Raised

### Mapper Selection for docdd-nes

1. **Which mapper for this project?**
   - **NROM**: Start here (simple, fast iteration)
   - **UNROM**: Migrate when >32KB PRG needed
   - **MMC1**: Only if we need CHR-ROM switching or PRG-RAM
   - Decision pending until we know game size requirements

2. **CHR-ROM or CHR-RAM?**
   - Depends on game genre/mechanics
   - If text-heavy or RPG-style: CHR-RAM
   - If action/platformer: CHR-ROM
   - Can prototype with NROM + CHR-ROM, migrate to CHR-RAM later

3. **When to switch mappers?**
   - Start NROM for prototyping
   - Migrate to UNROM when ROM size exceeds 32KB
   - Only use MMC1 if we need advanced features (CHR switching, PRG-RAM)

### Practical Implementation Questions

4. **How to handle bus conflicts in practice?**
   - UNROM: Always use lookup table pattern
   - Test on emulator first, then real hardware
   - Document banktable layout in CODE_MAP.md

5. **MMC1 interrupt safety - which solution?**
   - **Retry flag**: More complex, handles all cases
   - **Reset + save/restore**: Simpler, forces fixed-$C000 mode
   - Decision: Start with reset+save (simpler), switch to retry if needed

6. **Multi-bank init code?**
   - MMC1 power-on quirk requires reset stub in all banks
   - UNROM doesn't need this (fixed bank at power-on is guaranteed)
   - Build system needs to duplicate reset stub to all banks (MMC1 only)

### Testing & Validation

7. **How to test bank switching?**
   - Build test ROM with code in each bank
   - Print bank number to screen
   - Validate all banks accessible
   - Test NMI/IRQ during bankswitch (MMC1)

8. **CHR-RAM copy performance?**
   - Theory: 10 tiles/frame (160 bytes)
   - Need to measure actual cycle cost
   - May need double-buffering for large updates

9. **Donor cart compatibility?**
   - UNROM: Common (Mega Man, Castlevania, Metal Gear)
   - MMC1: Very common (Metroid, Zelda, Kid Icarus)
   - CHR-RAM boards less common (need to check availability)

---

## Decisions Made

### Mapper Progression Strategy

**Phase 1**: NROM (Mapper 0)
- Use for initial prototyping and test ROMs
- 32KB PRG + 8KB CHR (ROM or RAM)
- No bank switching complexity
- **Switch to Phase 2 when**: ROM size >32KB or need CHR switching

**Phase 2**: UNROM (Mapper 2)
- Migrate when NROM too small
- Simple bank switching (lookup table pattern)
- CHR-RAM for dynamic graphics
- **Switch to Phase 3 when**: Need CHR-ROM switching or PRG-RAM

**Phase 3**: MMC1 (Mapper 1) — Only if needed
- Use only if UNROM insufficient
- Serial protocol + interrupt safety
- CHR-ROM bank switching capability
- PRG-RAM for save games

**Decision**: Start with NROM, migrate as needed. Don't prematurely optimize for larger mapper.

### CHR Strategy (Pending Game Design)

**If action/platformer**:
- Use CHR-ROM for instant tile switching
- Pre-bake all graphics in ROM
- Fast, simple programming model

**If RPG/puzzle/text-heavy**:
- Use CHR-RAM for flexibility
- Compress tile data in PRG-ROM
- Enables VWF, compositing, dynamic graphics

**Decision deferred**: Wait for SPEC.md to define game genre.

### Build System Requirements

**NROM build**:
- Simple `.incbin` for CHR-ROM
- Or CHR-RAM copy routine for CHR-RAM variant

**UNROM build**:
- Link all PRG banks into single ROM
- Last bank duplicated to fixed position
- Bus conflict lookup table in fixed bank

**MMC1 build**:
- All PRG banks linked
- Reset stub duplicated to end of each bank
- Serial protocol routines in fixed bank

**Decision**: Start with NROM build script, extend to UNROM when needed.

---

## Study Progress Summary

**Wiki Pages Studied**: 52/100+ (52%)
- Priority 1: Getting Started (7 pages) ✅
- Priority 2: Essential Techniques (14 pages) ✅
- Priority 2.5: Toolchain (3 pages) ✅
- Priority 3: Programming Techniques (19 pages) ✅
- Priority 4: Audio (5 pages) ✅
- Priority 5: Mappers (4 pages) ✅
- **Total: 52 pages**

**Learnings Documents Created**: 11
1. `wiki_architecture.md` - Core NES architecture
2. `getting_started.md` - Initialization, registers, limitations
3. `sprite_techniques.md` - Sprite management patterns
4. `graphics_techniques.md` - Video, terrain, palettes
5. `input_handling.md` - Controller reading, accessories
6. `timing_and_interrupts.md` - Cycle budgeting, NMI handlers
7. `toolchain.md` - Tool selection and setup
8. `optimization.md` - 6502 optimization techniques
9. `math_routines.md` - Math implementations
10. `audio.md` - APU programming, sound engines, music drivers
11. `mappers.md` - **NEW**: Bank switching, CHR-ROM vs CHR-RAM, UNROM/MMC1

**Meta-Learnings Documents**: 5
1. `0_initial_questions.md` - Original learning questions
2. `1_essential_techniques.md` - After Priority 1-2
3. `2_toolchain_optimization.md` - After Priority 2.5-3
4. `3_audio_complete.md` - After Priority 4
5. `4_mappers_complete.md` - **NEW**: After Priority 5 (this document)

**Remaining Priorities**:
- Reference: ~40+ pages (file formats, emulation, platform variants)
- Not critical for practical work (can study as-needed)

---

## What We Can Build Now

**All core NES development knowledge acquired!** No major knowledge gaps for basic-to-intermediate NES game development.

### Test ROMs (Discovery Mode)
1. **Hello World**: Sprite, controller, beep (NROM)
2. **Bank Switch Test**: Validate UNROM/MMC1 bank switching
3. **CHR-RAM Test**: Measure tile copy performance, validate vblank budget
4. **Audio Test**: FamiTone2 integration, SFX priority
5. **Full Integration**: All subsystems working together

### Game Prototypes (Execution Mode)
With current knowledge, can build:
1. **NROM game** (≤32KB):
   - Single-screen puzzle game
   - Simple platformer (small levels)
   - Arcade-style shooter

2. **UNROM game** (≤256KB):
   - Multi-level platformer
   - Action-adventure (Zelda-style)
   - Vertical/horizontal shooter

3. **MMC1 game** (≤512KB):
   - Large RPG with save system
   - Multi-world platformer (SMB3-style)
   - Complex adventure game

**No more blockers for practical work!**

---

## Next Steps

### Option A: Begin Practical Work (RECOMMENDED)

**Why**: All core knowledge acquired. Best to validate through practice before forgetting theory.

**Steps**:
1. **Toolchain installation**:
   - Install asm6f assembler
   - Install Mesen emulator (Mac .NET version)
   - Download blargg test ROM suite
   - Install NEXXT (graphics editor)
   - Install FamiTracker (or FamiStudio)

2. **Build "hello world" test ROM**:
   - NROM mapper
   - Display sprite
   - Read controller
   - Play beep on button press
   - Validate learnings through practice

3. **Systematic test ROM development**:
   - One test ROM per subsystem
   - Measure actual cycle costs (compare to theory)
   - Update learning docs with real measurements
   - Document edge cases discovered

4. **Begin game development**:
   - Define game in SPEC.md
   - Choose mapper based on requirements
   - Implement game logic
   - Iterate with test ROMs as needed

### Option B: Continue Reference Study

**Why**: Complete wiki coverage for comprehensive reference material.

**Targets**:
- File formats (iNES, NES 2.0, NSF, UNIF)
- Emulation details (game bugs, tricky-to-emulate games)
- Platform variants (Famicom, FDS, Vs. System)

**Estimated time**: ~2-3 weeks of study

**Value**: Comprehensive reference, but not blocking for practical work.

### Option C: Deep Dive on Specific Topic

**Why**: Address specific knowledge gap before practical work.

**Candidates**:
- More PPU techniques (raster effects, scrolling edge cases)
- Compression (if ROM space becomes concern)
- Advanced mappers (MMC3, MMC5) if needed

---

## Recommendation

**Begin practical work (Option A)**.

**Rationale**:
1. **All core knowledge acquired** - no major gaps for basic game development
2. **Validate through practice** - test ROMs will reveal gaps in understanding
3. **Avoid knowledge decay** - theory learned but not applied is quickly forgotten
4. **Iterative learning** - discover what we need as we build
5. **Reference study can be async** - study file formats/emulation details as needed

**Next concrete actions**:
1. Install toolchain (asm6f, Mesen, NEXXT, FamiTracker)
2. Build "hello world" NROM test ROM
3. Validate learnings (measure actual cycle costs, test edge cases)
4. Update learning docs with practical findings
5. Define game in SPEC.md (genre, mechanics, scope)
6. Choose mapper based on game requirements
7. Begin game development

**Goal**: Complete solid reference material (✅ DONE), validate through practice, collaborate with NESHacker with practical experience.

---

## Mapper-Specific Implementation Checklist (For Future Use)

### NROM Implementation
- [ ] Create iNES header (32KB PRG, 8KB CHR)
  - **Theory**: `learnings/mappers.md` - Header format documented
- [x] Choose CHR-ROM or CHR-RAM
  - **Decision**: Pending SPEC.md (game genre) → **See `5_open_questions.md` Q5.2**
- [ ] If CHR-RAM: Add tile copy routine to init code
  - **Theory**: `learnings/mappers.md` - CHR copy code example provided
- [ ] Place vectors at $FFFA-$FFFF
  - **Theory**: `learnings/getting_started.md` - Vector locations documented
- [ ] Build and test on emulator
  - → **See `5_open_questions.md` Q1.1-Q1.3** (build + debug workflow)

### UNROM Implementation
- [ ] Create iNES header (64KB-256KB PRG, 0 CHR = CHR-RAM)
  - **Theory**: `learnings/mappers.md` - UNROM header example provided
- [ ] Create bus conflict lookup table in fixed bank
  - **Theory**: `learnings/mappers.md` - banktable pattern documented
  - → **See `5_open_questions.md` Q5.4**
- [ ] Implement bankswitch_y routine in fixed bank
  - **Theory**: `learnings/mappers.md` - bankswitch_y code provided
- [ ] Place common code (vectors, NMI, IRQ, utils) in fixed bank
  - **Theory**: `learnings/mappers.md` - Fixed bank strategy documented
  - → **See `5_open_questions.md` Q5.5**
- [ ] Organize switchable banks (levels, logic, data)
- [ ] Test bank switching (all banks accessible)
  - → **See `5_open_questions.md` Q7.1**
- [ ] Add CHR-RAM tile copy routine
  - **Theory**: `learnings/mappers.md` - CHR copy routine provided

### MMC1 Implementation
- [ ] Create iNES header with proper submapper/PRG-RAM settings
  - **Theory**: `learnings/mappers.md` - MMC1 header format documented
- [ ] Implement 5-write serial protocol routine
  - **Theory**: `learnings/mappers.md` - Serial protocol code provided
- [x] Choose interrupt safety strategy (retry flag or reset+save)
  - **Decision**: Reset+save (simpler) → **See `5_open_questions.md` Q5.6**
- [ ] Add reset stub to end of all 16KB banks
  - **Theory**: `learnings/mappers.md` - reset_stub code provided
- [ ] Configure mapper mode in init (fixed $C000, mirroring, CHR mode)
  - **Theory**: `learnings/mappers.md` - Quick setup code provided
- [ ] Implement PRG bank switching
  - **Theory**: `learnings/mappers.md` - mmc1_load_prg_bank routine provided
- [ ] If CHR-ROM: Implement CHR bank switching
  - **Theory**: `learnings/mappers.md` - MMC1 CHR banking documented
- [ ] Test interrupt safety (bank switch during NMI)
  - → **See `5_open_questions.md` Q7.1**
- [ ] Validate on multiple emulators (MMC1 revision differences)
  - Test on Mesen, FCEUX, Nintendulator

---

**Status**: Ready for practical work. All core priorities complete. 🎮
