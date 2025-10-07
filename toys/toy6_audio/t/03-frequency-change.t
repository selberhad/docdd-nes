#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../audio.nes";

# Test: Frequency change (400 Hz → 800 Hz)
at_frame 10 => sub {
    assert_frequency_near(400, 5);
};

at_frame 20 => sub {
    assert_frequency_near(800, 5);
};

done_testing();
