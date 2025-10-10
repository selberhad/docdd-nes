# PHASE 4 — Audio Programming Complete

**Date**: October 2025
**Phase**: Priority 4 (Audio) complete
**Status**: Ready for mappers study (Priority 5), then practical work

---

## What We Studied

### Priority 4: Audio (5 pages)
**Documented in**: `learnings/audio.md`

- APU_basics - Channel architecture, register map, initialization
- APU_period_table - Note/frequency mapping, NTSC period values
- Audio_drivers - Sound engine comparison (8 engines analyzed)
- Nerdy_Nights_sound - Practical sound programming tutorial
- Music - Music formats, drivers, NSF files

---

## Key Insights Gained

### APU Architecture
1. **5 channels**: 2 pulse (50% duty sweep), 1 triangle (no volume), 1 noise (percussion), 1 DMC (samples)
2. **Register map**: $4000-$400F for audio, $4015 for channel enable/status
3. **No DMA**: Unlike sprites, audio registers must be written directly (but fast - 1-4 bytes per channel)

### Channel Capabilities & Limitations
1. **Pulse waves**:
   - 4 duty cycles: 12.5%, 25%, 50%, 75%
   - Volume control (16 levels)
   - Sweep hardware (pitch bends)
   - Best for melody, harmony

2. **Triangle wave**:
   - **NO volume control** (only mute/unmute)
   - Plays **1 octave lower** than pulse for same period value
   - Silent or full volume only
   - Best for bass lines

3. **Noise channel**:
   - Tone mode vs noise mode (bit 7 of $400E)
   - 16 period values (not chromatic)
   - Best for drums, percussion, explosions

4. **DMC (samples)**:
   - 7-bit samples (64 levels)
   - Steals CPU cycles during playback (can glitch controller reads)
   - Expensive (ROM space + cycle cost)
   - Best for voice, drums when needed

### Period Table Mathematics
1. **Formula**: `period = CPU_frequency / (16 * desired_frequency) - 1`
2. **NTSC CPU**: 1.789773 MHz
3. **Example**: 400 Hz tone → period = $01BE (446 decimal)
4. **Note range**: A0 (27.5 Hz) to B7 (3951 Hz) covers 80 notes
5. **Storage**: 160 bytes (80 notes × 2 bytes per period value)

### Sound Engine Selection
**8 engines analyzed** - key decision factors:

| Engine | ROM | RAM | Cycles | Best For |
|--------|-----|-----|--------|----------|
| FamiTone2 | 1636 | 186 | 1200-1500 | **Beginners** (simple, proven) |
| FamiStudio | Med | Med | 1500-2500 | **Rich features** (expansion audio) |
| Pently | Small | Small | 1500-2000 | **Size optimization** (configurable) |
| Penguin | Small | Small | **790** | **Raster effects** (constant cycles) |
| GGSound | 2KB | Med | Variable | **Expressive music** (128 instruments) |
| NSD.Lib | Med | Med | Variable | **MML workflow** (text-based composition) |

**Recommendation for ddd-nes**: Start with **FamiTone2**
- Well-documented
- FamiTracker integration (industry standard)
- Predictable cycle cost
- Proven in hundreds of games

### Music/SFX Integration Patterns
1. **60 Hz update**: Call sound engine once per frame (in NMI or main loop)
2. **SFX priority strategies**:
   - **Priority by channel**: SFX on pulse 2, music on pulse 1/triangle
   - **Priority by type**: Important SFX interrupt music, ambient SFX co-exist
   - **Ducking**: Reduce music volume when SFX plays
3. **Cycle budget**: Reserve 500-1500 cycles per frame (depends on engine + PPU needs)

### Common Pitfalls (Documented)
1. **Phase reset on $4003/$4007 write**: Causes audible pop during vibrato
   - Workaround: Only write duty/volume/period, avoid $4003/$4007 unless starting new note
2. **Triangle mute with period=0**: Causes pop
   - Workaround: Use mute flag (bit 7 of $4008) instead
3. **DMC stealing CPU cycles**: Can glitch controller reads
   - Workaround: Disable DMC IRQ ($4017 bit 6), read controller multiple times

---

## Questions Raised

### Music Workflow
1. **Composition tool**: FamiTracker vs FamiStudio vs other?
   - FamiTracker: Classic, well-documented, widely used
   - FamiStudio: Modern, better UI, expansion audio
   - Decision pending - try both?

2. **Music data format**: Which sound engine to integrate?
   - FamiTone2 recommended for start
   - Can switch later if needed
   - Need to understand data export workflow

3. **Asset build integration**: How to convert FamiTracker → game data?
   - text2data tool (FamiTone2)
   - Include in build pipeline
   - Auto-convert on music file change?

### Audio Implementation Strategy
4. **When to implement audio**: Now or after test ROMs?
   - Could do simple beep/bloop in test ROM
   - Full music integration for game
   - SFX vs music priority?

5. **Cycle budget allocation**: How much vblank for audio?
   - Penguin: 790 constant (safe for tight budgets)
   - FamiTone2: 1200-1500 variable
   - Need to profile actual usage

6. **NSF integration**: Use NSF files or direct engine integration?
   - NSF = separate player, not game code
   - Direct integration = smaller, faster
   - Use NSF for testing, direct for game

---

## Decisions Made

### Sound Engine Choice
- **Primary**: FamiTone2 (start here)
- **Reason**: Beginner-friendly, well-documented, predictable
- **Alternative**: FamiStudio if expansion audio or rich features needed later

### Music Tool Choice (Pending Installation)
- **Composition**: FamiTracker (industry standard)
- **Alternative**: FamiStudio (modern, better UI)
- **Decision**: Try FamiTracker first, evaluate FamiStudio if limitations hit

### Audio Budget Allocation
- **Target**: 1000-1500 cycles per frame for FamiTone2
- **Vblank breakdown**:
  - OAM DMA: 513-514 cycles (mandatory)
  - Scroll updates: ~50-100 cycles
  - VRAM streaming: ~500-1000 cycles (varies)
  - **Music/SFX**: ~1000-1500 cycles
  - Remaining: game logic during rendering

---

## Study Progress Summary

**Wiki Pages Studied**: 48/100+ (48%)
- Priority 1: Getting Started (7 pages) ✅
- Priority 2: Essential Techniques (14 pages) ✅
- Priority 2.5: Toolchain (3 pages) ✅
- Priority 3: Programming Techniques (19 pages) ✅
- Priority 4: Audio (5 pages) ✅
- **Total: 48 pages**

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
10. `audio.md` - **NEW**: APU programming, sound engines, music drivers
11. `README.md` - Navigation and index

**Remaining Priorities**:
- Priority 5: Mappers (4 pages) - UNROM, MMC1, CHR-RAM
- Reference: ~40+ pages (file formats, emulation, platform variants)

---

## What We Can Build Now

With audio knowledge added, we can create:

### Test ROMs (Discovery Mode)
1. **Hello World**: Display sprite, read controller, **play beep on button press**
2. **Audio Test**: Test each APU channel, period table validation
3. **Music Test**: Integrate FamiTone2, play simple tune
4. **SFX Test**: Trigger sound effects, test priority/mixing

### Simple Game Prototypes
Now can add to previous capabilities:
1. **Audio feedback**: Button press beeps, collision sounds
2. **Background music**: Simple looping track
3. **Sound effects**: Jump, shoot, item collect, enemy hit

**No more major knowledge gaps** for basic NES game development!

---

## Next Steps

### Option A: Complete Mappers Study (Priority 5) - RECOMMENDED
**Why**: Round out all core NES knowledge before practical work
1. Study 4 mapper pages (Programming_mappers, UNROM, MMC1, CHR-RAM)
2. Create `learnings/mappers.md`
3. **Then start practical work** with complete reference material

### Option B: Start Practical Work Now
**Why**: Enough knowledge to build NROM games (32KB PRG + 8KB CHR)
1. Install toolchain (asm6f, Mesen, NEXXT, FamiTracker)
2. Build "hello world" test ROM
3. Validate learnings through practice
4. Study mappers later if ROM size exceeded

### Option C: Focus on Specific Gap
**Why**: Deep dive on one subsystem before practice
1. More PPU techniques (scrolling edge cases, raster effects)
2. More optimization (for specific bottlenecks)
3. Compression (if ROM space becomes concern)

---

## Recommendation

**Complete Priority 5 (Mappers)** next - only 4 pages remaining. Better to have complete core reference before switching contexts. Mappers affect ROM layout decisions from the start.

After Priority 5:
- **PHASE_5.md** meta-learnings
- Toolchain installation & setup
- First test ROM ("hello world" with sprite, controller, beep)
- Systematic test ROM development (one subsystem per ROM)

The goal remains: **Complete, solid reference material before NESHacker collaboration**.

---

## Audio-Specific Checklist (For Future Implementation)

When implementing audio:
- [x] Choose composition tool (FamiTracker or FamiStudio)
  - **Decision**: FamiTracker (industry standard), try FamiStudio if needed
  - → **See `5_open_questions.md` Q3.4**
- [ ] Install tool and learn basics
  - → **See `5_open_questions.md` Q3.4**
- [ ] Integrate FamiTone2 library into codebase
  - → **See `5_open_questions.md` Q3.1**
- [ ] Set up music data build pipeline (FamiTracker → text2data → .asm)
  - → **See `5_open_questions.md` Q3.5**
- [ ] Implement 60 Hz sound engine call (NMI or main loop)
  - **Theory**: `learnings/audio.md` - Call once per frame
  - → **See `5_open_questions.md` Q3.6** (when to implement)
- [ ] Create SFX trigger interface (sound_play(sfx_id))
  - **Theory**: `learnings/audio.md` - Trigger function documented
  - → **See `5_open_questions.md` Q3.2** (priority/mixing)
- [ ] Test on emulator with audio debugging
  - Use Mesen audio viewer
- [ ] Profile cycle cost (ensure within budget)
  - **Target**: 1000-1500 cycles/frame (FamiTone2)
  - → **See `5_open_questions.md` Q3.3**
- [ ] Test SFX priority/mixing
  - → **See `5_open_questions.md` Q3.2**
- [ ] Document actual cycle measurements in audio.md
  - Update learning doc with real measurements
