#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../audio.nes";

# Test: 400 Hz tone sustained over time
at_frame 50 => sub {
    assert_audio_playing();
    assert_frequency_near(400, 5);
};

done_testing();
