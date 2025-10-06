#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../nmi.nes";

# Test 2: Complex - Sprite animation
# Note: 4-frame init offset
at_frame 4 => sub {
    assert_ram 0x0011 => 0x01;  # sprite_x = 1
    assert_sprite 0, x => 0x01; # OAM X position = 1
};

at_frame 13 => sub {
    assert_ram 0x0011 => 0x0A;  # sprite_x = 10
    assert_sprite 0, x => 0x0A; # OAM X position = 10
};

at_frame 63 => sub {
    assert_ram 0x0011 => 0x3C;  # sprite_x = 60 (1 second at 60fps - 3 frames init)
    assert_sprite 0, x => 0x3C; # OAM X position = 60
};

done_testing();
