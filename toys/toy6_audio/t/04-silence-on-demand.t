#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../audio.nes";

# Test: Silence achieved by setting volume to 0
# ROM should be modified to silence at frame 150
at_frame 160 => sub {
    assert_silence();
};

done_testing();
