#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../lib";
use NES::Test;

load_rom "$Bin/sprite0.nes";

# Test: Validate Sprite 0 Hit
at_frame 4 => sub {
    # PPUSTATUS ($2002), bit 6 is the sprite 0 hit flag.
    # We expect this to be set. We use a mask of 0x40 to check only that bit.
    assert_ppu_status(0x40, 0x40, "Sprite 0 hit flag should be set");
};

done_testing();