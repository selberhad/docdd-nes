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

<!-- Fill after implementation -->

## Patterns for Production

<!-- Fill after implementation -->
