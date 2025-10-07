# PLAN — VRAM Buffer System

<!-- Read docs/guides/PLAN_WRITING.md before writing this document -->

## Overview

**Goal**: Implement VRAM buffer pattern (queue + flush) with automated TDD validation

**Scope**: 5 test scenarios from SPEC.md, single ROM with inline buffer routines

**Priorities**:
1. Single tile (prove queue+flush works)
2. Multiple tiles (prove iteration works)
3. Column streaming (validate new assert_column helper)
4. Overflow (error handling)
5. NMI integration (prove timing works)

**Methodology**: TDD with Phase 1 tools (jsnes + new nametable assertions)
- Test: Buffer state (RAM), nametable state (assert_tile/assert_column)
- Skip: Cycle counting (Phase 2), visual validation (Mesen2)
- Commit after each step (Red → Green)

---

## Steps

### Step 1: Scaffold ROM Build

**Goal**: Set up build infrastructure and basic ROM skeleton

#### Step 1.a: Scaffold Build Files

**Tasks**:
1. Run `new-rom.pl buffer` to generate Makefile, nes.cfg, buffer.s
2. Verify build: `make` produces buffer.nes
3. Create `t/` directory for test files

**Success Criteria**:
- [ ] `make` builds buffer.nes without errors
- [ ] ROM is 24KB+ (valid iNES format)

#### Step 1.b: Basic ROM Skeleton

**Code pattern** (buffer.s):
```asm
.segment "HEADER"
  ; iNES header (auto-generated)

.segment "ZEROPAGE"
  temp: .res 1

.segment "RAM"
  buffer_count: .res 1      ; $0300
  buffer_data:  .res 48     ; $0301-$0330 (16 entries × 3 bytes)

.segment "CODE"
reset:
  sei
  cld
  ldx #$FF
  txs
  ; ... standard init ...

  ; Initialize buffer
  lda #0
  sta buffer_count

  jmp main

nmi:
  rti

main:
  jmp main
```

**Commit**: `feat(vram_buffer): Step 1 - scaffold ROM build`

---

### Step 2: Single Tile Update

**Goal**: Prove basic queue + flush works

#### Step 2.a: Write Tests (t/01-single-tile.t)

**Test strategy**:
- Frame 1: Queue tile at $2000 (coord 0,0), value $42
- Frame 2: After NMI flush, assert tile appears

**Test outline**:
```perl
use NES::Test::Toy 'buffer';

at_frame 1 => sub {
    assert_ram(0x0300, 1);        # Count = 1 (queued)
    assert_tile(0, 0, 0x00);      # Not flushed yet
};

at_frame 2 => sub {
    assert_tile(0, 0, 0x42);      # Flushed!
    assert_ram(0x0300, 0);        # Buffer cleared
};

done_testing();
```

#### Step 2.b: Implement queue_tile and flush_buffer

**Tasks**:
1. Implement `queue_tile` routine (inline in main, not subroutine yet)
2. Implement `flush_buffer` routine
3. Call flush_buffer in NMI handler
4. Main: queue 1 tile, then infinite loop

**Code pattern** (queue_tile inline):
```asm
main:
  ; Queue tile: $2000 = $42
  ldx buffer_count
  cpx #16
  bcs skip_queue          ; Full, skip

  ; Calculate offset: count * 3 + 1
  txa
  asl                     ; count * 2
  sta temp
  txa
  clc
  adc temp                ; count * 3
  tax

  lda #$20                ; addr_hi
  sta buffer_data,x
  lda #$00                ; addr_lo
  sta buffer_data+1,x
  lda #$42                ; tile value
  sta buffer_data+2,x

  inc buffer_count

skip_queue:
  jmp skip_queue          ; Infinite loop
```

**Code pattern** (flush_buffer):
```asm
flush_buffer:
  ldx buffer_count
  beq done

  ldy #0                  ; Buffer offset
loop:
  lda $2002               ; Reset latch
  lda buffer_data,y       ; addr_hi
  sta $2006
  iny
  lda buffer_data,y       ; addr_lo
  sta $2006
  iny
  lda buffer_data,y       ; tile value
  sta $2007
  iny

  dex
  bne loop

  lda #0
  sta buffer_count
done:
  rts
```

**NMI handler**:
```asm
nmi:
  jsr flush_buffer
  rti
```

**Success Criteria**:
- [ ] Test passes: tile appears at (0,0) after NMI
- [ ] Buffer count = 1 before flush, 0 after

**Commit**: `feat(vram_buffer): Step 2 - single tile queue+flush`

---

### Step 3: Multiple Scattered Tiles

**Goal**: Prove loop handles multiple entries correctly

#### Step 3.a: Write Tests (t/02-multiple-tiles.t)

**Test strategy**:
- Queue 5 tiles at different coordinates
- Assert all appear after flush

**Test outline**:
```perl
at_frame 2 => sub {
    assert_tile(1, 1, 0x10);
    assert_tile(15, 10, 0x20);
    assert_tile(0, 0, 0x30);
    assert_tile(31, 29, 0x40);
    assert_tile(10, 5, 0x50);
    assert_ram(0x0300, 0);        # Buffer cleared
};
```

#### Step 3.b: Implement Multi-Queue

**Tasks**:
1. Extend main to queue 5 tiles (inline, copy-paste pattern)
2. Verify flush_buffer loop handles all entries
3. Verify buffer clears after flush

**Code pattern**:
```asm
main:
  ; Queue tile 1: (1,1) = $10
  ; ... queue_tile logic ...

  ; Queue tile 2: (15,10) = $20
  ; ... queue_tile logic ...

  ; ... 3 more tiles ...

infinite:
  jmp infinite
```

**Success Criteria**:
- [ ] All 5 tiles appear at correct coordinates
- [ ] Buffer count = 0 after flush
- [ ] No nametable corruption (only specified tiles change)

**Commit**: `feat(vram_buffer): Step 3 - multiple scattered tiles`

---

### Step 4: Column Streaming

**Goal**: Validate new assert_column helper, test high-volume updates

#### Step 4.a: Write Tests (t/03-column.t)

**Test strategy**:
- Queue 30 tiles (full column 5, rows 0-29)
- Use assert_column for ergonomic validation

**Test outline**:
```perl
at_frame 2 => sub {
    my @expected = (0x01..0x1E);  # 30 tiles: $01..$1E
    assert_column(5, \@expected);
    assert_ram(0x0300, 0);
};
```

#### Step 4.b: Implement Column Queue

**Tasks**:
1. Extend main to queue 30 tiles (loop)
2. Verify flush handles 30 entries
3. Test assert_column helper (first real usage!)

**Code pattern**:
```asm
main:
  ldx #0                  ; Row counter (0-29)
queue_loop:
  ; Calculate column address: $2000 + (row * 32) + 5
  txa
  asl                     ; row * 2
  asl                     ; row * 4
  asl                     ; row * 8
  asl                     ; row * 16
  asl                     ; row * 32
  clc
  adc #5                  ; + column 5
  tay                     ; Y = addr_lo

  lda #$20                ; addr_hi
  ; ... queue_tile logic (addr_hi=A, addr_lo=Y, tile=X+1) ...

  inx
  cpx #30
  bne queue_loop

infinite:
  jmp infinite
```

**Success Criteria**:
- [ ] All 30 tiles appear in column 5
- [ ] assert_column passes (validates helper works!)
- [ ] Buffer count = 0 after flush

**Commit**: `feat(vram_buffer): Step 4 - column streaming (30 tiles)`

---

### Step 5: Buffer Overflow

**Goal**: Validate overflow handling (silent drop)

#### Step 5.a: Write Tests (t/04-overflow.t)

**Test strategy**:
- Queue 20 tiles (exceeds 16 capacity)
- Assert first 16 queued, last 4 dropped
- Verify no corruption

**Test outline**:
```perl
at_frame 1 => sub {
    assert_ram(0x0300, 16);       # Count maxed at 16
};

at_frame 2 => sub {
    # First 16 tiles appear (row 0, cols 0-15)
    assert_tile(0, 0, 0x01);
    assert_tile(15, 0, 0x10);

    # Last 4 dropped (nametable still 0)
    assert_tile(16, 0, 0x00);
    assert_tile(19, 0, 0x00);
};
```

#### Step 5.b: Verify Overflow Logic

**Tasks**:
1. Extend main to attempt 20 queue operations
2. Verify queue_tile checks `count >= 16` and skips
3. Confirm no buffer corruption

**Code pattern**:
```asm
main:
  ldx #0
queue_20:
  ; ... queue_tile logic ...
  ; (count check ensures only 16 actually queue)
  inx
  cpx #20
  bne queue_20
```

**Success Criteria**:
- [ ] Buffer count never exceeds 16
- [ ] First 16 tiles flush correctly
- [ ] Tiles 17-20 don't corrupt buffer or nametable

**Commit**: `feat(vram_buffer): Step 5 - buffer overflow handling`

---

### Step 6: NMI Integration

**Goal**: Prove buffer persists across frames until flushed

#### Step 6.a: Write Tests (t/05-nmi-timing.t)

**Test strategy**:
- Frame 1: Queue 3 tiles, assert NOT in nametable yet
- Frame 2: After NMI flush, assert tiles appear

**Test outline**:
```perl
at_frame 1 => sub {
    assert_ram(0x0300, 3);        # Queued
    assert_tile(0, 0, 0x00);      # Not flushed yet
};

at_frame 2 => sub {
    assert_ram(0x0300, 0);        # Cleared
    assert_tile(0, 0, 0x42);      # Flushed
};
```

#### Step 6.b: Verify NMI Timing

**Tasks**:
1. Confirm tiles queue during main loop (before first NMI)
2. Confirm flush happens in NMI handler (after vblank starts)
3. Verify buffer state visible across frames

**Code pattern**: (already implemented in Step 2, just verify timing)

**Success Criteria**:
- [ ] Tiles not visible until after NMI
- [ ] Buffer state persists between frames
- [ ] Flush only happens during vblank

**Commit**: `feat(vram_buffer): Step 6 - NMI integration timing`

---

## Risks

**Risk 1: assert_column fails (new helper)**
- **Mitigation**: Test with Step 4, validate helper works before complex scenarios
- **Fallback**: Use 30× assert_tile if helper broken

**Risk 2: Buffer address calculation bugs**
- **Mitigation**: Step-by-step validation (1 tile → 5 tiles → 30 tiles)
- **Fallback**: Manual calculation validation, add debug output

**Risk 3: Nametable mirroring issues**
- **Mitigation**: Only use $2000-$23BF (nametable 0, no mirroring needed)
- **Likelihood**: Low (single nametable)

**Risk 4: jsnes nametable exposure broken**
- **Mitigation**: Test infrastructure extended in this session (already validated)
- **Fallback**: Read jsnes source, verify vramMem exposure

---

## Dependencies

**Test infrastructure**:
- ✅ NES::Test.pm with assert_tile, assert_column (added this session)
- ✅ lib/nes-test-harness.js exposes nametable data (added this session)
- ✅ Phase 1 DSL validated across 7 toys (88/88 tests passing)

**Build infrastructure**:
- ✅ new-rom.pl scaffolding tool
- ✅ cc65 toolchain (ca65, ld65)
- ✅ Makefile patterns from toy0-7

**Knowledge**:
- ✅ learnings/graphics_techniques.md (lines 388-434: Incremental Updates pattern)
- ✅ learnings/timing_and_interrupts.md (vblank budget: 2273 cycles)
- ✅ NMI handler pattern from toy4_nmi

**No external blockers** - all dependencies satisfied
