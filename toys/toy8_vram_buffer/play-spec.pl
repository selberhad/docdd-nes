#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../lib";
use NES::Test;

load_rom "$Bin/buffer.nes";

# Add test assertions here
at_frame 0 => sub {
    # Example: assert_ram 0x0010 => 0x00;
};

done_testing();
