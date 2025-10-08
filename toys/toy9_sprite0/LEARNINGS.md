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

3.  **How does the hit behave under different conditions?** (Future work)
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

## Findings

This toy successfully answered the primary questions it set out to investigate:

- **Q1: Can `jsnes` accurately emulate a sprite 0 hit?**
  - **Answer:** Yes. The test successfully validated that the PPUSTATUS sprite 0 hit flag is set when an opaque sprite overlaps an opaque background tile. This gives us confidence that we can write tests for more complex raster effects.

- **Q2: What is the best way to test for a sprite 0 hit with the `NES::Test` DSL?**
  - **Answer:** The existing `assert_ppu_status` assertion, when combined with a bitmask, is sufficient to test for the sprite 0 hit flag. No new DSL assertion was needed. This is a good outcome, as it means our existing DSL is more capable than we initially thought.

- **Q3: How does the hit behave under different conditions?**
  - **Answer:** This was not explored in this toy, and has been marked as a potential area for future investigation.

## Retrospective

This toy was a valuable exercise in debugging the test harness and understanding the PPU status register. However, it was a lot of work for a single assertion. In the future, we should avoid creating a new toy for a single assertion if it can be added to an existing toy's test suite. For example, this test could have been added to `toy1_sprite_dma`.
