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
print "=" x 60 . "\n";

at_frame $frame => sub {};  # Trigger state update

# Now read palette via NES::Test internals
# We need to access the emulator_state directly - use eval to get package variable
my $state;
{
    no strict 'refs';
    $state = $ {'NES::Test::emulator_state'};
}

die "Failed to get emulator state\n" unless $state && $state->{palette};

# Backdrop
printf "  \$3F00 (backdrop):        0x%02X\n", $state->{palette}[0x00];
printf "  \$3F10 (backdrop mirror): 0x%02X\n", $state->{palette}[0x10];
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
