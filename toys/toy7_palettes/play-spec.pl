#!/usr/bin/env perl
use strict;
use warnings;

# Run all tests in t/ directory
exec 'prove', '-v', 't/';
