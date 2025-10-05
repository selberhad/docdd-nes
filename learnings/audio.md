# Audio Programming

Practical guide to NES audio programming. Covers APU register programming, sound generation, and music engine integration.

## APU Register Map

APU channels occupy $4000-$400F, with $4015 for channel enable/status:

```
$4000-$4003  Pulse 1
$4004-$4007  Pulse 2
$4008-$400B  Triangle
$400C-$400F  Noise
$4010-$4013  DMC (not covered here)
$4015        Channel enable/status
$4017        Frame counter
```

## Initialization Sequence

Initialize APU to known state before use. Required to silence all channels and disable hardware features (sweep, envelope, length counter):

```asm
init_apu:
    ; Init $4000-4013
    ldy #$13
@loop:
    lda @regs,y
    sta $4000,y
    dey
    bpl @loop

    ; Skip $4014 (OAMDMA)
    lda #$0f
    sta $4015        ; Enable all channels
    lda #$40
    sta $4017        ; Disable IRQ
    rts

@regs:
    .byte $30,$08,$00,$00    ; Pulse 1
    .byte $30,$08,$00,$00    ; Pulse 2
    .byte $80,$00,$00,$00    ; Triangle
    .byte $30,$00,$00,$00    ; Noise
    .byte $00,$00,$00,$00    ; DMC
```

This disables hardware sweep, envelope, and length counter (features not used in basic APU programming).

## Pulse Wave Channels (2 channels)

Two identical pulse wave channels with pitch, volume, and timbre control.

### Registers

```
$4000/$4004:  %DD11VVVV    Duty cycle and volume
$4002/$4006:  %LLLLLLLL    Period low 8 bits
$4003/$4007:  %-----HHH    Period high 3 bits
```

### Parameters

**Duty cycle (DD):**
- 00 = 12.5%
- 01 = 25%
- 10 = 50% (square wave)
- 11 = 75%

**Volume (VVVV):**
- 0000 = silence
- 1111 = maximum

### Period Calculation

Raw period = 111860.8 / frequency - 1

For 400 Hz square wave:
- Period = 111860.8 / 400 - 1 = 279

### Example: 400 Hz Square Wave

```asm
jsr init_apu

lda #<279
sta $4002        ; Period low byte

lda #>279
sta $4003        ; Period high byte

lda #%10111111   ; 50% duty, max volume
sta $4000
```

### Runtime Parameter Changes

All parameters can be changed while playing:
- Volume: Write new value to $4000/$4004 (lower 4 bits)
- Period: Write to $4002/$4006 (low) and $4003/$4007 (high)
- **WARNING:** Writing to $4003/$4007 resets phase, causing pop. Avoid during vibrato.

## Triangle Wave Channel

Triangle channel has frequency and mute control. **No volume control** (always full volume or muted).

### Registers

```
$4008:  %1U------    Un-mute flag
$400A:  %LLLLLLLL    Period low 8 bits
$400B:  %-----HHH    Period high 3 bits
$4017:  %1-------    Apply un-mute immediately
```

### Period Calculation

Triangle plays **one octave lower** than pulse for same period.

Raw period = 55930.4 / frequency - 1

For 400 Hz triangle:
- Period = 55930.4 / 400 - 1 = 139

### Example: 400 Hz Triangle Wave

```asm
jsr init_apu

lda #<139
sta $400A        ; Period low byte

lda #>139
sta $400B        ; Period high byte

lda #%11000000
sta $4008        ; Un-mute
sta $4017        ; Apply immediately
```

### Muting Triangle

To silence:
- Write %10000000 to $4008, then $4017
- **Don't** write period of 0 (produces pop)

## Noise Channel

Noise channel for drums and sound effects. Controls frequency, volume, and tone mode.

### Registers

```
$400C:  %--11VVVV    Volume (0000=silence, 1111=max)
$400E:  %T---PPPP    Tone mode (T) and period (PPPP)
```

### Tone Mode

**T bit:**
- 0 = Noise mode (white noise)
- 1 = Tone mode (more tonal, good for drums)

**Period (PPPP):** 0-15, controls pitch (NOT frequency formula like pulse/triangle)

### Example: Tonal Noise

```asm
jsr init_apu

lda #%10000101   ; Tone mode, period 5
sta $400E

lda #%00111111   ; Max volume
sta $400C
```

## Period Tables for Musical Notes

Use lookup tables to map note numbers to periods. Avoids calculating periods at runtime.

### NTSC Period Table

For pulse channels. Triangle plays one octave lower for same values:

```asm
; NTSC period table (starts at lowest A on piano)
; Note indices: 0=A, 1=A#, 2=B, 3=C, ..., 11=G#, then next octave
periodTableLo:
  .byte $f1,$7f,$13,$ad,$4d,$f3,$9d,$4c,$00,$b8,$74,$34  ; Octave 1
  .byte $f8,$bf,$89,$56,$26,$f9,$ce,$a6,$80,$5c,$3a,$1a  ; Octave 2
  .byte $fb,$df,$c4,$ab,$93,$7c,$67,$52,$3f,$2d,$1c,$0c  ; Octave 3
  .byte $fd,$ef,$e1,$d5,$c9,$bd,$b3,$a9,$9f,$96,$8e,$86  ; Octave 4
  .byte $7e,$77,$70,$6a,$64,$5e,$59,$54,$4f,$4b,$46,$42  ; Octave 5
  .byte $3f,$3b,$38,$34,$31,$2f,$2c,$29,$27,$25,$23,$21  ; Octave 6
  .byte $1f,$1d,$1b,$1a,$18,$17,$15,$14                  ; Octave 7 (partial)

periodTableHi:
  .byte $07,$07,$07,$06,$06,$05,$05,$05,$05,$04,$04,$04  ; Octave 1
  .byte $03,$03,$03,$03,$03,$02,$02,$02,$02,$02,$02,$02  ; Octave 2
  .byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01  ; Octave 3
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; Octave 4
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; Octave 5
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00  ; Octave 6
  .byte $00,$00,$00,$00,$00,$00,$00,$00                  ; Octave 7 (partial)
```

### Using Period Table: Pulse Channels

```asm
; Set pulse channel 1 to note in X register (0-79)
lda periodTableHi,x
sta $4003

lda periodTableLo,x
sta $4002
```

### Using Period Table: Triangle Channel

Triangle plays octave lower, so compensate by:

**Option 1: Halve the period value**
```asm
; Set triangle to note in X register
lda periodTableHi,x
lsr a              ; Divide high byte by 2
sta $400B

lda periodTableLo,x
ror a              ; Rotate carry into low byte
sta $400A
```

**Option 2: Read from next octave**
```asm
; Set triangle to note in X register
lda periodTableHi+12,x    ; +12 = next octave
sta $400B

lda periodTableLo+12,x
sta $400A
```

### Generating Period Tables

Python script to generate custom tables (e.g., PAL):

```python
#!/usr/bin/env python3
import sys

lowestFreq = 55.0
ntscOctaveBase = 39375000.0/(22 * 16 * lowestFreq)
palOctaveBase = 266017125.0/(10 * 16 * 16 * lowestFreq)
maxNote = 80

def makePeriodTable(filename, pal=False):
    semitone = 2.0**(1./12)
    octaveBase = palOctaveBase if pal else ntscOctaveBase
    relFreqs = [(1 << (i // 12)) * semitone**(i % 12)
                for i in range(maxNote)]
    periods = [int(round(octaveBase / freq)) - 1 for freq in relFreqs]
    systemName = "PAL" if pal else "NTSC"

    with open(filename, 'wt') as outfp:
        outfp.write(f"; {systemName} period table\n")
        outfp.write(".export periodTableLo, periodTableHi\n")
        outfp.write(".segment \"RODATA\"\n")
        outfp.write("periodTableLo:\n")
        for i in range(0, maxNote, 12):
            outfp.write('  .byt ' + ','.join(f'${i % 256:02x}'
                                              for i in periods[i:i + 12]) + '\n')
        outfp.write('periodTableHi:\n')
        for i in range(0, maxNote, 12):
            outfp.write('  .byt ' + ','.join(f'${i >> 8:02x}'
                                              for i in periods[i:i + 12]) + '\n')

if __name__=='__main__':
    makePeriodTable('ntsc_periods.s', pal=False)
    makePeriodTable('pal_periods.s', pal=True)
```

## Audio Drivers / Music Engines

Audio drivers read music data from ROM and write to APU registers, typically once per frame.

### Two Categories

**1. Tracker Replayers** (FamiTracker NSF exports)
- Large ROM/RAM footprint
- Feature-rich, support all tracker features
- No sound effect support
- Not optimized for games
- Examples: FamiTracker, Famistudio (tracker mode), PPMCK/MML

**2. Game Replayers** (Optimized for game use)
- Limited instrument/effect features
- Small ROM/RAM footprint
- Sound effect support
- Translate text export to ASM data
- Usually no expansion audio (base NES hardware only)

### Popular Game Engines

#### FamiStudio Music Engine

Highly configurable, extensive features. Based on FamiTone2 but heavily reworked.

**Features:**
- Pulse, triangle, noise, DPCM
- 96 notes (C0-B7)
- Instrument envelopes: duty, volume, pitch, arpeggio
- Looping sections, release points
- Speed/tempo changes
- Up to 64 instruments, 17 songs per export
- Sound effects (configurable streams)
- Expansion audio support (VRC6, VRC7, FDS, Sunsoft 5B, Namco 163)
- PAL/NTSC playback
- Blaarg Smooth Vibrato (eliminates pops)

**Effects:** Fxx (speed), Dxx (cut), Bxx (loop), vibrato, slide notes, arpeggio

**Assemblers:** NESASM, CA65, ASM6

#### FamiTone2

By Shiru. Classic lightweight engine.

**Limits:**
- Notes: C-1 to D-6
- Instruments: 64 max
- DPCM only for instrument 0
- No volume column
- Pitch envelope limited to ±63 units
- No release phase

**Effects:** Fxx (speed), Dxx (cut), Bxx (loop)

**Requirements:**
- 3 bytes ZP
- 186 bytes RAM
- 1636 bytes ROM

#### FamiTone 5.0

By dougeff. Enhanced FamiTone2.

**Adds:**
- Volume column support
- Note range A0-B7
- Duty cycle envelopes
- Large sound effects (>256 bytes)
- Portamento effects: 1xx, 2xx, 3xx, 4xy, Qxx, Rxx

#### GGSound

By Gradual Games. Looping envelopes, high instrument limit.

**Features:**
- Note range C0-B7
- Looping envelopes (volume, arpeggio, pitch, duty)
- SFX on up to 2 channels
- Pause/unpause
- 128 instruments, 128 songs, 128 SFX

**Effects:** Bxx (loop, per-channel)

**Requirements:**
- 66 bytes ZP (57 without DPCM)
- 168 bytes RAM (144 without DPCM)
- ~3048 bytes ROM

#### Pently

By Damian Yerrick. Rows-per-minute tempo model, runtime PAL/NTSC correction.

**Features:**
- Notes A-0 to C-7
- Envelopes: volume, duty, arpeggio (no pitch)
- Volume column (4 levels)
- No DPCM
- Linear pitch model (like 0CC-FamiTracker)
- Configurable features (disable to save ROM/RAM)

**Effects:** 45x (vibrato), 3xx (portamento), Sxx/Gxx (grace notes), 0xy (arpeggio), Bxx (loop)

**Requirements:**
- 32 bytes ZP
- 112 bytes RAM
- 1918 bytes ROM (1283 bytes for FamiTone2-like feature set)

**Assemblers:** CA65, ASM6 (experimental)

**Native format:** Pently score (MML-like). FamiTracker conversion via ft2pently.

#### Penguin

By pubby. Constant cycle count (raster-safe).

**Features:**
- **790 cycles constant** (allows raster effects)
- SFX without extra cycles
- Similar to FamiTone2 + duty envelopes
- No DPCM
- Fixed tempo 150
- Minimum speed 4

**Requirements:**
- 12 bytes ZP
- 86 bytes RAM
- Not size-optimized (music data large, SFX expensive)

**Effects:** D00 (terminate pattern), SFX support all effects

#### Sabre

By CutterCross. Modern engine with broad feature set.

**Features:**
- Note range A0-B7
- Envelopes: volume, arpeggio, pitch, duty (all looping)
- DPCM for music (not SFX)
- 63 instruments, 256 tracks, 256 SFX
- NTSC/PAL/Dendy adjustments
- Triangle linear counter trill
- Mute/unmute channels

**Effects:** Bxx (loop), C00 (halt), D00 (skip frame), Fxx (speed), Zxx (DPCM delta)

**Requirements:**
- 42 bytes ZP
- 121 bytes RAM
- 1749 bytes ROM

**Assemblers:** CA65, ASM6

**Notes:**
- Instruments share common envelope set
- Optimized song format (no redundant period data)

### Choosing an Engine

**For beginners:** FamiTone2 (simple, well-documented)

**For rich features:** FamiStudio Music Engine (configurable, modern, expansion audio)

**For size optimization:** Pently (configurable, can disable features)

**For raster effects:** Penguin (constant cycle count)

**For expressive music:** GGSound (looping envelopes) or NSD.Lib (MML-focused)

**For modern workflow:** Sabre or FamiStudio (both actively maintained)

## Sound Engine Architecture Patterns

### Update Frequency

Most engines update **once per frame** (60 Hz NTSC, 50 Hz PAL). Called from NMI or main loop after PPU updates.

### Typical Call Structure

```asm
NMI:
    ; ... PPU updates ...

    jsr music_update    ; Update music engine

    ; ... rest of NMI ...
    rti
```

### SFX Priority

Sound effects typically **interrupt** music channels:
- High priority SFX takes over channel
- Music resumes when SFX ends
- Common: SFX on pulse 1 + noise, music on pulse 2 + triangle

### Music/SFX Mixing Strategies

**Strategy 1: Channel hijacking**
- SFX steals channels from music
- Music pauses/mutes affected channels
- Simple but causes audio gaps

**Strategy 2: Dedicated SFX channels**
- Reserve channels for SFX only
- Music uses remaining channels
- No interruption, but fewer channels for music

**Strategy 3: Priority system**
- Each SFX has priority level
- High priority interrupts music
- Low priority skipped if channel busy

### Data Format Considerations

**Compact formats:**
- Delta encoding (store note changes, not absolute values)
- Run-length encoding for repeated notes/rests
- Shared envelopes across instruments
- Pattern reuse

**Example: FamiTone2 optimization**
- No redundant period writes if only volume changes
- Shared arpeggio/pitch envelopes

## Cycle Budget for Audio

### Per-Frame Update Costs

Typical music engine costs (approximate):

| Engine | Cycles/Frame | Notes |
|--------|--------------|-------|
| FamiTone2 | ~1200-1500 | Varies by song complexity |
| Pently | ~1500-2000 | Configurable features |
| Penguin | **790** | Constant, raster-safe |
| GGSound | ~1800 | With DPCM |
| FamiStudio | ~1500-2500 | Depends on enabled features |

### Vblank Budget

- Total vblank: ~2273 cycles (NTSC)
- PPU updates: ~500-1500 cycles (varies)
- **Audio budget: 500-1500 cycles** (depends on PPU needs)

### Optimization Strategies

**If over budget:**
- Update music every other frame (30 Hz updates)
- Disable unused features in configurable engines
- Use simpler instruments (fewer envelope points)
- Reduce SFX count/complexity

**Raster effect requirement:**
- Use Penguin (constant 790 cycles)
- Or update music outside vblank (tricky, test thoroughly)

## Practical Patterns

### Pattern 1: Simple SFX Trigger

```asm
; Play sound effect 0 on pulse channel 1
play_sfx_jump:
    lda #0              ; SFX index
    ldx #0              ; Channel (0 = pulse 1)
    jsr famistudio_sfx_play
    rts
```

### Pattern 2: Music Track Change

```asm
; Switch to song 1
change_to_song_1:
    lda #1              ; Song index
    jsr famistudio_music_play
    rts
```

### Pattern 3: Volume Fade

```asm
; Fade out pulse 1 over time
fade_pulse1:
    lda pulse1_volume
    beq @done           ; Already silent
    sec
    sbc #1              ; Decrease volume
    sta pulse1_volume
    ora #%10110000      ; 50% duty, constant volume
    sta $4000
@done:
    rts

pulse1_volume: .byte 15    ; Current volume (0-15)
```

### Pattern 4: Simple Pitch Bend

```asm
; Bend pulse 1 pitch up
pitch_bend_up:
    lda pulse1_period_lo
    sec
    sbc #4              ; Decrease period = higher pitch
    sta pulse1_period_lo
    sta $4002

    lda pulse1_period_hi
    sbc #0              ; Handle carry
    sta pulse1_period_hi
    sta $4003           ; WARNING: Resets phase (pop)
    rts

pulse1_period_lo: .byte 0
pulse1_period_hi: .byte 0
```

## NSF Files and Music Data

### NSF Format

NSF (NES Sound Format) packages music data + playback code:
- Header with metadata (title, artist, track count)
- 6502 code to play music
- Music data (note sequences, instruments)
- Can be played on NES or PC emulator

### NSF vs. Game Integration

**NSF exports (FamiTracker):**
- Self-contained player
- Large, feature-rich
- Not optimized for games
- Good for music development/testing

**Game engines:**
- Lightweight, optimized
- Require external tools to convert music
- Integrate into game code
- Support SFX alongside music

### Workflow

1. Compose in tracker (FamiTracker, FamiStudio)
2. Export to text format or engine-specific format
3. Convert to ASM data (via engine's converter)
4. Include in game source
5. Call engine's play routines from game code

## References


## See Also

- learnings/wiki_architecture.md - APU hardware architecture
- learnings/memory.md - RAM allocation for audio buffers

---

## Attribution

This document synthesizes information from the following NESdev Wiki pages:

- [APU_basics](https://www.nesdev.org/wiki/APU_basics)
- [APU_period_table](https://www.nesdev.org/wiki/APU_period_table)
- [Audio_drivers](https://www.nesdev.org/wiki/Audio_drivers)
- [Music](https://www.nesdev.org/wiki/Music)

