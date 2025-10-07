#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../../lib";
use NES::Test;

load_rom "$Bin/../audio.nes";

# Test: 440 Hz tone generation (A note)
at_frame 10 => sub {
    assert_audio_playing();
    assert_frequency_near(440, 5);
};

done_testing();
