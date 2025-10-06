# Toys Status

**Last updated**: 2025-10-06

## Test Suite: 51/51 passing (100%)

| Toy | Tests | Status | Notes |
|-----|-------|--------|-------|
| toy0_toolchain | 6/6 ✓ | Complete | Build pipeline |
| toy1_sprite_dma | 20/20 ✓ | Complete | OAM DMA |
| toy2_ppu_init | 5/5 ✓ | Complete | 2-vblank warmup |
| toy3_controller | 2/2 ✓ | Partial (timeboxed) | 6 tests skipped |
| toy4_nmi | 18/18 ✓ | Complete | NMI handler + integration |
| debug/0_survey | - | Complete | Emulator research |
| debug/1_jsnes_wrapper | - | Complete | jsnes harness (16 tests) |
| debug/2_tetanes | - | Complete | TetaNES investigation (rejected) |

## Next Candidates

1. **toy5_scrolling** - Background scrolling (nametables, PPUSCROLL)
2. **toy6_audio** - APU channels + FamiTone2 integration
3. **toy5_vram_buffer** - VRAM update buffer
4. **toy5_palettes** - Palette manipulation
