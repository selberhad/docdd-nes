#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../nmi.nes";

# Test 1: Simple - Frame counter increments
at_frame 1 => sub {
    assert_ram 0x0010 => 0x01;  # frame_counter = 1
};

at_frame 2 => sub {
    assert_ram 0x0010 => 0x02;  # frame_counter = 2
};

at_frame 10 => sub {
    assert_ram 0x0010 => 0x0A;  # frame_counter = 10
};

done_testing();
