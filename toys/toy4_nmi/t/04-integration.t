#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../nmi.nes";

# Test 4: Integration - Both counters update together
at_frame 1 => sub {
    assert_ram 0x0010 => 0x01;  # Frame counter
    assert_ram 0x0011 => 0x01;  # Sprite X
    assert_sprite 0, x => 0x01; # OAM matches
};

at_frame 10 => sub {
    assert_ram 0x0010 => 0x0A;  # Both incremented
    assert_ram 0x0011 => 0x0A;
    assert_sprite 0, x => 0x0A; # All synchronized
};

done_testing();
