#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../overflow.nes";

# Test: Buffer overflow handling
# Queue 20 tiles, verify only 16 are accepted (buffer full at 16)

at_frame 4 => sub {
    # After flush, first 16 tiles appear (row 0, cols 0-15)
    assert_tile(0, 0, 0x01);
    assert_tile(1, 0, 0x02);
    assert_tile(15, 0, 0x10);

    # Last 4 dropped (nametable still 0)
    assert_tile(16, 0, 0x00);
    assert_tile(17, 0, 0x00);
    assert_tile(18, 0, 0x00);
    assert_tile(19, 0, 0x00);

    # Buffer cleared after flush
    assert_ram(0x0300, 0);
};

done_testing();
