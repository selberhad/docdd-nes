#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;

die "Usage: $0 <rom_name> [target_dir]\n" unless @ARGV >= 1;

my $name = shift;
my $dir = shift || '.';

# Validate we're in a reasonable directory
die "Target directory $dir doesn't exist\n" unless -d $dir;

my $rom_name = $name;
$rom_name =~ s/\.nes$//;  # Strip .nes if provided

print "Scaffolding ROM '$rom_name' in $dir/\n\n";

# ===== Makefile =====
open my $mf, '>', "$dir/Makefile" or die "Failed to create Makefile: $!\n";
print $mf <<'EOF';
# Makefile for @ROM@ - NES ROM build
# Assembles @ROM@.s with ca65, links with ld65 using custom nes.cfg

# Paths (macOS Homebrew cc65)
# NOTE: Homebrew installs to /opt/homebrew on Apple Silicon
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
CA65_FLAGS = -g               # Generate debug symbols
LD65_FLAGS = --dbgfile $(DBG) # Output debug file

# Default target
all: $(ROM)

# Assemble .s -> .o
$(OBJ): $(ASM_SRC)
	$(CA65) $(CA65_FLAGS) $< -o $@

# Link .o -> .nes
$(ROM): $(OBJ) $(CFG_FILE)
	$(LD65) $(OBJ) -C $(CFG_FILE) -o $@ $(LD65_FLAGS)

# Clean build artifacts
clean:
	rm -f $(OBJ) $(ROM) $(DBG) *.lst

# Run ROM in Mesen2
run: $(ROM)
	open -a Mesen $(ROM)

# Run test suite
test: $(ROM)
	perl play-spec.pl

.PHONY: all clean run test
EOF

# Substitute ROM name
seek $mf, 0, 0;
my $makefile = do { local $/; <$mf> };
close $mf;
$makefile =~ s/\@ROM\@/$rom_name/g;

open $mf, '>', "$dir/Makefile" or die $!;
print $mf $makefile;
close $mf;

# ===== nes.cfg (standard NROM layout - matches toy0-3) =====
open my $cfg, '>', "$dir/nes.cfg" or die "Failed to create nes.cfg: $!\n";
print $cfg <<'EOF';
# Minimal NES linker config for toy0_toolchain
# Maps segments to NROM memory layout (16KB PRG + 8KB CHR)

MEMORY {
    # iNES header (16 bytes)
    HEADER: start=$0000, size=$0010, fill=yes, fillval=$00, file=%O;

    # PRG-ROM: 16KB starting at $8000 (NROM-128 layout)
    # Reserve last 6 bytes for vectors at $FFFA-$FFFF
    PRG:    start=$8000, size=$3FFA, fill=yes, fillval=$FF, file=%O;

    # Hardware vectors at $FFFA-$FFFF (end of PRG-ROM)
    ROMV:   start=$FFFA, size=$0006, fill=yes, file=%O;

    # CHR-ROM: 8KB (graphics data)
    CHR:    start=$0000, size=$2000, fill=yes, fillval=$00, file=%O;
}

SEGMENTS {
    HEADER:  load=HEADER, type=ro;
    CODE:    load=PRG,    type=ro;
    VECTORS: load=ROMV,   type=ro;
    CHARS:   load=CHR,    type=ro;
}
EOF
close $cfg;

# ===== Minimal .s skeleton =====
open my $asm, '>', "$dir/$rom_name.s" or die "Failed to create $rom_name.s: $!\n";
print $asm <<'EOF';
; @ROM@ - NES ROM skeleton

.segment "HEADER"
    .byte "NES", $1A
    .byte $01           ; 1x 16KB PRG-ROM
    .byte $01           ; 1x 8KB CHR-ROM
    .byte $00           ; Mapper 0, horizontal mirroring
    .byte $00
    .res 8, $00

.segment "CODE"

reset:
    SEI                 ; Disable IRQs
    CLD                 ; Clear decimal mode

    ; Initialize stack
    LDX #$FF
    TXS

    ; Disable PPU
    INX                 ; X = 0
    STX $2000           ; PPUCTRL = 0 (NMI disabled)
    STX $2001           ; PPUMASK = 0 (rendering disabled)

    ; Clear vblank flag
    BIT $2002

    ; Wait first vblank
vblankwait1:
    BIT $2002
    BPL vblankwait1

    ; Wait second vblank
vblankwait2:
    BIT $2002
    BPL vblankwait2

    ; PPU ready, fall through to main loop

loop:
    JMP loop

nmi_handler:
irq_handler:
    RTI

.segment "VECTORS"
    .word nmi_handler
    .word reset
    .word irq_handler

.segment "CHARS"
    .res 8192, $00
EOF

# Substitute ROM name in comments
seek $asm, 0, 0;
my $asm_content = do { local $/; <$asm> };
close $asm;
$asm_content =~ s/\@ROM\@/$rom_name/g;

open $asm, '>', "$dir/$rom_name.s" or die $!;
print $asm $asm_content;
close $asm;

# ===== play-spec.pl template =====
open my $spec, '>', "$dir/play-spec.pl" or die "Failed to create play-spec.pl: $!\n";
print $spec <<'EOF';
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

# Substitute ROM name
seek $spec, 0, 0;
my $spec_content = do { local $/; <$spec> };
close $spec;
$spec_content =~ s/\@ROM\@/$rom_name/g;

open $spec, '>', "$dir/play-spec.pl" or die $!;
print $spec $spec_content;
close $spec;
chmod 0755, "$dir/play-spec.pl";

# ===== Summary =====
print "✅ Created ROM scaffolding:\n";
print "   Makefile          - Build configuration\n";
print "   nes.cfg           - NROM linker config (16KB PRG + 8KB CHR)\n";
print "   $rom_name.s       - Assembly skeleton (init + infinite loop)\n";
print "   play-spec.pl      - Test spec template\n";
print "\n";
print "📋 Next steps:\n";
print "   cd $dir\n";
print "   make              # Build ROM\n";
print "   perl play-spec.pl # Run tests\n";
print "\n";
