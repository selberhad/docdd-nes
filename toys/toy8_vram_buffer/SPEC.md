# SPEC — VRAM Buffer System

**Purpose**: Queue nametable tile updates during gameplay, flush efficiently during vblank NMI

<!-- Read docs/guides/SPEC_WRITING.md before writing this document -->

## Overview

**What it does**: Defers nametable writes to vblank by buffering tile updates in RAM. Game code queues tiles during rendering (when PPU is busy), NMI handler flushes buffer via PPUADDR/PPUDATA writes (when PPU is available).

**Key principles**:
- Sacrifice rendering time (plentiful) to save vblank time (scarce)
- Simple queue format: minimal overhead, predictable behavior
- Silent overflow handling (drop new entries if buffer full)
- Test with Phase 1 tools (nametable assertions, not cycle counting)

**Scope**: Isolates VRAM update buffering pattern
- **In scope**: Queue management, flush logic, overflow behavior
- **Out of scope**: Scrolling, metatiles, compression (separate toys)

**Integration context**:
- Input: Game code calls queue operations (inline assembly, not library)
- Output: Nametable tiles updated after NMI flush
- Dependencies: NMI handler must call flush routine

## Data Model

### Buffer Structure (RAM $0300-$032F)

```
$0300:       Queue count (0-16)
$0301-$0303: Entry 0 (addr_hi, addr_lo, tile_value)
$0304-$0306: Entry 1 (addr_hi, addr_lo, tile_value)
...
$032E-$0330: Entry 15 (addr_hi, addr_lo, tile_value)
```

**Layout**:
- 1 byte counter + (16 entries × 3 bytes) = 49 bytes total
- Max capacity: 16 tile updates per frame
- Overflow: Silently ignore queue attempts when count >= 16

**Example** (2 tiles queued):
```
$0300: 02        ; Count = 2
$0301: 20        ; Entry 0: addr_hi ($20xx)
$0302: 45        ; Entry 0: addr_lo ($2045 = row 2, col 5)
$0303: 42        ; Entry 0: tile = $42
$0304: 21        ; Entry 1: addr_hi ($21xx)
$0305: 00        ; Entry 1: addr_lo ($2100 = row 8, col 0)
$0306: 43        ; Entry 1: tile = $43
```

## Core Operations

### Operation 1: queue_tile

**Purpose**: Add tile update to buffer (called during gameplay, outside vblank)

**Pseudocode**:
```asm
; Input: A = tile value, X = addr_hi, Y = addr_lo
queue_tile:
  lda $0300           ; Load count
  cmp #16
  bcs queue_full      ; If count >= 16, ignore

  ; Calculate buffer offset (count * 3 + 1)
  sta temp
  asl                 ; count * 2
  adc temp            ; count * 3
  tax
  inx                 ; Skip counter byte

  ; Store entry (addr_hi, addr_lo, tile)
  tya                 ; addr_hi from Y
  sta $0300,x
  txa                 ; addr_lo from X
  sta $0301,x
  lda tile_value      ; tile from A
  sta $0302,x

  ; Increment count
  inc $0300
  rts

queue_full:
  rts                 ; Silent drop (production: set overflow flag)
```

**Behavior**:
- If buffer has space: Append entry, increment counter
- If buffer full (count >= 16): Do nothing (silent drop)
- No validation: Caller responsible for valid PPU addresses

### Operation 2: flush_buffer

**Purpose**: Write all queued tiles to nametable (called during NMI, inside vblank)

**Pseudocode**:
```asm
flush_buffer:
  lda $0300           ; Load count
  beq flush_done      ; If 0, nothing to flush

  tax                 ; X = count (loop counter)
  ldy #1              ; Y = buffer offset (start after counter)

flush_loop:
  ; Set PPUADDR
  lda $2002           ; Reset latch
  lda $0300,y         ; addr_hi
  sta $2006
  iny
  lda $0300,y         ; addr_lo
  sta $2006
  iny

  ; Write tile
  lda $0300,y         ; tile value
  sta $2007
  iny

  dex
  bne flush_loop

  ; Clear buffer
  lda #0
  sta $0300           ; Reset count

flush_done:
  rts
```

**Behavior**:
- Loop over all entries, write via PPUADDR/PPUDATA
- Clear counter when done
- Cost: ~(20 cycles per tile) × count + overhead

## Test Scenarios

### 1. Simple: Single Tile Update

**Setup**:
- Queue 1 tile: address $2000, value $42
- Trigger NMI to flush

**Expected**:
- Nametable[$2000] = $42 after NMI
- Buffer count = 0 after flush

**Assertions**:
```perl
at_frame 2 => sub {
    assert_tile(0, 0, 0x42);      # Tile at (0,0) = $42
    assert_ram(0x0300, 0);        # Buffer empty
};
```

### 2. Complex: Column Streaming

**Setup**:
- Queue 30 tiles (column 5, rows 0-29)
- Values: $01, $02, $03, ..., $1E

**Expected**:
- All 30 tiles appear in nametable column 5
- Buffer count = 0 after flush

**Assertions**:
```perl
at_frame 2 => sub {
    assert_column(5, [0x01, 0x02, 0x03, ..., 0x1E]);
    assert_ram(0x0300, 0);
};
```

### 3. Complex: Multiple Scattered Updates

**Setup**:
- Queue 5 tiles at random positions:
  - Tile(1,1) = $10
  - Tile(15,10) = $20
  - Tile(0,0) = $30
  - Tile(31,29) = $40
  - Tile(10,5) = $50

**Expected**:
- All 5 tiles appear at correct coordinates
- Buffer count = 0

**Assertions**:
```perl
at_frame 2 => sub {
    assert_tile(1, 1, 0x10);
    assert_tile(15, 10, 0x20);
    assert_tile(0, 0, 0x30);
    assert_tile(31, 29, 0x40);
    assert_tile(10, 5, 0x50);
    assert_ram(0x0300, 0);
};
```

### 4. Error: Buffer Overflow

**Setup**:
- Queue 20 tiles (exceeds 16-entry capacity)

**Expected**:
- First 16 tiles queued successfully
- Last 4 tiles silently dropped
- No corruption (count stays at 16)

**Assertions**:
```perl
at_frame 1 => sub {
    # After queuing 20 tiles
    assert_ram(0x0300, 16);       # Count maxed at 16
};

at_frame 2 => sub {
    # After flush, only first 16 appear
    assert_tile(0, 0, 0x01);      # Tile 1 (queued)
    assert_tile(0, 15, 0x10);     # Tile 16 (last queued)
    assert_tile(0, 16, 0x00);     # Tile 17 (dropped, nametable empty)
};
```

### 5. Integration: NMI Handler

**Setup**:
- Queue tiles during frame N
- NMI handler at frame N+1 flushes buffer

**Expected**:
- Tiles not visible until after NMI flush
- Buffer persists across frames until flushed

**Assertions**:
```perl
at_frame 1 => sub {
    # Queued but not flushed yet
    assert_ram(0x0300, 3);        # Count = 3
    assert_tile(0, 0, 0x00);      # Nametable still empty
};

at_frame 2 => sub {
    # After NMI flush
    assert_ram(0x0300, 0);        # Buffer cleared
    assert_tile(0, 0, 0x42);      # Tile now visible
};
```

## Success Criteria

- [ ] Single tile queued and flushed correctly
- [ ] Multiple scattered tiles all appear at correct coordinates
- [ ] Full column (30 tiles) flushed successfully in one frame
- [ ] Buffer overflow (>16 entries) drops new entries without corruption
- [ ] Buffer count resets to 0 after flush
- [ ] Tiles appear in nametable only after NMI flush, not before
- [ ] No nametable corruption (only specified tiles change)
- [ ] All tests pass using Phase 1 DSL (assert_tile, assert_column)
