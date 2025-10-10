# NES Development Learnings

This directory contains extracted technical knowledge from NESdev Wiki pages, organized into actionable implementation patterns.

---

## Documentation Practices

### Learning Documents
Located at root of `learnings/` directory. Each document:
- **Focuses on practical patterns** extracted from cached wiki pages
- **Includes code snippets** with cycle counts and timing constraints
- **Documents gotchas and pitfalls** to avoid
- **Ends with Attribution section** linking to source NESdev wiki pages

### Meta-Learnings (`.ddd/` subdirectory)
Located in `learnings/.ddd/`. These document **our learning process**:
- **INITIAL.md** - Original questions we needed to answer
- **PHASE_2.md** - Progress assessment after Priority 1-2 (core techniques)
- **PHASE_3.md** - Progress assessment after Priority 2.5-3 (toolchain + optimization)
- **PHASE_N.md** - Future phase assessments after each priority group

**Practice**: After completing each priority group in STUDY_PLAN.md, create a PHASE_N.md documenting:
- What we studied
- Key insights gained
- Questions raised
- Decisions made/pending
- Study progress summary
- Recommended next steps

### Attribution
Every learning document includes attribution footer added via `tools/add-attribution.pl`:

```markdown
---

## Attribution

This document synthesizes information from the following NESdev Wiki pages:

- [PageName](https://www.nesdev.org/wiki/PageName)
- [AnotherPage](https://www.nesdev.org/wiki/AnotherPage)
```

**Why**: Proper credit to NESdev wiki, clickable links from GitHub, suitable for future mdbook compilation.

**Usage**: After creating/updating a learning doc:
```bash
tools/add-attribution.pl learnings/new_doc.md
```

---

## Learning Documents (Current)

### Core Architecture (Priority 1)
- **[wiki_architecture.md](wiki_architecture.md)** - NES system overview (CPU, PPU, APU, memory map, timing)
- **[getting_started.md](getting_started.md)** - Initialization, registers, RAM layout, hardware limitations

### Essential Techniques (Priority 2)
- **[sprite_techniques.md](sprite_techniques.md)** - Sprite evaluation, OAM management, sprite 0 hit, cel streaming
- **[graphics_techniques.md](graphics_techniques.md)** - Video standard detection, terrain rendering, palette changes
- **[input_handling.md](input_handling.md)** - Controller reading, edge detection, accessories, platform differences
- **[timing_and_interrupts.md](timing_and_interrupts.md)** - Cycle budgeting, NMI handlers, interrupt forwarding

### Development Tools (Priority 2.5)
- **[toolchain.md](toolchain.md)** - Assembler/emulator selection, graphics/audio tools, test ROMs

### Programming Techniques (Priority 3)
- **[optimization.md](optimization.md)** - 6502 optimization patterns, cycle/byte trade-offs, unofficial opcodes
- **[math_routines.md](math_routines.md)** - Multiply, divide, BCD conversion, RNG implementations

### Audio (Priority 4)
- **[audio.md](audio.md)** - APU programming, sound engines, music drivers, cycle budgets

### Mappers (Priority 5)
- **[mappers.md](mappers.md)** - Bank switching, CHR-ROM vs CHR-RAM, UNROM/MMC1 programming

---

## How to Use These Docs

### During Study Phase (Now)
1. **Systematic wiki reading** per STUDY_PLAN.md priorities
2. **Extract to learning docs** (practical patterns, code, constraints)
3. **Record meta-learnings** in `.ddd/PHASE_N.md` after each priority group
4. **Add attribution** via `tools/add-attribution.pl`

### During Discovery Mode (Test ROMs)
1. **Before building test ROM**: Read relevant learning doc to understand constraints
2. **Define questions**: What assumptions are we testing? (LEARNINGS.md style from DDD.md)
3. **Build test ROM**: Validate techniques from learning docs
4. **Document findings**: Update learning doc with actual measurements, edge cases

### During Execution Mode (Building Game)
1. **Reference learning docs**: Use code patterns as templates
2. **Check cycle budgets**: Ensure vblank budget isn't exceeded
3. **Apply gotcha workarounds**: Avoid documented pitfalls
4. **Update docs**: When discovering new patterns or edge cases

---

## Wiki Page Mapping

Each learning doc synthesizes information from multiple cached wiki pages. See Attribution section at bottom of each doc for exact source pages.

### Priority 1 (Core - 7 pages)
- Before_the_basics, Programming_Basics, Init_code, Registers, PPU_power_up_state, Sample_RAM_map, Limitations
- **Docs created**: wiki_architecture.md, getting_started.md

### Priority 2 (Essential Techniques - 14 pages)
- PPU_sprite_evaluation, Sprite_size, Detecting_video_standard, Placeholder_graphics, Drawing_terrain, Palette_change_mid_frame, Sprite_cel_streaming, Don't_hardcode_OAM_addresses, Controller_reading_code, Input_devices, Cycle_reference_chart, Cycle_counting, NMI_thread, Interrupt_forwarding
- **Docs created**: sprite_techniques.md, graphics_techniques.md, input_handling.md, timing_and_interrupts.md

### Priority 2.5 (Toolchain - 3 pages)
- Tools, Emulators, Emulator_tests
- **Docs created**: toolchain.md

### Priority 3 (Programming Techniques - 19 pages)
- 6502_assembly_optimisations, RTS_Trick, Jump_Table, Scanning_Tables, Scanning_Large_Tables, Synthetic_Instructions, Programming_with_unofficial_opcodes, Pointer_table, Multibyte_constant, Multiplication_by_a_constant_integer, Fast_signed_multiply, 8-bit_Multiply, 8-bit_Divide, Division_by_a_constant_integer, Divide_by_3, 16-bit_BCD, Base_100, Random_number_generator, Compression, Fixed_Bit_Length_Encoding
- **Docs created**: optimization.md, math_routines.md

### Priority 4 (Audio - 5 pages)
- APU_basics, APU_period_table, Audio_drivers, Nerdy_Nights_sound, Music
- **Docs created**: audio.md

### Priority 5 (Mappers - 4 pages)
- Programming_mappers, Programming_UNROM, Programming_MMC1, CHR-ROM_vs_CHR-RAM
- **Docs created**: mappers.md

---

## Key Constraints (Always Remember)

### Timing
- **VBlank budget**: 2273 CPU cycles (NTSC), 2660 cycles (PAL)
- **OAM DMA**: 513-514 cycles (must happen in vblank)
- **Frame rate**: 60.0988 FPS (NTSC), 50.007 FPS (PAL)
- **PAL timing**: 20% slower CPU - detect video standard and compensate

### Graphics
- **Sprite limit**: 8 sprites per scanline (hardware limit, cannot exceed)
- **Sprite count**: 64 total sprites in OAM
- **Pattern tables**: 256 tiles each (left $0000-$0FFF, right $1000-$1FFF)
- **Palette memory**: 32 bytes, 4 BG + 4 sprite palettes, 4 colors each

### Memory
- **RAM**: 2KB total ($0000-$07FF)
- **Zero page**: 256 bytes ($0000-$00FF) - fast addressing, indirect addressing only
- **Stack**: 256 bytes ($0100-$01FF) - reserve 96+ bytes free space
- **OAM buffer**: 256 bytes ($0200-$02FF by convention)

### Input
- **Controller strobe**: Latch once, read 8 bits sequentially (don't re-strobe mid-read)
- **DPCM conflict**: DMC playback can glitch controller reads (disable $4017 or read multiple times)
- **Button order**: A, B, Select, Start, Up, Down, Left, Right

---

## Document Maintenance

### When to Update Learning Docs
- After building test ROMs (add actual cycle counts, discovered edge cases)
- When hitting hardware limitations (document workarounds)
- When finding new techniques on forums/Discord (extract to appropriate doc)
- When discovering errors in cached wiki pages (note corrections)

### When to Create Phase Docs
- After completing each priority group in STUDY_PLAN.md
- Document: what studied, insights gained, questions raised, decisions made
- Location: `learnings/.ddd/PHASE_N.md`

### Organization Principle
- **Architecture docs** → What the hardware does (CPU, PPU, APU, memory)
- **Technique docs** → How to use the hardware (patterns, code, budgets)
- **Tool docs** → Development workflow (assemblers, emulators, graphics)
- **Meta docs** → Our learning process (`.ddd/` subdirectory)

---

## Future: mdbook Compilation

These learnings will eventually be compiled into an **mdbook** - a cleaned up, streamlined condensation of the NESdev wiki:
- **Audience**: LLM agents (but human-friendly via clear, concise language)
- **Attribution**: External wiki links already in place
- **Organization**: Matches current document structure
- **Value**: Agent-friendly NES reference, community-contributed knowledge

---

**Remember**: NES development is constraint-driven. The docs capture the constraints; test ROMs validate them; game code works within them. Document what you learn or lose it. 🎮
