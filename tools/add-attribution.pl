#!/usr/bin/env perl
# Add NESdev wiki attribution to learnings docs

use strict;
use warnings;

my $file = $ARGV[0] or die "Usage: $0 <file>\n";
open my $fh, '<', $file or die "Can't read $file: $!\n";
my @lines = <$fh>;
close $fh;

my @pages;
for my $line (@lines) {
    if ($line =~ m{\.webcache/([^.]+)\.html}) {
        push @pages, $1;
    }
}

# Remove duplicates, preserve order
my %seen;
@pages = grep { !$seen{$_}++ } @pages;

if (@pages) {
    # Remove old reference sections
    @lines = grep {
        $_ !~ m{^\s*-\s+.*\.webcache/} &&
        $_ !~ m{^Refer to these cached} &&
        $_ !~ m{^\*\*Next steps\*\*:}
    } @lines;

    # Remove trailing blank lines
    pop @lines while @lines && $lines[-1] =~ /^\s*$/;

    # Add attribution section
    push @lines, "\n---\n\n";
    push @lines, "## Attribution\n\n";
    push @lines, "This document synthesizes information from the following NESdev Wiki pages:\n\n";
    for my $page (@pages) {
        push @lines, "- [$page](https://www.nesdev.org/wiki/$page)\n";
    }
    push @lines, "\n";
}

open $fh, '>', $file or die "Can't write $file: $!\n";
print $fh @lines;
close $fh;

print "Updated $file with " . scalar(@pages) . " attributions\n";
