#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../palette.nes";

# Test basic palette writes via PPUADDR/PPUDATA

at_frame 3 => sub {
    assert_palette 0x3F00 => 0x0F;  # Backdrop = black
    assert_palette 0x3F01 => 0x30;  # BG pal 0, color 1 = white
};

done_testing();
