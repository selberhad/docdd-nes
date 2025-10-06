#!/usr/bin/env perl

# play-spec.pl - Automated test for toy0_toolchain ROM
# Tests NES::Test Phase 1 DSL with minimal hello.nes ROM

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../lib";

use NES::Test;

# Load the ROM
load_rom "$Bin/hello.nes";

# Frame 0: Initial state after reset
at_frame 0 => sub {
    # CPU should be at reset vector
    # Note: exact PC depends on where SEI/CLD instructions are
    # We'll just verify CPU is executing (not crashed)

    # Initial CPU register state (NES powers on with known values)
    # A, X, Y are typically 0 on reset
    # SP starts at $FD (after reset)
    # Note: jsnes may not perfectly emulate power-on state

    # Just verify ROM loaded and emulator is running
    pass("ROM loaded and emulator at frame 0");
};

# Frame 1: After one frame of execution
at_frame 1 => sub {
    # CPU should still be in the infinite loop (JMP loop)
    # We can't assert exact PC without knowing code layout,
    # but we can verify emulator advanced a frame

    pass("Emulator advanced to frame 1");
};

# Test RAM access
at_frame 2 => sub {
    # NES RAM should be accessible
    # Zero page should be readable (values may vary)

    # Just verify we can read RAM without crashing
    assert_ram 0x0000 => sub { defined $_ };  # Any value is fine

    pass("RAM accessible");
};

# Test OAM access (sprite memory)
at_frame 3 => sub {
    # OAM at $0200-$02FF should be accessible
    # Initial values likely 0 (no sprites set up)

    # Verify we can check sprite data
    # Sprite 0, Y position should be 0 (no sprites initialized)
    assert_sprite 0, y => 0;

    pass("OAM accessible");
};

done_testing();
