#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Test: ca65 assembles without error
is(system("ca65 hello.s -o hello.o -g 2>/dev/null"), 0, "ca65 assembles hello.s");
ok(-f "hello.o", "hello.o created");

# Test: ld65 links without error
is(system("ld65 hello.o -C nes.cfg -o hello.nes --dbgfile hello.dbg 2>/dev/null"), 0,
   "ld65 links to hello.nes");

# Test: ROM file size (16 byte header + 16KB PRG + 8KB CHR)
is(-s "hello.nes", 24592, "ROM is exactly 24592 bytes");

# Test: iNES header magic bytes
open my $fh, '<:raw', 'hello.nes' or die "Cannot open hello.nes: $!";
read $fh, my $header, 4;
is(unpack('H*', $header), '4e45531a', 'iNES header magic correct (NES<EOF>)');
close $fh;

# Test: Debug symbols exist
ok(-f "hello.dbg", "Debug symbols file created");

# Test: Makefile builds correctly
system("make clean >/dev/null 2>&1");  # Clean first
is(system("make >/dev/null 2>&1"), 0, "Makefile builds successfully");
ok(-f "hello.nes", "make produces hello.nes");

# Test: make clean removes artifacts
system("make >/dev/null 2>&1");  # Ensure files exist
system("make clean >/dev/null 2>&1");
ok(!-f "hello.nes", "make clean removes hello.nes");
ok(!-f "hello.o", "make clean removes hello.o");
ok(!-f "hello.dbg", "make clean removes hello.dbg");

# Test: Invalid assembly syntax fails
system("cp hello.s hello.s.bak");
open my $bad, '>>', 'hello.s' or die $!;
print $bad "\nINVALID_INSTRUCTION_XYZ\n";
close $bad;
isnt(system("ca65 hello.s -o hello_bad.o 2>/dev/null"), 0,
     "ca65 fails on invalid syntax");
system("mv hello.s.bak hello.s");

# Test: Missing linker config fails
isnt(system("ld65 hello.o -o hello_bad.nes 2>/dev/null"), 0,
     "ld65 fails without config");

# Clean up test artifacts
unlink("hello_bad.o", "hello_bad.nes");

done_testing();
