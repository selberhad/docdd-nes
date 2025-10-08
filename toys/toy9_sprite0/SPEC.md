# SPEC — toy9_sprite0

## Behavior

This toy demonstrates a minimal, verifiable Sprite 0 hit.

1.  The ROM shall configure the PPU to display both a background and sprites.
2.  A single, opaque background tile shall be drawn across the entire nametable.
3.  A single, opaque 8x8 sprite (Sprite 0) shall be placed at a fixed screen position where it is guaranteed to overlap the background.
4.  When the ROM is run in a compatible emulator, the PPU's Sprite 0 Hit flag (bit 6 of PPUSTATUS, `$2002`) shall be set on the scanline where the overlap occurs.

## Testable Assertions

- At a specific frame `N` (after PPU warmup and rendering has begun):
  - The PPUSTATUS register (`$2002`) should have bit 6 set, indicating a sprite 0 hit occurred during that frame.