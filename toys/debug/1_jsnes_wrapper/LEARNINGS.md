# Learning Goals: jsnes Headless Wrapper

**Created**: October 2025
**Toy**: toys/debug/1_jsnes_wrapper
**Purpose**: Build Node.js CLI wrapper around jsnes for automated ROM testing

---

## Questions to Answer

**Q1**: Can jsnes run headlessly in Node.js?
- ✅ **ANSWERED**: Yes, runs perfectly with no browser/GUI needed

**Q2**: What API does jsnes expose for state inspection?
- ✅ **ANSWERED**: Direct object access (documented below)

**Q3**: Can we dump memory and registers as JSON?
- ✅ **ANSWERED**: Yes, trivial with Node.js JSON.stringify()

**Q4**: Is jsnes accurate enough for our testing needs?
- ⚠️ **PARTIAL**: Basic functionality works, accuracy vs Mesen2 not yet validated

**Q5**: How fast is jsnes execution?
- ✅ **ANSWERED**: Instant for 1 frame (no noticeable delay)

---

## jsnes API Documentation

### NES Object Structure

```javascript
const nes = new jsnes.NES({ onFrame: ..., onAudioSample: ... });
nes.loadROM(romData);
nes.frame();  // Run one frame
```

### CPU State Access

```javascript
nes.cpu.REG_PC      // Program Counter
nes.cpu.REG_ACC     // Accumulator (A register)
nes.cpu.REG_X       // X register
nes.cpu.REG_Y       // Y register
nes.cpu.REG_SP      // Stack Pointer
nes.cpu.REG_STATUS  // Status register
nes.cpu.mem[addr]   // CPU memory (64KB array, 0x0000-0xFFFF)
```

### PPU State Access

```javascript
nes.ppu.f_nmiOnVblank      // NMI on VBlank flag
nes.ppu.f_spriteSize       // Sprite size (0=8x8, 1=8x16)
nes.ppu.f_bgPatternTable   // Background pattern table address
nes.ppu.f_spPatternTable   // Sprite pattern table address
nes.ppu.f_addrInc          // VRAM address increment
nes.ppu.spriteMem[addr]    // OAM (sprite memory, 256 bytes)
nes.ppu.vramMem[addr]      // VRAM (nametables, palette, etc.)
```

**Key finding**: PPU registers are NOT memory-mapped at 0x2000+ in jsnes. They're direct object properties.

### Limitations Discovered

1. **No cycle counter**: jsnes doesn't expose total cycle count (only returns cycles per instruction during emulation)
2. **No frame count**: No built-in frame counter property
3. **Memory-mapped I/O**: CPU memory at 0x2000-0x401F is `undefined` (not mapped like real NES)

---

## Implementation

### nes-headless.js

**Features**:
- Loads .nes ROM file
- Runs N frames (default: 1)
- Dumps state as JSON:
  - CPU registers (PC, A, X, Y, SP, status)
  - PPU flags (NMI, sprite size, pattern tables, addr increment)
  - OAM (first 16 bytes)
  - Optional memory range dump (`--dump-range=START:END`)

**Usage**:
```bash
node nes-headless.js rom.nes [--frames=N] [--dump-range=0000:00FF]
```

**Output** (JSON):
```json
{
  "cpu": { "pc": 32769, "a": 0, "x": 0, "y": 0, "sp": 511, "status": 40 },
  "ppu": { "nmiOnVblank": 0, "spriteSize": 0, ... },
  "oam": [0, 0, 0, ...],
  "memory": { "range": { "start": 0, "end": 15, "bytes": [...] } }
}
```

### test.pl

**Tests** (16 passing):
- ✅ Wrapper exits successfully
- ✅ JSON output parses correctly
- ✅ CPU state present (PC, A, SP)
- ✅ PPU state present (NMI flag, etc.)
- ✅ OAM dump present (16 bytes)
- ✅ Memory range dump works (`--dump-range` flag)

**Pattern**: Perl spawns Node.js process, parses JSON, runs Test::More assertions.

---

## Findings

### Successes

1. **✅ True headless**: No GUI, no browser, pure Node.js CLI
2. **✅ Direct API access**: Simpler than FCEUX Lua (no scripting layer)
3. **✅ Fast**: Instant execution (no noticeable delay for 1 frame)
4. **✅ Easy integration**: `node wrapper.js` → JSON → Perl `decode_json()` → assertions
5. **✅ Clean JSON**: Easy to parse, inspect, debug

### Challenges

1. **⚠️ No cycle counter**: Can't measure exact cycle counts (would need to instrument jsnes CPU)
2. **⚠️ Memory-mapped I/O missing**: PPU registers not at 0x2000+ (different from real NES)
3. **⚠️ Accuracy unknown**: Haven't validated jsnes vs Mesen2 for correctness

### Comparison vs FCEUX Lua

| Feature | jsnes | FCEUX Lua |
|---------|-------|-----------|
| Headless | ✅ True (Node.js) | ❌ GUI required |
| API | ✅ Direct object access | ⚠️ Lua scripting layer |
| Cycle counter | ❌ Not exposed | ✅ `debugger.getcyclescount()` |
| Speed | ✅ Instant | ⚠️ GUI overhead |
| Accuracy | ⚠️ Unknown | ✅ Cycle-accurate |
| Setup | ✅ `npm install` | ⚠️ 61 Homebrew deps |

**Verdict**: jsnes wins for basic testing, FCEUX wins for cycle-accurate validation.

---

## Next Steps

### Immediate: Validate Accuracy

Compare jsnes vs Mesen2 for toy0 ROM:
- Run toy0 in Mesen2, note CPU/PPU state after 1 frame
- Run toy0 with jsnes wrapper, compare output
- If different: Document discrepancies, decide if acceptable

### If Accurate: Generalize

1. Move `nes-headless.js` to `tools/nes-test.js`
2. Create `tools/nes-test.pl` wrapper for convenient Perl usage
3. Document pattern in TOY_DEV_NES.md
4. Use for future toy validation (toy1_sprite_dma, etc.)

### If Inaccurate: Fallback

1. Document where jsnes differs from Mesen2
2. Fallback to FCEUX Lua (toys/debug/2_fceux_lua)
3. Or: Find Rust NES emulator with headless support

---

## Artifacts Created

**Code**:
- `nes-headless.js` - Node.js CLI wrapper (100 lines)
- `test.pl` - Perl tests (16 tests passing)
- `inspect.js` - jsnes API inspection tool
- `package.json` - npm dependencies

**Documentation**:
- This LEARNINGS.md

**Dependencies**:
- `jsnes@^1.2.1` (npm package)
- `JSON::PP` (core Perl module)
- `Test::More` (core Perl module)

---

## Recommendation

**✅ PROCEED with jsnes** for basic hardware validation, with caveats:
- Use for: Memory state, register values, basic functionality
- NOT for: Precise cycle counting (jsnes doesn't expose it)
- Validate: Compare toy0 output with Mesen2 before trusting

**Fallback ready**: If jsnes proves inaccurate, FCEUX Lua is proven alternative (GUI overhead acceptable).
