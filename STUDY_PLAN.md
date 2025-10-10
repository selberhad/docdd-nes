# NESdev Wiki Study Plan

Systematic coverage of NESdev Wiki for architecture understanding. Use `tools/fetch-wiki.sh PageName` to cache pages.

## ✅ Already Cached & Studied

- [x] CPU - https://www.nesdev.org/wiki/CPU
- [x] PPU - https://www.nesdev.org/wiki/PPU
- [x] APU - https://www.nesdev.org/wiki/APU
- [x] 2A03 - https://www.nesdev.org/wiki/2A03
- [x] CPU_memory_map - https://www.nesdev.org/wiki/CPU_memory_map
- [x] PPU_memory_map - https://www.nesdev.org/wiki/PPU_memory_map
- [x] Controller_reading - https://www.nesdev.org/wiki/Controller_reading
- [x] 6502_instructions - https://www.nesdev.org/wiki/6502_instructions
- [x] Mapper - https://www.nesdev.org/wiki/Mapper
- [x] PPU_scrolling - https://www.nesdev.org/wiki/PPU_scrolling
- [x] PPU_rendering - https://www.nesdev.org/wiki/PPU_rendering
- [x] PPU_palettes - https://www.nesdev.org/wiki/PPU_palettes
- [x] CHR_ROM - https://www.nesdev.org/wiki/CHR_ROM
- [x] OAM - https://www.nesdev.org/wiki/OAM
- [x] The_frame_and_NMIs - https://www.nesdev.org/wiki/The_frame_and_NMIs

**Learnings captured in:** `learnings/wiki_architecture.md`

---

## 🎯 Priority 1: Core Development (Getting Started)

- [x] Before_the_basics - https://www.nesdev.org/wiki/Before_the_basics
- [x] Programming_Basics - https://www.nesdev.org/wiki/Programming_Basics
- [x] Init_code - https://www.nesdev.org/wiki/Init_code
- [x] Registers - https://www.nesdev.org/wiki/Registers
- [x] PPU_power_up_state - https://www.nesdev.org/wiki/PPU_power_up_state
- [x] Sample_RAM_map - https://www.nesdev.org/wiki/Sample_RAM_map
- [x] Limitations - https://www.nesdev.org/wiki/Limitations

**Learnings captured in:** `learnings/getting_started.md`

## 🎯 Priority 2: Essential Techniques

### PPU & Graphics
- [x] PPU_sprite_evaluation - https://www.nesdev.org/wiki/PPU_sprite_evaluation
- [x] Sprite_size - https://www.nesdev.org/wiki/Sprite_size
- [x] Detecting_video_standard - https://www.nesdev.org/wiki/Detecting_video_standard
- [x] Placeholder_graphics - https://www.nesdev.org/wiki/Placeholder_graphics
- [x] Drawing_terrain - https://www.nesdev.org/wiki/Drawing_terrain
- [x] Palette_change_mid_frame - https://www.nesdev.org/wiki/Palette_change_mid_frame
- [x] Sprite_cel_streaming - https://www.nesdev.org/wiki/Sprite_cel_streaming
- [x] Don't_hardcode_OAM_addresses - https://www.nesdev.org/wiki/Don%27t_hardcode_OAM_addresses

### Input
- [x] Controller_reading_code - https://www.nesdev.org/wiki/Controller_reading_code
- [x] Input_devices - https://www.nesdev.org/wiki/Input_devices

### Timing & Interrupts
- [x] Cycle_reference_chart - https://www.nesdev.org/wiki/Cycle_reference_chart
- [x] Cycle_counting - https://www.nesdev.org/wiki/Cycle_counting
- [x] NMI_thread - https://www.nesdev.org/wiki/NMI_thread
- [x] Interrupt_forwarding - https://www.nesdev.org/wiki/Interrupt_forwarding

**Learnings captured in:**
- `learnings/sprite_techniques.md` - Sprite evaluation, OAM management, sprite 0 hit, cel streaming
- `learnings/graphics_techniques.md` - Video standard detection, terrain rendering, palette changes
- `learnings/input_handling.md` - Controller reading, accessories, edge detection patterns
- `learnings/timing_and_interrupts.md` - Cycle budgeting, NMI handlers, interrupt forwarding

## 🎯 Priority 2.5: Development Toolchain

- [x] Tools - https://www.nesdev.org/wiki/Tools
- [x] Emulators - https://www.nesdev.org/wiki/Emulators
- [x] Emulator_tests - https://www.nesdev.org/wiki/Emulator_tests

**Learnings captured in:** `learnings/toolchain.md` - Assembler/emulator selection, graphics/audio tools, test ROMs

## 🎯 Priority 3: Programming Techniques

### 6502 Optimization
- [x] 6502_assembly_optimisations - https://www.nesdev.org/wiki/6502_assembly_optimisations
- [x] RTS_Trick - https://www.nesdev.org/wiki/RTS_Trick
- [x] Jump_Table - https://www.nesdev.org/wiki/Jump_Table
- [x] Scanning_Tables - https://www.nesdev.org/wiki/Scanning_Tables
- [x] Scanning_Large_Tables - https://www.nesdev.org/wiki/Scanning_Large_Tables
- [x] Synthetic_Instructions - https://www.nesdev.org/wiki/Synthetic_Instructions
- [x] Programming_with_unofficial_opcodes - https://www.nesdev.org/wiki/Programming_with_unofficial_opcodes
- [x] Pointer_table - https://www.nesdev.org/wiki/Pointer_table
- [x] Multibyte_constant - https://www.nesdev.org/wiki/Multibyte_constant

### Math
- [x] Multiplication_by_a_constant_integer - https://www.nesdev.org/wiki/Multiplication_by_a_constant_integer
- [x] Fast_signed_multiply - https://www.nesdev.org/wiki/Fast_signed_multiply
- [x] 8-bit_Multiply - https://www.nesdev.org/wiki/8-bit_Multiply
- [x] 8-bit_Divide - https://www.nesdev.org/wiki/8-bit_Divide
- [x] Division_by_a_constant_integer - https://www.nesdev.org/wiki/Division_by_a_constant_integer
- [x] Divide_by_3 - https://www.nesdev.org/wiki/Divide_by_3
- [x] 16-bit_BCD - https://www.nesdev.org/wiki/16-bit_BCD
- [x] Base_100 - https://www.nesdev.org/wiki/Base_100
- [x] Random_number_generator - https://www.nesdev.org/wiki/Random_number_generator

### Data Compression
- [x] Compression - https://www.nesdev.org/wiki/Compression
- [x] Fixed_Bit_Length_Encoding - https://www.nesdev.org/wiki/Fixed_Bit_Length_Encoding

**Learnings captured in:**
- `learnings/optimization.md` - Cycle/byte trade-offs, speed techniques, unofficial opcodes, jump tables
- `learnings/math_routines.md` - Multiply, divide, BCD conversion, RNG implementations

## 🎯 Priority 4: Audio

- [x] APU_basics - https://www.nesdev.org/wiki/APU_basics
- [x] APU_period_table - https://www.nesdev.org/wiki/APU_period_table
- [x] Audio_drivers - https://www.nesdev.org/wiki/Audio_drivers
- [x] Nerdy_Nights_sound - https://www.nesdev.org/wiki/Nerdy_Nights_sound
- [x] Music - https://www.nesdev.org/wiki/Music

**Learnings captured in:** `learnings/audio.md` - APU programming, sound engines, music drivers, cycle budgets

## 🎯 Priority 5: Mappers

- [x] Programming_mappers - https://www.nesdev.org/wiki/Programming_mappers
- [x] Programming_UNROM - https://www.nesdev.org/wiki/Programming_UNROM
- [x] Programming_MMC1 - https://www.nesdev.org/wiki/Programming_MMC1
- [x] CHR-ROM_vs_CHR-RAM - https://www.nesdev.org/wiki/CHR-ROM_vs_CHR-RAM

**Learnings captured in:** `learnings/mappers.md` - Bank switching, CHR-ROM vs CHR-RAM, UNROM/MMC1 programming

## 📚 Reference & Advanced Topics (Optional/As-Needed)

**Purpose**: Deep dives and edge cases. Not required for practical work, but useful for:
- Debugging tricky hardware behavior
- Understanding ROM formats for tooling
- Emulator accuracy research
- Platform variant support (Famicom, PAL)

**Recommendation**: Study as-needed when specific questions arise during development.

---

### Hardware Details
- [ ] Glossary - https://www.nesdev.org/wiki/Glossary
- [ ] Cartridge_and_mappers'_history - https://www.nesdev.org/wiki/Cartridge_and_mappers%27_history
- [ ] Hardware_pinout - https://www.nesdev.org/wiki/Hardware_pinout
- [ ] Cartridge_board_reference - https://www.nesdev.org/wiki/Cartridge_board_reference
- [ ] Errata - https://www.nesdev.org/wiki/Errata
- [ ] Myths - https://www.nesdev.org/wiki/Myths

### File Formats
- [ ] INES - https://www.nesdev.org/wiki/INES
- [ ] NES_2.0 - https://www.nesdev.org/wiki/NES_2.0
- [ ] UNIF - https://www.nesdev.org/wiki/UNIF
- [ ] NSF - https://www.nesdev.org/wiki/NSF
- [ ] FDS_file_format - https://www.nesdev.org/wiki/FDS_file_format


### Emulation Reference
- [ ] Game_bugs - https://www.nesdev.org/wiki/Game_bugs
- [ ] Tricky-to-emulate_games - https://www.nesdev.org/wiki/Tricky-to-emulate_games
- [ ] Sprite_overflow_games - https://www.nesdev.org/wiki/Sprite_overflow_games
- [ ] Colour-emphasis_games - https://www.nesdev.org/wiki/Colour-emphasis_games
- [ ] Expansion_audio_games - https://www.nesdev.org/wiki/Expansion_audio_games

### Platform Variants
- [ ] Family_Computer - https://www.nesdev.org/wiki/Family_Computer
- [ ] Family_Computer_Disk_System - https://www.nesdev.org/wiki/Family_Computer_Disk_System
- [ ] Vs._System - https://www.nesdev.org/wiki/Vs._System
- [ ] FamicomBox - https://www.nesdev.org/wiki/FamicomBox
- [ ] CIC_lockout_chip - https://www.nesdev.org/wiki/CIC_lockout_chip
- [ ] Famicom_cartridge_dimensions - https://www.nesdev.org/wiki/Famicom_cartridge_dimensions

### Advanced Topics
- [ ] Emulation_Libraries - https://www.nesdev.org/wiki/Emulation_Libraries
- [ ] Catch-up - https://www.nesdev.org/wiki/Catch-up
- [ ] Releasing_on_modern_platforms - https://www.nesdev.org/wiki/Releasing_on_modern_platforms
- [ ] Calculate_CRC32 - https://www.nesdev.org/wiki/Calculate_CRC32

---

## 📝 Study Process

1. **Cache page**: `tools/fetch-wiki.sh PageName`
2. **Read & analyze**: Extract key technical details
3. **Document findings**: Create `learnings/topic_name.md` if substantial new info
4. **Check off**: Mark completed in this file
5. **Apply**: Use knowledge in test ROMs or game code

## 🎯 Current Focus & Next Steps

**✅ All Core Priorities Complete!**

**Study Progress**:
- **52/100+ wiki pages studied** (52% total coverage)
- **Core priorities**: 52 pages across 5 priorities (Priorities 1-5) ✅
- **Reference topics**: ~40+ pages remain (optional/as-needed)

**Completed Priorities**:
- Priority 1: Getting Started (7 pages) ✅
- Priority 2: Essential Techniques (14 pages) ✅
- Priority 2.5: Development Toolchain (3 pages) ✅
- Priority 3: Programming Techniques (19 pages) ✅
- Priority 4: Audio (5 pages) ✅
- Priority 5: Mappers (4 pages) ✅

**Learnings Documentation**:
- **11 technical documents** created (`learnings/*.md`)
- **5 meta-learning documents** created (`learnings/.ddd/*.md`)
- **All questions tracked** in `learnings/.ddd/5_open_questions.md`

---

## 🚀 Recommended Next Phase

**Option A: Begin Practical Work (RECOMMENDED)**

Systematic study complete. Time to validate through practice:

1. **Toolchain Setup**:
   - Install asm6f, Mesen, NEXXT, FamiTracker
   - Run blargg test ROM suite (validate emulator)
   - Create build script (Makefile)
   - **Answers**: Q1.1-Q1.8 from `5_open_questions.md`

2. **"Hello World" Test ROM** (NROM):
   - Display sprite (test graphics workflow)
   - Read controller (test input)
   - Play beep (test basic audio)
   - Profile cycle usage (measure actual costs)
   - **Answers**: Q1.3-Q1.6, Q2.1-Q2.2, Q6.3 from `5_open_questions.md`

3. **Subsystem Test ROMs**:
   - Graphics: Metatiles, scrolling, attributes
   - Audio: FamiTone2 integration, SFX mixing
   - Collision: AABB, tile-based detection
   - **Updates**: Learning docs with real measurements

4. **Game Prototype**:
   - Define game in SPEC.md
   - Implement core gameplay
   - Measure/optimize performance
   - Document architecture patterns

**Option B: Continue Reference Study**

Study file formats, emulation details, platform variants (~40+ pages). Useful but not blocking for practical work.

**Option C: Mixed Approach**

Begin practical work, study Reference topics as specific questions arise (e.g., read INES/NES 2.0 when building ROM headers).
