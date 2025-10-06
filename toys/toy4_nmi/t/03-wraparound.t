#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../nmi.nes";

# Test 3: Wraparound - Counter overflow at 256
# Note: 4-frame init offset
at_frame 258 => sub {
    assert_ram 0x0010 => 0xFF;  # frame_counter = 255 (258 - 3 init)
};

at_frame 259 => sub {
    assert_ram 0x0010 => 0x00;  # Wrapped to 0
};

at_frame 260 => sub {
    assert_ram 0x0010 => 0x01;  # Wrapped, now incrementing again
};

done_testing();
