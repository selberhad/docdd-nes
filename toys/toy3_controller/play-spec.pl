#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../lib";

use NES::Test;

load_rom "$Bin/controller.nes";

# Test A button
press_button 'A';
at_frame 1 => sub {
    assert_ram 0x0010 => 0x80;  # A = bit 7
};

# Test B button
press_button 'B';
at_frame 2 => sub {
    assert_ram 0x0010 => 0x40;  # B = bit 6
};

# Test Start button
press_button 'Start';
at_frame 3 => sub {
    assert_ram 0x0010 => 0x10;  # Start = bit 4
};

# Test Up button
press_button 'Up';
at_frame 4 => sub {
    assert_ram 0x0010 => 0x08;  # Up = bit 3
};

# Test A+B combination
press_button 'A+B';
at_frame 5 => sub {
    assert_ram 0x0010 => 0xC0;  # A+B = bits 7+6
};

# Test Up+A combination
press_button 'Up+A';
at_frame 6 => sub {
    assert_ram 0x0010 => 0x88;  # Up+A = bits 3+7
};

# Test no buttons (should be 0)
at_frame 7 => sub {
    assert_ram 0x0010 => 0x00;  # No buttons
};

done_testing();
