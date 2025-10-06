#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../nmi.nes";

# Test 3: Wraparound - Counter overflow at 256
at_frame 255 => sub {
    assert_ram 0x0010 => 0xFF;  # frame_counter = 255
};

at_frame 256 => sub {
    assert_ram 0x0010 => 0x00;  # Wrapped to 0
};

at_frame 257 => sub {
    assert_ram 0x0010 => 0x01;  # Wrapped, now incrementing again
};

done_testing();
