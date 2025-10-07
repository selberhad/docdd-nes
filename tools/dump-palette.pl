#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use NES::Test;

my $rom_path = $ARGV[0] or die "Usage: $0 <rom.nes> [frame]\n";
my $frame = $ARGV[1] || 3;

load_rom $rom_path;

print "Palette RAM at frame $frame:\n";
print "=" x 70 . "\n";

at_frame $frame => sub {};  # Trigger state update

# Now read palette via NES::Test internals
my $state;
{
    no strict 'refs';
    $state = $ {'NES::Test::emulator_state'};
}

die "Failed to get emulator state\n" unless $state && $state->{palette};

# Show all 8 backdrop mirror addresses (should all be identical on hardware)
print "Backdrop mirrors (hardware: all 8 should match):\n";
for my $addr (0x3F00, 0x3F04, 0x3F08, 0x3F0C, 0x3F10, 0x3F14, 0x3F18, 0x3F1C) {
    my $idx = $addr - 0x3F00;
    printf "  \$%04X: 0x%02X (%3d)\n", $addr, $state->{palette}[$idx], $state->{palette}[$idx];
}
print "\n";

# BG palettes
print "BG Palettes:\n";
for my $pal (0..3) {
    my $base = $pal * 4;
    printf "  Pal %d: ", $pal;
    for my $col (0..3) {
        my $idx = $base + $col;
        printf "\$3F%02X=0x%02X ", $idx, $state->{palette}[$idx];
    }
    print "\n";
}
print "\n";

# Sprite palettes
print "Sprite Palettes:\n";
for my $pal (0..3) {
    my $base = 0x10 + ($pal * 4);
    printf "  Pal %d: ", $pal;
    for my $col (0..3) {
        my $idx = $base + $col;
        printf "\$3F%02X=0x%02X ", $idx, $state->{palette}[$idx];
    }
    print "\n";
}
