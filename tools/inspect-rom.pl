#!/usr/bin/env perl
use strict;
use warnings;

# iNES ROM header inspector
# Decodes and displays iNES header format for .nes files

die "Usage: $0 <rom.nes> [rom2.nes ...]\n" unless @ARGV;

my @roms = @ARGV;

for my $rom_path (@roms) {
    unless (-f $rom_path) {
        warn "File not found: $rom_path\n";
        next;
    }

    print "=" x 70 . "\n";
    print "ROM: $rom_path\n";
    print "=" x 70 . "\n";

    open my $fh, '<:raw', $rom_path or die "Cannot open $rom_path: $!\n";

    # Read 16-byte iNES header
    my $header;
    my $bytes_read = read($fh, $header, 16);

    if ($bytes_read != 16) {
        warn "Failed to read 16-byte header from $rom_path\n";
        close $fh;
        next;
    }

    # Unpack header bytes
    my @bytes = unpack('C16', $header);

    # Display raw hex
    print "\nRaw header (16 bytes):\n";
    printf "  %02X %02X %02X %02X  %02X %02X %02X %02X  %02X %02X %02X %02X  %02X %02X %02X %02X\n",
        @bytes;

    # Parse iNES format
    my ($n, $e, $s, $magic_1a, $prg, $chr, $flags6, $flags7, $prg_ram, $flags9, $flags10, @rest) = @bytes;

    # Validate magic number
    print "\nHeader validation:\n";
    if ($n == 0x4E && $e == 0x45 && $s == 0x53 && $magic_1a == 0x1A) {
        print "  ✓ Magic number: 'NES' 0x1A (valid iNES header)\n";
    } else {
        printf "  ✗ Magic number: %02X %02X %02X %02X (INVALID - not iNES format)\n", $n, $e, $s, $magic_1a;
    }

    # Decode fields
    print "\nROM configuration:\n";
    printf "  PRG-ROM:  %d x 16KB = %d KB (%d bytes)\n", $prg, $prg * 16, $prg * 16384;
    printf "  CHR-ROM:  %d x 8KB  = %d KB (%d bytes)\n", $chr, $chr * 8, $chr * 8192;
    printf "  PRG-RAM:  %d x 8KB  = %d KB (battery-backed)\n", $prg_ram || 1, ($prg_ram || 1) * 8;

    # Flags 6 (byte 6)
    my $mirroring = ($flags6 & 0x01) ? 'Vertical' : 'Horizontal';
    my $battery   = ($flags6 & 0x02) ? 'Yes' : 'No';
    my $trainer   = ($flags6 & 0x04) ? 'Yes (512 bytes)' : 'No';
    my $four_screen = ($flags6 & 0x08) ? 'Yes' : 'No';
    my $mapper_low = ($flags6 & 0xF0) >> 4;

    print "\nFlags 6 (byte 6 = 0x" . sprintf("%02X", $flags6) . "):\n";
    print "  Mirroring:    $mirroring\n";
    print "  Battery:      $battery\n";
    print "  Trainer:      $trainer\n";
    print "  Four-screen:  $four_screen\n";
    print "  Mapper (low): $mapper_low\n";

    # Flags 7 (byte 7)
    my $vs_unisystem = ($flags7 & 0x01) ? 'Yes' : 'No';
    my $playchoice   = ($flags7 & 0x02) ? 'Yes' : 'No';
    my $nes2         = (($flags7 & 0x0C) == 0x08) ? 'Yes (NES 2.0)' : 'No (iNES)';
    my $mapper_high  = ($flags7 & 0xF0) >> 4;

    print "\nFlags 7 (byte 7 = 0x" . sprintf("%02X", $flags7) . "):\n";
    print "  VS Unisystem: $vs_unisystem\n";
    print "  PlayChoice:   $playchoice\n";
    print "  Format:       $nes2\n";
    print "  Mapper (high): $mapper_high\n";

    # Mapper number
    my $mapper = ($mapper_high << 4) | $mapper_low;
    my $mapper_name = get_mapper_name($mapper);
    print "\nMapper:\n";
    print "  Number: $mapper ($mapper_name)\n";

    # Flags 9 (byte 9) - TV system
    my $tv_system = ($flags9 & 0x01) ? 'PAL' : 'NTSC';
    print "\nTV System (byte 9):\n";
    print "  $tv_system\n";

    # File size validation
    my $expected_size = 16 + ($prg * 16384) + ($chr * 8192);
    if ($trainer eq 'Yes (512 bytes)') {
        $expected_size += 512;
    }

    seek $fh, 0, 2;  # Seek to end
    my $actual_size = tell $fh;

    print "\nFile size:\n";
    printf "  Expected: %d bytes (header + PRG + CHR%s)\n",
        $expected_size, ($trainer eq 'Yes (512 bytes)' ? ' + trainer' : '');
    printf "  Actual:   %d bytes\n", $actual_size;

    if ($actual_size == $expected_size) {
        print "  ✓ Size matches header\n";
    } else {
        print "  ✗ Size mismatch (CORRUPTED or INVALID)\n";
    }

    # Read reset vectors from end of PRG-ROM
    # Vectors are at $FFFA-$FFFF (last 6 bytes of PRG-ROM)
    # File offset: 16 (header) + (PRG size - 6)
    my $prg_size = $prg * 16384;
    my $vector_offset = 16 + $prg_size - 6;

    seek $fh, $vector_offset, 0;
    my $vectors;
    if (read($fh, $vectors, 6) == 6) {
        my @vec_bytes = unpack('C6', $vectors);
        my $nmi_vector   = $vec_bytes[0] | ($vec_bytes[1] << 8);
        my $reset_vector = $vec_bytes[2] | ($vec_bytes[3] << 8);
        my $irq_vector   = $vec_bytes[4] | ($vec_bytes[5] << 8);

        print "\nHardware Vectors (at \$FFFA-\$FFFF):\n";
        printf "  NMI   (\$FFFA): \$%04X  [%02X %02X]\n", $nmi_vector, $vec_bytes[0], $vec_bytes[1];
        printf "  RESET (\$FFFC): \$%04X  [%02X %02X]  ← CPU starts here\n", $reset_vector, $vec_bytes[2], $vec_bytes[3];
        printf "  IRQ   (\$FFFE): \$%04X  [%02X %02X]\n", $irq_vector, $vec_bytes[4], $vec_bytes[5];

        # Show first 16 bytes at reset vector (if it points into PRG-ROM)
        if ($reset_vector >= 0x8000 && $reset_vector < 0x8000 + $prg_size) {
            my $code_offset = 16 + ($reset_vector - 0x8000);
            seek $fh, $code_offset, 0;
            my $code_sample;
            if (read($fh, $code_sample, 16) == 16) {
                my @code_bytes = unpack('C16', $code_sample);
                print "\nCode at RESET vector (\$" . sprintf("%04X", $reset_vector) . "):\n  ";
                printf "%02X " x 16, @code_bytes;
                print "\n";
            }
        }
    }

    close $fh;

    print "\n";
}

sub get_mapper_name {
    my ($num) = @_;
    my %mappers = (
        0 => 'NROM (no mapper)',
        1 => 'MMC1',
        2 => 'UNROM',
        3 => 'CNROM',
        4 => 'MMC3',
        7 => 'AxROM',
        9 => 'MMC2',
        10 => 'MMC4',
        11 => 'Color Dreams',
        66 => 'GxROM',
        71 => 'Camerica',
    );
    return $mappers{$num} || 'Unknown';
}
