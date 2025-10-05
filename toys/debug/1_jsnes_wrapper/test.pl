#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON::PP;

# Test jsnes wrapper can run toy0 ROM and dump state

# Run wrapper
my $output = `node nes-headless.js ../../toy0_toolchain/hello.nes 2>&1`;
is($?, 0, "nes-headless.js exits successfully");

# Parse JSON output
my $state = eval { decode_json($output) };
ok($state, "JSON output parses correctly") or diag("Output: $output");

# Validate CPU state
ok(exists $state->{cpu}, "CPU state present");
ok(defined $state->{cpu}{pc}, "Program counter present");
ok(defined $state->{cpu}{a}, "Accumulator present");
ok(defined $state->{cpu}{sp}, "Stack pointer present");

# Validate PPU state
ok(exists $state->{ppu}, "PPU state present");
ok(defined $state->{ppu}{nmiOnVblank}, "PPU NMI flag present");

# Validate OAM dump
ok(exists $state->{oam}, "OAM data present");
is(ref($state->{oam}), 'ARRAY', "OAM is array");
is(scalar(@{$state->{oam}}), 16, "OAM has 16 bytes dumped");

# Test memory dump feature
$output = `node nes-headless.js ../../toy0_toolchain/hello.nes --dump-range=0000:000F 2>&1`;
is($?, 0, "nes-headless.js with --dump-range exits successfully");

$state = decode_json($output);
ok(exists $state->{memory}{range}, "Memory range dump present");
is($state->{memory}{range}{start}, 0, "Memory range start correct");
is($state->{memory}{range}{end}, 15, "Memory range end correct");
is(scalar(@{$state->{memory}{range}{bytes}}), 16, "Memory range has 16 bytes");

done_testing();
