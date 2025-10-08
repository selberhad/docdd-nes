#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;

die "Usage: $0 <rom_name> [target_dir]\n" unless @ARGV >= 1;

my $name = shift;
my $dir = shift || '.';
die "Target directory $dir doesn't exist\n" unless -d $dir;

my $rom_name = $name;
$rom_name =~ s/\.nes$//;

print "Scaffolding ROM '$rom_name' in $dir/\n\n";

# Check if this is a second ROM in same directory
my $makefile_exists = -f "$dir/Makefile";
my $playspec_exists = -f "$dir/play-spec.pl";

# Helper: Write template with @ROM@ substitution
sub write_tpl {
    my ($path, $content) = @_;
    $content =~ s/\@ROM\@/$rom_name/g;
    open my $fh, '>', $path or die "Failed to create $path: $!\n";
    print $fh $content;
    close $fh;
}

# Makefile
if ($makefile_exists) {
    print "⚠️  Makefile exists - appending new ROM target\n";

    # Read existing Makefile
    open my $fh, '<', "$dir/Makefile" or die "Can't read Makefile: $!\n";
    my $makefile = do { local $/; <$fh> };
    close $fh;

    # Extract ROMS variable if it exists, or create it
    my $roms_line;
    if ($makefile =~ /^ROMS\s*=\s*(.+)$/m) {
        my $existing_roms = $1;
        $roms_line = "ROMS = $existing_roms $rom_name.nes";
        $makefile =~ s/^ROMS\s*=\s*.+$/$roms_line/m;
    } else {
        # No ROMS variable yet - extract first ROM name from existing Makefile
        my ($first_rom) = $makefile =~ /^ROM\s*=\s*(\S+)/m;
        $roms_line = "ROMS = $first_rom $rom_name.nes";

        # Insert ROMS variable after CFG_FILE
        $makefile =~ s/(^CFG_FILE\s*=.+$)/$1\n$roms_line/m;
    }

    # Update 'all' target to build all ROMs
    $makefile =~ s/^all:.+$/all: \$(ROMS)/m;

    # Update 'clean' target to remove all build artifacts
    if ($makefile =~ /^clean:\s*$/m) {
        $makefile =~ s/^clean:\s*\n\s*rm -f.+$/ clean:\n\trm -f *.o *.nes *.dbg *.lst/m;
    }

    # Append new ROM-specific targets
    my $new_targets = <<EOF;

# $rom_name ROM targets
${rom_name}.o: ${rom_name}.s
\t\$(CA65) \$(CA65_FLAGS) \$< -o \$\@

${rom_name}.nes: ${rom_name}.o \$(CFG_FILE)
\t\$(LD65) \$< -C \$(CFG_FILE) -o \$\@ --dbgfile ${rom_name}.dbg
EOF

    $makefile .= $new_targets;

    # Write updated Makefile
    open $fh, '>', "$dir/Makefile" or die "Can't write Makefile: $!\n";
    print $fh $makefile;
    close $fh;

} else {
    # First ROM - create fresh Makefile
    write_tpl("$dir/Makefile", <<'EOF');
# Makefile for @ROM@ - NES ROM build
# Assembles @ROM@.s with ca65, links with ld65 using custom nes.cfg

# Paths (macOS Homebrew cc65)
CA65 = /opt/homebrew/bin/ca65
LD65 = /opt/homebrew/bin/ld65
MESEN = /Applications/Mesen.app/Contents/MacOS/Mesen

# Source files
ASM_SRC = @ROM@.s
CFG_FILE = nes.cfg
ROM = @ROM@.nes
OBJ = @ROM@.o
DBG = @ROM@.dbg

# Build flags
CA65_FLAGS = -g
LD65_FLAGS = --dbgfile $(DBG)

all: $(ROM)

$(OBJ): $(ASM_SRC)
	$(CA65) $(CA65_FLAGS) $< -o $@

$(ROM): $(OBJ) $(CFG_FILE)
	$(LD65) $(OBJ) -C $(CFG_FILE) -o $@ $(LD65_FLAGS)

clean:
	rm -f $(OBJ) $(ROM) $(DBG) *.lst

run: $(ROM)
	open -a Mesen $(ROM)

test: $(ROM)
	perl play-spec.pl

.PHONY: all clean run test
EOF
}

# nes.cfg (only create if doesn't exist - shared between ROMs)
unless (-f "$dir/nes.cfg") {
    write_tpl("$dir/nes.cfg", <<'EOF');
# NROM linker config (16KB PRG + 8KB CHR)

MEMORY {
    HEADER: start=$0000, size=$0010, fill=yes, fillval=$00, file=%O;
    PRG:    start=$8000, size=$3FFA, fill=yes, fillval=$FF, file=%O;
    ROMV:   start=$FFFA, size=$0006, fill=yes, file=%O;
    CHR:    start=$0000, size=$2000, fill=yes, fillval=$00, file=%O;
}

SEGMENTS {
    HEADER:  load=HEADER, type=ro;
    CODE:    load=PRG,    type=ro;
    VECTORS: load=ROMV,   type=ro;
    CHARS:   load=CHR,    type=ro;
}
EOF
}

# Assembly skeleton
write_tpl("$dir/$rom_name.s", <<'EOF');
; @ROM@ - NES ROM skeleton

.segment "HEADER"
    .byte "NES", $1A
    .byte $01, $01, $00, $00
    .res 8, $00

.segment "CODE"

reset:
    SEI
    CLD
    LDX #$FF
    TXS

    INX  ; X = 0
    STX $2000  ; PPUCTRL = 0
    STX $2001  ; PPUMASK = 0
    BIT $2002  ; Clear vblank

    ; Wait 2 vblanks
vblankwait1:
    BIT $2002
    BPL vblankwait1
vblankwait2:
    BIT $2002
    BPL vblankwait2

loop:
    JMP loop

nmi_handler:
irq_handler:
    RTI

.segment "VECTORS"
    .word nmi_handler, reset, irq_handler

.segment "CHARS"
    .res 8192, $00
EOF

# Test spec (only create if doesn't exist)
unless ($playspec_exists) {
    write_tpl("$dir/play-spec.pl", <<'EOF');
#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../../lib";
use NES::Test;

load_rom "$Bin/@ROM@.nes";

# Add test assertions here
at_frame 0 => sub {
    # Example: assert_ram 0x0010 => 0x00;
};

done_testing();
EOF

    chmod 0755, "$dir/play-spec.pl";
}

# Summary
print "\n✅ ROM scaffolding complete:\n";
if ($makefile_exists) {
    print "   - Updated Makefile with $rom_name.nes target\n";
} else {
    print "   - Created Makefile\n";
}
print "   - Created $rom_name.s (assembly skeleton)\n";
print "   - nes.cfg " . ($makefile_exists ? "(shared)\n" : "(created)\n");
unless ($playspec_exists) {
    print "   - Created play-spec.pl\n";
}

print "\n📋 Next steps:\n";
print "   cd $dir\n";
print "   make              # Build all ROMs\n";
if ($playspec_exists) {
    print "   prove -v t/       # Run tests (t/ directory exists)\n";
} else {
    print "   perl play-spec.pl # Run tests\n";
}
print "\n";
