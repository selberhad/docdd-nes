#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../overflow.nes";

# Test: NMI timing validation
# Verify tiles are not visible until AFTER the NMI handler flushes the buffer.

# Frame 3: main loop has run, buffer is full.
# NMI has not yet run, so nametable should be empty.
at_frame 3 => sub {
    # Buffer has 16 entries, waiting for flush
    assert_ram(0x0300, 16, "Buffer is full before NMI");

    # Nametable is still empty
    assert_tile(0, 0, 0x00, "Tile (0,0) is empty before NMI");
    assert_tile(15, 0, 0x00, "Tile (15,0) is empty before NMI");
};

# Frame 4: NMI has run, buffer has been flushed.
# Nametable should now contain the tiles.
at_frame 4 => sub {
    # Buffer is now empty
    assert_ram(0x0300, 0, "Buffer is empty after NMI");

    # Nametable is populated
    assert_tile(0, 0, 0x01, "Tile (0,0) is populated after NMI");
    assert_tile(15, 0, 0x10, "Tile (15,0) is populated after NMI");
};

done_testing();
