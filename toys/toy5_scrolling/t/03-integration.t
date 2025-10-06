#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../scroll.nes";

# Test integration with toy4 NMI pattern

# Frame 4: First NMI has fired (toy4 finding)
at_frame 4 => sub {
    assert_ram 0x10 => 0x01;  # scroll_x = 1 (first NMI already fired)
    assert_ram 0x11 => 0x00;  # scroll_y = 0
};

# Frame 9: 6th NMI
at_frame 9 => sub {
    assert_ram 0x10 => 0x06;  # scroll_x = 6
};

# Frame 19: 16th NMI
at_frame 19 => sub {
    assert_ram 0x10 => 0x10;  # scroll_x = 16 (0x10)
};

done_testing();
