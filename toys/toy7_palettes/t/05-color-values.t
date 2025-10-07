#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../palette.nes";

# Test edge case color values
# $0D = "blacker than black" (should store as-is)
# $0F = canonical black

at_frame 3 => sub {
    # ROM writes $0D to $3F02, $0F to $3F03
    # Just verify they store correctly (no special handling in jsnes)
    assert_palette 0x3F02 => 0x0D;  # Blacker than black
    assert_palette 0x3F03 => 0x0F;  # Canonical black
};

done_testing();
