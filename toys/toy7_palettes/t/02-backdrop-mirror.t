#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../palette.nes";

# Test backdrop mirroring: $3F00 = $3F10
# Note: $3F00 gets overwritten by $3F04 write later, but $3F10 reflects final value

at_frame 3 => sub {
    # Both should have same value (last write to either address)
    # Final value is $16 from $3F04 write
    assert_palette 0x3F00 => 0x16;
    assert_palette 0x3F10 => 0x16;
};

done_testing();
