#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../lib";

use NES::Test;

load_rom "$Bin/sprite_dma.nes";

# Frame 0: Before DMA
at_frame 0 => sub {
    # Verify shadow OAM populated
    assert_ram 0x0200 => 100;  # Sprite 0 Y
    assert_ram 0x0201 => 0x42; # Sprite 0 tile
    assert_ram 0x0202 => 0x01; # Sprite 0 attr
    assert_ram 0x0203 => 80;   # Sprite 0 X

    # PPU OAM should be empty (zeros or undefined)
    # NOTE: May need to verify jsnes initializes spriteMem to zeros
};

# Frame 1: After DMA
at_frame 1 => sub {
    # PPU OAM should match shadow OAM
    assert_sprite 0, y => 100, tile => 0x42, attr => 0x01, x => 80;
    assert_sprite 1, y => 110, tile => 0x43, attr => 0x02, x => 90;
    assert_sprite 2, y => 120, tile => 0x44, attr => 0x03, x => 100;
    assert_sprite 3, y => 130, tile => 0x45, attr => 0x00, x => 110;
};

done_testing();
