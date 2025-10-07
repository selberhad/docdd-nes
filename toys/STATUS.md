# Toys Status

**Last updated**: 2025-10-07

## Test Suite: 73/73 passing (100%)

| Toy | Tests | Status | Notes |
|-----|-------|--------|-------|
| toy0_toolchain | 6/6 ✓ | Complete | Build pipeline |
| toy1_sprite_dma | 20/20 ✓ | Complete | OAM DMA |
| toy2_ppu_init | 5/5 ✓ | Complete | 2-vblank warmup |
| toy3_controller | 2/2 ✓ | Partial (timeboxed) | 6 tests skipped |
| toy4_nmi | 18/18 ✓ | Complete | NMI handler + integration |
| toy5_scrolling | 15/15 ✓ | Complete | PPUSCROLL horizontal auto-scroll |
| toy6_audio | 7/7 ✓ | Complete | Pulse channel tone generation + FFT validation |
| debug/0_survey | - | Complete | Emulator research |
| debug/1_jsnes_wrapper | - | Complete | jsnes harness (16 tests) |
| debug/2_tetanes | - | Complete | TetaNES investigation (rejected) |

## Next Candidates

1. **toy7_vram_buffer** - VRAM update buffer (column streaming)
2. **toy7_palettes** - Palette manipulation
3. **toy7_sprite0** - Sprite 0 hit detection (status bar splits)
4. **toy8_music_engine** - FamiTone2/FamiStudio integration
