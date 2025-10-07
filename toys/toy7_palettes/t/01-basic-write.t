#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../palette.nes";

# Test basic palette writes via PPUADDR/PPUDATA
# Final state after all writes: $3F00=$16 (last write wins), $3F01=$30

at_frame 3 => sub {
    # Note: $3F00 gets written 3 times due to mirroring tests
    # Final value should be $16 (from $3F04 write)
    assert_palette 0x3F00 => 0x16;
    assert_palette 0x3F01 => 0x30;
};

done_testing();
