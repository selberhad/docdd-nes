#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../scroll.nes";

# Test wraparound: scroll_x wraps at 256 (0xFF → 0x00 → 0x01)

# Frame 257: 254th NMI (frame 4 + 253 = 254)
at_frame 257 => sub {
    assert_ram 0x10 => 0xFE;  # scroll_x = 254
};

# Frame 258: 255th NMI
at_frame 258 => sub {
    assert_ram 0x10 => 0xFF;  # scroll_x = 255
};

# Frame 259: 256th NMI - wraparound
at_frame 259 => sub {
    assert_ram 0x10 => 0x00;  # scroll_x = 0 (wrapped)
};

# Frame 260: 257th NMI
at_frame 260 => sub {
    assert_ram 0x10 => 0x01;  # scroll_x = 1
};

# Frame 263: 260th NMI
at_frame 263 => sub {
    assert_ram 0x10 => 0x04;  # scroll_x = 4
};

done_testing();
