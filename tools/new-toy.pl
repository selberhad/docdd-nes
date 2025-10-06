#!/usr/bin/env perl
use strict;
use warnings;

die "Usage: $0 <toy_name>\n" unless @ARGV == 1;
my $name = shift;
$name =~ s/^toy\d+_//; # Strip toy prefix if provided

# Find highest toyN number
my $max = -1;
opendir(my $dh, 'toys') or mkdir 'toys';
while (my $entry = readdir($dh)) {
    if ($entry =~ /^toy(\d+)_/) {
        $max = $1 if $1 > $max;
    }
}
closedir $dh;

my $num = $max + 1;
my $dir = "toys/toy${num}_${name}";
mkdir $dir or die "Failed to create $dir: $!\n";

# Template generator
sub write_doc {
    my ($file, $title, $content) = @_;
    open my $fh, '>', "$dir/$file" or die "Failed to create $file: $!\n";
    print $fh "# $title\n\n$content";
    close $fh;
}

write_doc('SPEC.md', 'SPEC — ' . ucfirst($name),
    "## Purpose\n\n## Input/Output\n\n## Success Criteria\n");

write_doc('PLAN.md', 'PLAN — ' . ucfirst($name),
    "## Steps\n\n1. [ ] \n\n## Risks\n\n## Dependencies\n");

write_doc('README.md', ucfirst($name) . ' (toy' . $num . ')',
    "**Quick context**: \n\n## What This Toy Does\n\n## Key APIs\n\n## Gotchas\n");

write_doc('LEARNINGS.md', 'LEARNINGS — ' . ucfirst($name),
    "## Learning Goals\n\n### Questions to Answer\n\n### Decisions to Make\n\n## Findings\n\n## Patterns for Production\n");

print "\n";
print "✅ Created $dir/\n";
print "   SPEC.md PLAN.md README.md LEARNINGS.md\n";
print "\n";
print "📋 Next steps for LLM:\n";
print "   1. Review TOY_DEV.md and TOY_DEV_NES.md (toy methodology)\n";
print "   2. Review relevant learnings/ docs for this subsystem\n";
print "   3. Check learnings/.docdd/5_open_questions.md for questions to answer\n";
print "   4. Reference docs/guides/ for SPEC, PLAN, LEARNINGS writing guidance\n";
print "   5. Start with LEARNINGS.md (define questions BEFORE planning)\n";
print "\n";
