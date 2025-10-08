#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../buffer.nes";

# Test: Multiple scattered tiles queued and flushed
# Queue 5 tiles at different coordinates, verify all appear after NMI

at_frame 4 => sub {
    assert_tile(1, 1, 0x10);
    assert_tile(15, 10, 0x20);
    assert_tile(0, 0, 0x30);
    assert_tile(31, 29, 0x40);
    assert_tile(10, 5, 0x50);
    assert_ram(0x0300, 0);        # Buffer cleared after flush
};

done_testing();
