# PLAN — toy9_sprite0

This plan follows a test-driven approach to validate Sprite 0 hit detection.

## Step 1: Scaffold the ROM and Initial Failing Test

- **Action:** Use `tools/new-rom.pl sprite0` to create the basic ROM files (`sprite0.s`, `nes.cfg`, `Makefile`, `play-spec.pl`).
- **Test:** Write the initial `play-spec.pl`. This test will load the ROM and assert that the Sprite 0 hit flag is set at a specific frame (e.g., frame 4). This test is expected to fail because the ROM is empty.
- **Commit:** `feat(sprite0): Step 1 - initial ROM scaffold and failing test`

## Step 2: Basic PPU and Background Setup

- **Action:** In `sprite0.s`, add the standard PPU initialization code:
  - Wait for VBlank twice.
  - Set up a simple palette.
  - Load a single, opaque tile into the background nametable.
  - Enable background rendering in PPUMASK (`$2001`).
- **Test:** The `play-spec.pl` will still fail, but we can manually inspect the ROM in an emulator to confirm a solid background is being drawn.
- **Commit:** `feat(sprite0): Step 2 - render solid background`

## Step 3: Add Sprite 0 and Validate Hit

- **Action:** In `sprite0.s`:
  - Enable sprite rendering in PPUMASK.
  - Place a single, opaque sprite (Sprite 0) at a position that guarantees overlap with the background (e.g., Y=30, X=30).
- **Test:** Run `play-spec.pl`. At this point, the Sprite 0 hit should occur. We may need to adjust the test to check the PPU status register correctly. If `NES::Test` doesn't expose this, we will need to modify it.
- **Commit:** `feat(sprite0): Step 3 - add sprite 0 and validate hit`

## Step 4: Finalize and Document

- **Action:**
  - Clean up the code and add comments.
  - Update `LEARNINGS.md` with the findings from the implementation.
  - Update the `README.md` with a summary of the toy.
- **Commit:** `feat(sprite0): complete toy9 (N/N tests passing)`