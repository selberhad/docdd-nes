#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../scroll.nes";

# Test horizontal auto-scroll: scroll_x increments each frame

# Frame 4: First NMI has fired (toy4 finding - 4-frame init offset)
at_frame 4 => sub {
    assert_ram 0x10 => 0x01;  # scroll_x = 1 (first NMI already fired)
    assert_ram 0x11 => 0x00;  # scroll_y = 0
};

# Frame 5: Second NMI
at_frame 5 => sub {
    assert_ram 0x10 => 0x02;  # scroll_x = 2
};

# Frame 13: 10th NMI (frame 4 + 9 = 10 NMIs total)
at_frame 13 => sub {
    assert_ram 0x10 => 0x0A;  # scroll_x = 10
};

# Frame 67: 64th NMI
at_frame 67 => sub {
    assert_ram 0x10 => 0x40;  # scroll_x = 64
};

# Frame 131: 128th NMI
at_frame 131 => sub {
    assert_ram 0x10 => 0x80;  # scroll_x = 128
};

done_testing();
