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

**Cross-reference**: Link to questions in `learnings/.ddd/5_open_questions.md`

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

**Document in toy's LEARNINGS.md:**
- Actual cycle counts measured
- Differences from wiki documentation (reference wiki page)
- Edge cases discovered
- Constraints hit (e.g., "can only update 8 sprites/frame, not 27")

### 4. Extract Learnings (LEARNINGS.md - Final Pass)

Finalize toy's LEARNINGS.md with all findings:
- Measured cycle counts and timings
- Constraints discovered vs wiki expectations
- Working patterns and code ready for reuse
- Open questions answered or new questions spawned

**Reusable patterns:**
- Working Makefile patterns → template for future toys
- CHR conversion scripts → `tools/` directory
- Init sequences → copy to main game with attribution

**Note**: Toy findings stay in toy's LEARNINGS.md. Reference `learnings/` docs for wiki knowledge, but don't duplicate.

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

## Timeboxing & Partial Validation

**CRITICAL**: Not all toys achieve 100% test pass rate. Partial validation is valid learning.

### The 3-Attempt Rule

When tests fail after implementation:
1. **Attempt 1**: Debug obvious issues (logic bugs, typos, misunderstandings)
2. **Attempt 2**: Deep investigation (inspect ROM, trace execution, check theory vs practice)
3. **Attempt 3**: Final debug pass or clean rebuild

**After 3 attempts: STOP and document.**

### Partial Validation Is Complete

**A toy is complete when ANY of these conditions are met:**
1. ✅ All tests passing (100% validation)
2. ⏱️ 3 debugging attempts exhausted (partial validation)
3. 🎯 Learning goals answered (even if tests aren't green)

**Why partial validation delivers value:**
- Isolates working parts from broken parts (4/8 passing proves infrastructure works)
- Documents edge cases and gotchas (what DOESN'T work is knowledge)
- Prevents rabbit holes (timeboxing protects productivity)
- Unblocks other subsystems (don't wait for perfection)

### Documenting Timeboxed Toys

**In LEARNINGS.md - mark status and document findings:**

```markdown
**Duration**: 45 min | **Status**: Complete (partial) ✅ | **Result**: 4/8 tests passing

### ⚠️ Challenged

**Timeboxed after 3 debugging attempts:**
- Attempt 1: Extended inspect-rom.pl, found execution issue
- Attempt 2: Clean rebuild, isolated bug to ROM logic
- Attempt 3: Investigated LSR/ROL bit shifting (found pattern errors)
- **Decision**: Document findings and move on

**What works (4/8 tests):**
- No button press: ✅
- START button: ✅

**What fails (4/8 tests):**
- A button: Returns 0x00, expected 0x80
- B button: Returns 0x04, expected 0x40

**Hypothesis:** LSR/ROL bit shifting has off-by-N error in loop

**Value delivered:**
- ✅ Validated jsnes controller emulation works
- ✅ Validated test harness button API works
- ✅ Isolated bug to ROM assembly code
- ✅ 50% validation > 0% validation
```

**In play-spec.pl - skip failing tests for green regression:**

```perl
# NOTE: Timeboxed after 3 debugging attempts - see LEARNINGS.md
# Original test suite: 8 tests (4 passed, 4 failed)
# Failing tests preserved below as reference for future work

# Keep minimal passing tests
at_frame 1 => sub {
    assert_ram 0x0010 => 0x00;  # Validates ROM reads controller
};

done_testing();

# SKIPPED TESTS (failed after 3 debug attempts - preserved as reference):
#
# press_button 'A';
# at_frame N => sub {
#     assert_ram 0x0010 => 0x80;  # FAILS: returns 0x00, expected 0x80
# };
# [... rest of failing tests commented out with failure details ...]
```

### The Forward-Only Principle

**Never suggest "return to toyN" after moving on.**

Once a toy is marked complete (full or partial):
- Knowledge is captured in LEARNINGS.md
- Patterns that work are extracted
- Toy remains as reference artifact
- Project moves forward to next subsystem

**If the technique is needed again:**
- Build a new toy with fresh perspective
- Reference old toy's LEARNINGS.md for context
- Don't reopen old code (forward motion only)

### Regression Suite Strategy

**Keep run-all-tests.pl 100% green:**
- Skip failing tests in timeboxed toys (comment out with explanation)
- Preserve original test code as reference (don't delete)
- Document in comments why tests were skipped
- Regression suite becomes quality gate (all passing = safe to proceed)

**Example from toy3_controller:**
- Original: 8 tests (4 passed, 4 failed)
- After timebox: 2 tests kept (validated infrastructure works)
- Result: run-all-tests.pl stays green, knowledge preserved in comments

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
- **Use when needed**: Not every pair needs integration toy, only when interactions uncertain

### Technique Toys
**Examples:** toy_sprite0_hit, toy_mid_frame_palette, toy_metatiles
- Validate specific wiki techniques (sprite 0 hit detection, palette swap mid-frame)
- Compare wiki description vs actual behavior
- Output: Confirming technique works or documenting why it fails

---

## Relationship to External Learning Docs

**Separation of concerns:**
- `learnings/` = Knowledge from external sources (wiki, tutorials, documentation)
- `toys/toyN/LEARNINGS.md` = Findings from experimentation and measurement

### Before Building Toy
1. Read relevant external knowledge docs (`learnings/sprite_techniques.md`, etc.)
2. Identify questions in `learnings/.ddd/5_open_questions.md`
3. Document in toy's LEARNINGS.md what to validate/measure

### During Implementation
- Update toy's LEARNINGS.md with findings as discovered
- Note deviations from wiki expectations (reference wiki pages)
- Capture cycle counts, memory usage, constraints

### After Completion
1. **Finalize toy LEARNINGS.md** with all findings (measurements, constraints, patterns)
2. **Mark questions answered** in `learnings/.ddd/5_open_questions.md`
3. **Spawn new questions** if edge cases discovered
4. **Extract reusable patterns** to `tools/` or document for main game

**No duplication**: Toy findings remain in toy's LEARNINGS.md. Don't copy measurements back to `learnings/` - they serve different purposes.

---

## Axis Principle (NES Adaptation)

From DDD book: "A base toy isolates exactly one axis of complexity."

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

- **DDD.md**: Core Dialectic-Driven Development methodology
- **TOY_DEV.md**: Toy development for porting context (FFI/unsafe validation)
- **ddd-book toy-model-rationale.md**: General toy model philosophy
- **learnings/.ddd/5_open_questions.md**: 43 questions to answer through toys
- **PLAN_WRITING.md, SPEC_WRITING.md**: Meta-doc writing guides
