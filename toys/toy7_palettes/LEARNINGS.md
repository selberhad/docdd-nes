# LEARNINGS — Palettes

<!-- Read docs/guides/LEARNINGS_WRITING.md before writing this document -->

## Learning Goals

**Goal**: Understand NES palette RAM structure, mirroring behavior, and access patterns via PPUADDR/PPUDATA. Validate hardware quirks documented in wiki through automated testing.

**Vision**: Build palette manipulation patterns that work reliably for runtime palette changes, mid-frame effects, and palette animation in main game.

### Questions to Answer

**Q1: How do palette writes work via PPUADDR + PPUDATA?**
- Set address to $3F00-$3F1F via two writes to $2006
- Write color values via $2007
- Does write order matter? (high byte first, then low byte)
- Can we write multiple palette entries sequentially without re-setting address?
- **Answer via**: Write test ROM, read back palette values, verify against expected

**Q2: Does $3F00 = $3F10 mirroring work as documented?**
- Wiki says: backdrop color ($3F00) shares storage with sprite palette 0, entry 0 ($3F10)
- Writing to either address should update both
- Reading from either should return same value
- **Answer via**: Write to $3F00, read from $3F10; write to $3F10, read from $3F00

**Q3: Can we read palette RAM back via PPUDATA?**
- Set address to $3F00 via $2006
- Read via $2007 (with dummy read?)
- Does jsnes accurately emulate palette readback?
- **Answer via**: Write known values, read back, compare

**Q4: What are the mirroring quirks for unused palette entries?**
- Wiki mentions: $3F04/$3F08/$3F0C (BG palette 1-3, entry 0) are unused
- Wiki mentions: $3F14/$3F18/$3F1C (sprite palette 1-3, entry 0) are unused
- Do these mirror to $3F00? Are they writable but ignored?
- **Answer via**: Write to these addresses, read back, check behavior

**Q5: Does $3F20-$3FFF mirroring work?**
- Wiki says: entire $3F00-$3FFF region mirrors the 32-byte palette
- $3F20 should mirror $3F00, $3F21 mirrors $3F01, etc.
- How far does mirroring extend? (full $3F00-$3FFF = 256 bytes mirroring 32 bytes)
- **Answer via**: Write to $3F00, read from $3F20/$3F40/$3F60, verify same value

**Q6: What color values are valid?**
- Wiki says: 6-bit values $00-$3F (64 colors)
- Wiki warns: $0D = "blacker than black" (avoid)
- Wiki says: $0F = canonical black
- Do invalid values ($40-$FF) wrap or produce undefined behavior?
- **Answer via**: Test edge cases ($00, $0D, $0F, $3F, $40, $FF)

**Q7: Can we test palettes with jsnes + automated assertions?**
- Phase 1 scope: can jsnes expose palette RAM for assertions?
- Need to add palette inspection to nes-test-harness.js
- Need to add assert_palette() to NES::Test.pm
- **Answer via**: Extend test DSL, validate with simple palette test

### Decisions to Make

**D1: Test infrastructure approach**
- **Option A**: Add palette RAM exposure to jsnes harness (Phase 1, automated)
- **Option B**: Use shadow palette RAM in ROM, test via assert_ram (indirect)
- **Option C**: Defer to Phase 3 (manual Mesen2 validation)
- **Decision**: Option A - extend Phase 1 DSL for full automation

**D2: Assertion granularity**
- **Option A**: `assert_palette(address, expected)` - one entry at a time
- **Option B**: `assert_palette_bg(pal_num, color_num, expected)` - semantic helpers
- **Option C**: `assert_palette_array(start, [values])` - bulk validation
- **Decision**: All three - composable layers (low/mid/high level)

**D3: Test coverage scope**
- Minimum: Basic writes, backdrop mirroring, single mirror test
- Medium: All mirroring quirks, readback, unused entries
- Maximum: Edge cases, invalid values, sequential writes, timing
- **Decision**: Medium coverage - validate all wiki claims, defer exotic edge cases

## Findings

### Infrastructure Complete (Step 1-2)

**✅ Phase 1 DSL Extended for Palette Testing**
- Extended `lib/nes-test-harness.js` to expose `nes.ppu.vramMem[0x3F00-0x3F1F]` as palette array
- Added `assert_palette(addr, expected)` to `lib/NES/Test.pm`
- Supports address mirroring: `(addr - 0x3F00) & 0x1F` wraps $3F20+ to 0-31 range
- Palette data successfully transmitted via JSON from Node.js harness to Perl test module

**✅ Q1: Palette writes via PPUADDR + PPUDATA work**
- Standard pattern: `LDA #$3F; STA $2006; LDA #$00; STA $2006; LDA #$0F; STA $2007`
- Sequential writes auto-increment (PPUCTRL bit 2 default = increment by 1)
- No dummy read needed for palette writes (unlike CHR-ROM reads)
- jsnes accurately emulates basic palette write behavior

**✅ Q7: jsnes palette testing validated**
- jsnes stores palette in `ppu.vramMem[0x3F00-0x3F1F]`
- Palette data accessible via test harness (32-byte array)
- `assert_palette()` works correctly (tested with 0x2D write → reads back 45 decimal)
- DEBUG=1 confirmed: palette array transmitted correctly through JSON protocol

**⚠️ Q2-Q5: Palette mirroring behavior unclear**
- Initial assumption about unused entry mirroring ($3F04 → $3F00) not working as expected
- Got 0x2D from $3F00 (last write to $3F10) instead of 0x16 (from $3F04)
- **Theory vs Practice gap**: Wiki documentation may differ from jsnes implementation
- **Next step**: Use `tools/dump-palette.pl` to inspect full palette state and understand actual mirroring

**Debugging tools created:**
- `tools/dump-palette.pl` - palette RAM inspector (needs refinement)
- DEBUG=1 tracing in harness + NES::Test.pm

### Open Questions

**Palette mirroring implementation:**
- Does jsnes implement backdrop mirroring ($3F00 = $3F10)?
- How does jsnes handle unused entries ($3F04, $3F08, $3F0C, $3F14, $3F18, $3F1C)?
- Does $3F20+ region mirroring work in jsnes?
- Need to read jsnes ppu.js `writeMem()` function to understand actual behavior

**Next session priorities:**
1. Investigate jsnes palette mirroring implementation (read ppu.js writeMem for $3F00-$3FFF range)
2. Update ROM and tests to match actual jsnes behavior (not wiki theory)
3. Document jsnes-specific quirks vs hardware
4. Complete remaining test scenarios

## Patterns for Production

**Palette write pattern (validated):**
```asm
; Write single palette entry
BIT $2002       ; Reset PPUADDR latch
LDA #$3F
STA $2006       ; High byte
LDA #$addr_low
STA $2006       ; Low byte ($3F00-$3F1F)
LDA #color
STA $2007       ; Write color value

; Sequential writes (auto-increment)
; After first write, subsequent $2007 writes auto-increment address
```

**Test infrastructure pattern:**
```perl
use NES::Test;
load_rom "rom.nes";

at_frame 3 => sub {
    assert_palette 0x3F00 => 0x0F;  # Backdrop
    assert_palette 0x3F01 => 0x30;  # BG pal 0, color 1
};
```

**Debugging pattern:**
```bash
# Enable detailed tracing
env DEBUG=1 prove -v t/test.t

# Outputs:
# [DEBUG] palette slice length: 32, first few: [45,48,0,0]  # jsnes harness
# [DEBUG-PERL] palette type: ARRAY, length: 32               # Perl module
# [DEBUG-PERL] palette[0]=45                                  # Actual value
```
