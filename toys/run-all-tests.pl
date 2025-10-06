#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use Cwd qw(abs_path);

# Find all play-spec.pl files in toy directories
my $toys_dir = abs_path(dirname(__FILE__));
my @test_files;
my @missing;

# Scan for toyN_* directories
opendir(my $dh, $toys_dir) or die "Cannot open toys/: $!\n";
while (my $entry = readdir($dh)) {
    next unless $entry =~ /^toy\d+_/;
    next unless -d "$toys_dir/$entry";

    my $spec = "$toys_dir/$entry/play-spec.pl";
    if (-f $spec) {
        push @test_files, $spec;
    } else {
        push @missing, $entry;
    }
}
closedir $dh;

# Also check debug/ subdirectories
if (-d "$toys_dir/debug") {
    opendir(my $debug_dh, "$toys_dir/debug") or die "Cannot open toys/debug/: $!\n";
    while (my $entry = readdir($debug_dh)) {
        next if $entry =~ /^\./;
        next unless -d "$toys_dir/debug/$entry";

        my $spec = "$toys_dir/debug/$entry/play-spec.pl";
        if (-f $spec) {
            push @test_files, $spec;
        } else {
            push @missing, "debug/$entry";
        }
    }
    closedir $debug_dh;
}

# Report
print "=" x 70 . "\n";
print "TOY REGRESSION TEST SUITE\n";
print "=" x 70 . "\n";
print "\n";
print "Found " . scalar(@test_files) . " test(s) to run\n";
if (@missing) {
    print "Warning: " . scalar(@missing) . " toy(s) missing play-spec.pl:\n";
    print "  - $_\n" for @missing;
}
print "\n";

# Use prove to run tests (standard Perl test harness)
if (@test_files) {
    exec 'prove', '-v', @test_files;
} else {
    print "No tests found!\n";
    exit 1;
}
