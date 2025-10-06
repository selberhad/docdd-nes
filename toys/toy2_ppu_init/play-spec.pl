#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../lib";

use NES::Test;

load_rom "$Bin/ppu_init.nes";

# Frame 1: After reset, before first vblank completes
at_frame 1 => sub {
    # PPU should be disabled
    assert_ppu_ctrl 0x00;
    assert_ppu_mask 0x00;

    # Marker should be 0 (init not complete)
    assert_ram 0x0010 => 0x00;
};

# Frame 2: After first vblank wait
at_frame 2 => sub {
    # First marker should be set
    assert_ram 0x0010 => 0x01;
};

# Frame 3: After second vblank wait
at_frame 3 => sub {
    # Second marker should be set (warmup complete)
    assert_ram 0x0010 => 0x02;
};

done_testing();
