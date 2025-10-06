#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../nmi.nes";

# Test 2: Complex - Sprite animation
at_frame 1 => sub {
    assert_ram 0x0011 => 0x01;  # sprite_x = 1
    assert_sprite 0, x => 0x01; # OAM X position = 1
};

at_frame 10 => sub {
    assert_ram 0x0011 => 0x0A;  # sprite_x = 10
    assert_sprite 0, x => 0x0A; # OAM X position = 10
};

at_frame 60 => sub {
    assert_ram 0x0011 => 0x3C;  # sprite_x = 60 (1 second at 60fps)
    assert_sprite 0, x => 0x3C; # OAM X position = 60
};

done_testing();
