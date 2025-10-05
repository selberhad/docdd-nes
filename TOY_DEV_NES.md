# Toy Model Development for NES

_Test ROMs validate hardware behavior before integrating into main game. They are systematic experiments kept as reference artifacts._

---

## What Toy Models Are (NES Context)

- **Hardware validation tools**: Build minimal ROMs to verify PPU timing, sprite behavior, controller reads, etc.
- **Build infrastructure proofs**: Validate toolchain, Makefile patterns, asset pipelines before complexity
- **Constraint discovery**: Test cycle budgets, vblank timing, memory limits with real measurements
- **Reference implementations**: Keep as examples showing "this technique works on real hardware"
- **Theory-to-practice bridges**: Wiki says X cycles, toy measures actual timing in Mesen

## What Toy Models Are Not

- Not production game code (main game lives in `src/`, toys in `toys/`)
- Not comprehensive (one subsystem per toy, integration toys combine two validated subsystems)
- Not deleted after validation (permanent reference artifacts)
- Not theoretical (must run on emulator/hardware, produce measurable results)

---

## The NES Toy Cycle

**CRITICAL**: Start with learning goals, end with updated theory docs.

### 1. Define Learning Goals (LEARNINGS.md - First Pass)

Before building, document questions to answer:
- **Hardware questions**: "How many sprites can update in vblank?" (theory says ~27, measure reality)
- **Build questions**: "Does ca65 support this directive?" (docs unclear, test it)
- **Technique questions**: "Does sprite 0 hit work during scrolling?" (wiki examples conflict, verify)
- **Success criteria**: What measurements prove the technique works?

**Cross-reference**: Link to questions in `learnings/.docdd/5_open_questions.md`

### 2. Write Specifications (SPEC.md + PLAN.md)

- **SPEC**: What the ROM must do, what outputs to measure, success criteria
- **PLAN**: Step-by-step with test-first approach (Red → Green → Commit)
- **One axis**: Isolate single complexity (sprite DMA timing, NOT "sprite system with scrolling and input")
- **Integration toys**: Only after base toys validated (e.g., toy3 = toy1_sprite + toy2_controller)

### 3. Test-First Implementation

#### For Build Infrastructure (toolchain, Makefiles, asset pipelines):
**Use Perl + Test::More**
```perl
#!/usr/bin/env perl
use Test::More;
# Test build outputs: file sizes, exit codes, binary headers
is(system("ca65 hello.s -o hello.o"), 0, "assembles");
is(-s "hello.nes", 24592, "ROM size correct");
done_testing();
```

**Why Perl:**
- Core module (no deps), concise, perfect for file/process validation
- TAP output integrates with CI
- Matches utility belt philosophy (terse, powerful)

**What to test:**
- Command exit codes (ca65, ld65, asset converters)
- File existence, sizes, binary content (headers, magic bytes)
- Makefile targets (build, clean, dependency tracking)

**What NOT to test:**
- Emulator GUI behavior (manual validation)
- Visual output (human judgment)
- Debugger interaction (manual workflow)

#### For Hardware Behavior (PPU, APU, controller, timing):
**Manual validation in Mesen2**
- Load ROM, observe behavior
- Use debugger: breakpoints, cycle counter, memory watches
- Measure actual timings vs theory
- Screenshot comparisons for visual tests (if needed)

**Document in LEARNINGS.md:**
- Actual cycle counts measured
- Differences from wiki documentation
- Edge cases discovered
- Constraints hit (e.g., "can only update 8 sprites/frame, not 27")

### 4. Extract Learnings (LEARNINGS.md - Final Pass)

Update theory docs with findings:
- **learnings/sprite_techniques.md**: "OAM DMA takes exactly 513 cycles (tested in toy1)"
- **learnings/timing_and_interrupts.md**: "Vblank budget: 2273 cycles minus NMI overhead = 2260 usable (measured)"
- **Open questions**: Mark as answered or spawn new questions

**Reusable patterns:**
- Working Makefile patterns → template for future toys
- CHR conversion scripts → `tools/` directory
- Init sequences → copy to main game with attribution

---

## Testing Philosophy

### TDD for Infrastructure (Perl + Test::More)

**When applicable:**
- Toolchain validation (assemblers, linkers, converters)
- Build automation (Makefiles, shell scripts)
- Asset pipelines (graphics, music conversion)
- File format validation (iNES headers, CHR-ROM structure)

**Workflow:**
1. Write failing test (Red): `perl test.pl` → failures
2. Implement: Write code/config/Makefile
3. Run test (Green): `perl test.pl` → pass
4. Commit: `feat(toyN): Step X - description, tests passing`

**Pattern (toy0_toolchain example):**
```perl
# Test build pipeline
is(system("ca65 hello.s -o hello.o -g"), 0, "ca65 assembles");
ok(-f "hello.o", "object file created");
is(system("ld65 hello.o -C nes.cfg -o hello.nes"), 0, "ld65 links");

# Test ROM structure
is(-s "hello.nes", 24592, "ROM is 24592 bytes");
open my $fh, '<:raw', 'hello.nes';
read $fh, my $header, 4;
is(unpack('H*', $header), '4e45531a', 'iNES header magic');
```

**Makefile integration:**
```makefile
test: hello.nes
    perl test.pl
```

### Manual Validation for Hardware

**When applicable:**
- PPU behavior (scrolling, sprite rendering, palette changes)
- APU audio output (channel mixing, DMC timing)
- Controller input (polling timing, DPCM conflicts)
- Cycle counting (vblank budget, mid-frame techniques)

**Tools:**
- **Mesen2 debugger**: Breakpoints, step-through, memory watches
- **Cycle counter**: Measure actual timing (e.g., "OAM DMA start to finish")
- **Event viewer**: PPU operations, APU state changes
- **Memory tools**: Watch zero page, OAM, PPU registers in real-time

**Document in LEARNINGS.md:**
```markdown
## Evidence

### ✅ Validated
- OAM DMA: 513 cycles measured (Mesen cycle counter)
- Vblank NMI overhead: 7 cycles (breakpoint at NMI entry)

### ⚠️ Challenged
- Wiki says "update 64 sprites in vblank" - only achieved 27 (cycle budget exceeded)

### 🌀 Uncertain
- Does sprite 0 hit work reliably at X=255? (edge case untested)
```

---

## Patterns That Work (NES Toys)

### Build Infrastructure Toys
**Examples:** toy0_toolchain, toy_chr_pipeline, toy_music_build
- Validate assembler, linker, asset converters
- Test-driven with Perl (automated regression)
- Output: Working Makefile + scripts for main game

### Hardware Subsystem Toys
**Examples:** toy1_sprite_dma, toy2_controller, toy4_scrolling
- One NES subsystem per toy (PPU, APU, controller)
- Manual validation in Mesen2
- Output: Cycle counts, memory layouts, init sequences

### Integration Toys
**Examples:** toy3_sprite_input (sprite + controller), toy5_scroll_sprite (scrolling + sprites)
- Combine TWO validated base toys
- Test interaction/conflicts (e.g., DPCM vs controller reads)
- Only after base toys proven individually

### Technique Toys
**Examples:** toy_sprite0_hit, toy_mid_frame_palette, toy_metatiles
- Validate specific wiki techniques (sprite 0 hit detection, palette swap mid-frame)
- Compare wiki description vs actual behavior
- Output: Confirming technique works or documenting why it fails

---

## Integration with Learning Docs

### Before Building Toy
1. Read relevant theory docs (`learnings/sprite_techniques.md`, etc.)
2. Identify questions in `learnings/.docdd/5_open_questions.md`
3. Document in toy's LEARNINGS.md what to learn

### During Implementation
- Update toy's LEARNINGS.md with findings as discovered
- Note deviations from wiki/theory immediately
- Capture cycle counts, memory usage, constraints

### After Completion
1. **Update theory docs** with measured reality:
   - `learnings/sprite_techniques.md` ← cycle counts from toy1
   - `learnings/timing_and_interrupts.md` ← vblank measurements
2. **Mark questions answered** in `learnings/.docdd/5_open_questions.md`
3. **Spawn new questions** if edge cases discovered
4. **Extract patterns** to `tools/` or document for main game

---

## Axis Principle (NES Adaptation)

From DocDD book: "A base toy isolates exactly one axis of complexity."

**For NES:**
- **Build toys**: One tool/pipeline (assembler, graphics converter, music build)
- **Hardware toys**: One subsystem (PPU scrolling, sprite DMA, controller reads)
- **Integration toys**: Exactly two validated subsystems (their interaction is the axis)

**Examples:**
- ✅ toy1_sprite_dma: Just OAM DMA timing (one axis)
- ✅ toy2_controller: Just controller read sequence (one axis)
- ✅ toy3_sprite_input: Integration of toy1 + toy2 (interaction is one axis)
- ❌ toy_bad: Sprites + scrolling + controller + audio (four axes - split into separate toys)

---

## North Star

Toys are **experiments, not construction**.

Build minimal ROMs to validate assumptions, measure reality, and extract patterns. The ROM is disposable. The learnings (cycle counts, constraints, working patterns) are permanent.

When theory meets the NES cycle counter, update the theory.

---

## References

- **DDD.md**: Core Doc-Driven Development methodology
- **TOY_DEV.md**: Toy development for porting context (FFI/unsafe validation)
- **docdd-book toy-model-rationale.md**: General toy model philosophy
- **learnings/.docdd/5_open_questions.md**: 43 questions to answer through toys
- **PLAN_WRITING.md, SPEC_WRITING.md**: Meta-doc writing guides
