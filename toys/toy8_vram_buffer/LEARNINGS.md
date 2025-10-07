# LEARNINGS — VRAM Buffer System

<!-- Read docs/guides/LEARNINGS_WRITING.md before writing this document -->

## Learning Goals

### Questions to Answer

**Q1: How much vblank time remains after OAM DMA for VRAM updates?**
- Total vblank budget: 2273 cycles (NTSC)
- OAM DMA cost: 513-514 cycles
- Scroll register updates: ~20 cycles
- **Expected remaining**: ~1740 cycles for VRAM updates
- **Need to measure**: How many tiles can actually fit in vblank?
  - Wiki says "~160 bytes via moderately unrolled loop"
  - Does this match practice? (Phase 2 cycle counting needed for precision)

**Q2: What buffer format is most efficient for NES?**
- **Option A**: Simple queue (addr_hi, addr_lo, tile_value) × N entries
  - Pros: Simple, flexible (any tile anywhere)
  - Cons: 3 bytes per tile, random access pattern
- **Option B**: RLE/compression (count, start_addr, values...)
  - Pros: Better for contiguous updates (columns/rows)
  - Cons: More complex, harder to debug
- **Option C**: Hybrid (header byte specifies format per entry)
  - Pros: Flexible (optimize per use case)
  - Cons: Complex to implement/maintain
- **Answer via**: Implement Option A first (YAGNI - measure before optimizing)

**Q3: How to handle buffer overflow?**
- **Scenario**: Game queues more updates than fit in vblank
- **Option A**: Drop oldest entries (FIFO)
- **Option B**: Drop newest entries (keep critical updates)
- **Option C**: Priority system (mark critical updates)
- **Option D**: Hard limit + warning (fail fast, fix game code)
- **Likely answer**: Option A or D (depends on game needs)

**Q4: Column/row streaming patterns for scrolling?**
- **Column streaming** (horizontal scroll): 30 tiles × 1 byte = 30 bytes
  - How many cycles to queue + flush?
  - Can we update full column per frame?
- **Row streaming** (vertical scroll): 32 tiles × 1 byte = 32 bytes
  - Similar timing questions
- **Answer via**: Implement column streaming, measure with new DSL helpers

**Q5: How to integrate with NMI handler?**
- **Pattern from learnings/graphics_techniques.md** (lines 404-433):
  - Game code queues updates during gameplay (outside vblank)
  - NMI handler flushes buffer during vblank
  - Clear queue counter after flush
- **Questions**:
  - Where to store buffer in RAM? (zero page? work RAM?)
  - How big should buffer be? (16 entries? 32? 64?)
  - **Answer via**: Start with 16-entry buffer in work RAM ($0300+)

**Q6: How to test buffer correctness with Phase 1 tools?**
- **Available**: assert_tile(), assert_column(), assert_nametable()
- **Not available**: Cycle counting (Phase 2 needed)
- **Testing strategy**:
  - Queue tiles → assert they appear in nametable
  - Queue column → assert all 30 tiles present
  - Queue overflow → assert behavior (drop or error)
  - **Limitation**: Can't measure precise cycle costs (document estimates)

### Decisions to Make

**D1: Buffer data structure**
- Start with **simple queue format**: (addr_hi, addr_lo, tile) × N
- Store in work RAM: $0300-$03FF (256 bytes = ~85 tiles max)
- Counter at $0300, entries start $0301
- Rationale: KISS - optimize later if needed

**D2: API design**
- **queue_tile(addr, tile)** - Add single tile to buffer
- **flush_buffer()** - Write all queued tiles via PPUADDR/PPUDATA
- **clear_buffer()** - Reset counter (implicit in flush)
- **Assembly interface** (not library - inline for cycle efficiency)

**D3: Overflow handling**
- **Decision**: Hard limit with silent drop (for toy)
- Buffer size: 16 entries (48 bytes)
- If full, ignore new entries (prevent corruption)
- Production games should track overflow and warn

**D4: Test scenarios (from NEXT_SESSION.md)**
- Single tile update
- Multiple scattered tiles
- Full column (30 tiles)
- Buffer overflow behavior
- Integration with NMI handler

## Findings

**Duration**: 1 session (partial) | **Status**: In Progress | **Result**: 2/2 tests passing (Step 2 complete)

### ✅ Validated

**V1: Single tile queue + flush works correctly**
- Evidence: t/01-single-tile.t passes (tile $42 appears at $2000, buffer clears)
- Buffer structure: $0300 (count) + $0301+ (entries × 3 bytes each)
- Flush timing: NMI handler writes queued tiles during vblank
- Pattern confirmed: Queue during gameplay → flush during NMI

**V2: New DSL helpers work perfectly**
- `assert_tile(x, y, value)`: Ergonomic tile coordinate assertions (no manual address calc)
- `assert_nametable($addr, value)`: Low-level PPU address assertions work
- Harness nametable exposure: jsnes vramMem[0x2000-0x23FF] accessible
- Token savings: `assert_tile(0, 0, 0x42)` vs calculating $2000 + comments

**V3: Buffer implementation matches SPEC**
- Queue logic: count * 3 offset calculation works
- Overflow check: `CPX #16` / `BCS skip` prevents buffer overflow
- Flush loop: Y-indexed iteration over entries works correctly
- Clear on flush: Setting count = 0 after flush confirmed

**V4: Frame timing understanding improved**
- Frame 0-2: PPU warmup (2 vblanks, NMI disabled)
- Frame 3+: NMI enabled, flush_buffer called each vblank
- Queue happens during main loop (before first NMI)
- Flush happens in NMI handler (during vblank)

### 🌀 Uncertain

**U1: How many tiles can actually flush in vblank?**
- Theory: ~160 bytes via unrolled loop (wiki estimate)
- Current: Unoptimized loop (no unrolling yet)
- Need Phase 2: Cycle counting to measure actual vblank budget
- Estimate: Current loop ~20 cycles/tile → 16 tiles ≈ 320 cycles (safe)

**U2: Column streaming (30 tiles) performance**
- Will 30 tiles fit in vblank budget? (Step 4 will test)
- Estimate: 30 × 20 cycles = 600 cycles (should fit in ~1760 available)
- Unknown: Actual cycle cost without Phase 2 measurement tools

### 📝 Implementation Notes

**Code organization:**
- Inline queue logic in main (not subroutine) - keeps test simple
- flush_buffer as subroutine - called from NMI handler
- Constants: BUFFER_COUNT, BUFFER_DATA, MAX_ENTRIES (clear addressing)

**Test strategy:**
- Focus on end state (frame 4) vs intermediate states
- NES RAM not zero-initialized (0xFF initial values) - learned in toy2
- Frame timing: Wait for NMI-enabled frames before checking results

**Next steps:**
- Step 3: Multiple scattered tiles (5 tiles at different coords)
- Step 4: Column streaming (30 tiles, validate assert_column helper)
- Step 5: Buffer overflow (20 tiles → 16 queued, 4 dropped)
- Step 6: NMI integration timing (verify persistence across frames)

## Patterns for Production

**Pattern 1: VRAM Update Buffer (Simple Queue)**

**Use case**: Defer nametable writes to vblank (avoid rendering glitches)

**Structure** (RAM $0300-$032F):
```
$0300:       count (0-16)
$0301-$0303: entry 0 (addr_hi, addr_lo, tile)
$0304-$0306: entry 1 (addr_hi, addr_lo, tile)
...
```

**Queue operation** (inline during gameplay):
```asm
; Check capacity
LDX BUFFER_COUNT
CPX #MAX_ENTRIES
BCS skip_queue          ; Full, silently drop

; Calculate offset: count * 3
TXA
ASL                     ; count * 2
STA temp
TXA
CLC
ADC temp                ; count * 3
TAX

; Store entry
LDA #addr_hi
STA BUFFER_DATA,X
LDA #addr_lo
STA BUFFER_DATA+1,X
LDA #tile_value
STA BUFFER_DATA+2,X

; Increment counter
INC BUFFER_COUNT
```

**Flush operation** (NMI handler, during vblank):
```asm
flush_buffer:
    LDX BUFFER_COUNT
    BEQ done

    LDY #0              ; Buffer offset
loop:
    BIT $2002           ; Reset latch
    LDA BUFFER_DATA,Y   ; addr_hi
    STA $2006
    INY
    LDA BUFFER_DATA,Y   ; addr_lo
    STA $2006
    INY
    LDA BUFFER_DATA,Y   ; tile
    STA $2007
    INY

    DEX
    BNE loop

    LDA #0
    STA BUFFER_COUNT    ; Clear buffer
done:
    RTS
```

**Integration**:
- Game code: Queue tiles during rendering (outside vblank)
- NMI handler: Call flush_buffer first thing in vblank
- Overflow: Silent drop (production: add overflow flag/warning)

**Cycle estimate**: ~20 cycles/tile (unoptimized loop)
- 16 tiles: ~320 cycles
- 30 tiles: ~600 cycles (column streaming)
- Vblank budget: ~1760 cycles available (2273 - 513 OAM DMA)

**Memory cost**: 49 bytes (1 count + 16 entries × 3)

**Trade-offs**:
- Pro: Simple, predictable, easy to debug
- Pro: Flexible (any tile anywhere)
- Con: 3 bytes per tile (no compression)
- Con: Random access pattern (no optimization for sequential writes)

**When to use**: Most games (scrolling, HUD updates, level changes)

**When not to use**: Full-screen redraws (use double buffering instead)
