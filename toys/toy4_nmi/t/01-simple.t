#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../nmi.nes";

# Test 1: Simple - Frame counter increments
# Note: 4-frame init offset (2 vblank warmup + NMI enable + first vblank)
at_frame 4 => sub {
    assert_ram 0x0010 => 0x01;  # First NMI fired
};

at_frame 5 => sub {
    assert_ram 0x0010 => 0x02;  # Second NMI
};

at_frame 13 => sub {
    assert_ram 0x0010 => 0x0A;  # 10th NMI
};

done_testing();
