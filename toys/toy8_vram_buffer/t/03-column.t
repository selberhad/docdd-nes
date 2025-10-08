#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../buffer.nes";

# Test: Column streaming (30 tiles in column 5)
# Queue full column (rows 0-29), verify all appear after NMI

at_frame 4 => sub {
    my @expected = (0x01..0x1E);  # 30 tiles: $01..$1E
    assert_column(5, \@expected);
    assert_ram(0x0300, 0);        # Buffer cleared after flush
};

done_testing();
