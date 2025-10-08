# LEARNINGS — Sprite 0 Hit Detection

## Learning Goals

This toy aims to validate the behavior of the NES's Sprite 0 hit feature, a fundamental technique for creating raster effects like status bars.

### Questions to Answer

1.  **Can `jsnes` accurately emulate a sprite 0 hit?**
    - Does the sprite 0 hit flag (PPUSTATUS bit 6) get set when an opaque sprite pixel overlaps an opaque background pixel?
    - Is the timing of the flag accurate enough for testing purposes?

2.  **What is the best way to test for a sprite 0 hit with the `NES::Test` DSL?**
    - Can we reliably detect the flag being set within a specific frame?
    - Will we need a new DSL assertion, like `assert_sprite0_hit_at_frame(N)` or similar, to abstract the polling logic?

3.  **How does the hit behave under different conditions?**
    - Does it work with different sprite and background palettes?
    - Can we verify the X=255 pixel bug (where the hit doesn't occur)?
    - How does the left-edge clipping (PPUMASK bits 1 & 2) affect detection?

### Decisions to Make

1.  **Test ROM Design:**
    - Create a simple ROM with a single, non-moving background tile and a single, non-moving sprite 0 placed to guarantee an overlap.
    - The ROM itself won't need to do much besides set up the PPU; the validation will happen entirely within the test harness.

2.  **Test Harness Strategy:**
    - The primary test will be to run the emulator to the frame where the hit should occur and inspect the PPUSTATUS register.
    - We will likely need to add a new helper to `NES::Test` to expose the PPU's internal status flags for assertion.

## Plan

1.  **SPEC.md:** Define the exact behavior: a ROM that sets up a guaranteed sprite 0 hit scenario.
2.  **PLAN.md:** Detail the implementation steps for the ROM and the test-first approach for the `play-spec.pl`.
3.  **Implementation:**
    - Write a `play-spec.pl` that attempts to assert the sprite 0 hit flag (this will fail initially).
    - Implement the simple assembly file (`sprite0.s`) to configure the PPU, palettes, background, and sprite 0 position.
    - Extend `NES::Test` if necessary to expose the PPU status flags.
    - Iterate until the test passes.