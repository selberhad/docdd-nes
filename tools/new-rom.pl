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

# Helper: Write template with @ROM@ substitution
sub write_tpl {
    my ($path, $content) = @_;
    $content =~ s/\@ROM\@/$rom_name/g;
    open my $fh, '>', $path or die "Failed to create $path: $!\n";
    print $fh $content;
    close $fh;
}

# Makefile
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

# nes.cfg (no substitution needed)
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

# Test spec
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

# Summary
print "✅ Created ROM scaffolding:\n";
print "   Makefile, nes.cfg, $rom_name.s, play-spec.pl\n\n";
print "📋 Next steps:\n";
print "   cd $dir\n";
print "   make              # Build ROM\n";
print "   perl play-spec.pl # Run tests\n\n";
