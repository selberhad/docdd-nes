#!/usr/bin/env perl
use strict;
use warnings;

# Test runner - uses prove to run all test scenarios
# Each scenario in t/*.t starts fresh emulator instance

exec 'prove', '-v', 't/';
