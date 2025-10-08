# toy8_vram_buffer

This toy validates a VRAM update buffering system. It provides a mechanism to queue nametable updates during gameplay and have them automatically flushed to the PPU during the NMI (vblank) period.

## Key Features Validated

- A simple RAM-based queue for storing VRAM updates (address + value).
- An NMI handler that reliably flushes the buffer to the PPU.
- Handling of various scenarios: single tile updates, multiple scattered tiles, and full column streaming.
- Correct behavior for buffer overflow (silently dropping new entries when full).
- NMI timing, ensuring that buffered writes are not visible until after the NMI handler has completed.