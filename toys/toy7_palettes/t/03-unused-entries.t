#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../palette.nes";

# Test unused entry mirroring: $3F04/$3F08/$3F0C/$3F14/$3F18/$3F1C all mirror $3F00

at_frame 3 => sub {
    # Write to $3F04 should update $3F00 (and all other unused entries)
    assert_palette 0x3F04 => 0x16;
    assert_palette 0x3F00 => 0x16;  # Backdrop mirrors
    assert_palette 0x3F10 => 0x16;  # Sprite pal 0 entry 0 also mirrors
};

done_testing();
