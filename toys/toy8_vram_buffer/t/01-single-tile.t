#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../buffer.nes";

# Test: Single tile queue + flush
# After ROM boots, tile is queued and flushed by NMI

at_frame 4 => sub {
    assert_tile(0, 0, 0x30);      # Tile flushed to nametable (Step 3: now queues 0x30)
    assert_ram(0x0300, 0);        # Buffer cleared after flush
};

done_testing();
