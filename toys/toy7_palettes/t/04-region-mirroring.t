#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../palette.nes";

# Test region mirroring: $3F00-$3F1F repeats at $3F20, $3F40, $3F60, etc.

at_frame 3 => sub {
    # $3F01 = $30, should be readable at +$20, +$40 mirrors
    assert_palette 0x3F01 => 0x30;
    assert_palette 0x3F21 => 0x30;  # +$20 mirror
    assert_palette 0x3F41 => 0x30;  # +$40 mirror

    # $3F00 also mirrors
    assert_palette 0x3F00 => 0x16;
    assert_palette 0x3F20 => 0x16;
    assert_palette 0x3F40 => 0x16;
};

done_testing();
