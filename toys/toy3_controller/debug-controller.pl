#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../lib";

use NES::Test;

# Access internal emulator state via package variable
sub get_state {
    no strict 'refs';
    return ${"NES::Test::emulator_state"};
}

load_rom "$Bin/controller.nes";
set_verbosity(2);  # Enable debug logging

# Check initial state
at_frame 0 => sub {
    my $state = get_state();
    my $marker = $state->{cpu}{mem}[0x0012] // 'undef';
    my $counter = $state->{cpu}{mem}[0x0011] // 'undef';
    my $pc = $state->{cpu}{pc};

    print "# Frame 0:\n";
    print "#   CPU PC = " . sprintf("0x%04X", $pc) . "\n";
    print "#   Debug marker (0x0012) = $marker (5 = loop entered)\n";
    print "#   Loop counter (0x0011) = $counter (should increment)\n";
    print "#   First 16 bytes of RAM: ";
    for my $i (0..15) {
        my $val = $state->{cpu}{mem}[$i] // '??';
        printf "%02s ", ref($val) ? '??' : sprintf("%02X", $val);
    }
    print "\n";
};

# Test A button with debug output
print "\n# Testing A button (index 0, should be 0x41 when pressed)\n";
press_button 'A';
at_frame 2 => sub {
    my $state = get_state();
    my $marker = $state->{cpu}{mem}[0x0012];
    my $counter = $state->{cpu}{mem}[0x0011];
    my $buttons = $state->{cpu}{mem}[0x0010];

    print "# Frame 2:\n";
    print "#   Debug marker (0x0012) = $marker (5 = loop entered)\n";
    print "#   Loop counter (0x0011) = $counter (should be > 0)\n";
    print "#   Button byte (0x0010) = " . sprintf("0x%02x", $buttons) . " (expected 0x80)\n";
};

# Test Up button
print "\n# Testing Up button (index 4, should be 0x41 when pressed)\n";
press_button 'Up';
at_frame 3 => sub {
    my $state = get_state();
    my $marker = $state->{cpu}{mem}[0x0012];
    my $counter = $state->{cpu}{mem}[0x0011];
    my $buttons = $state->{cpu}{mem}[0x0010];

    print "# Frame 3:\n";
    print "#   Debug marker (0x0012) = $marker (5 = loop entered)\n";
    print "#   Loop counter (0x0011) = $counter (should be > 0)\n";
    print "#   Button byte (0x0010) = " . sprintf("0x%02x", $buttons) . " (expected 0x08)\n";
};

done_testing();
