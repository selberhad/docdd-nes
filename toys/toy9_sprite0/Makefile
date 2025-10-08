# Makefile for sprite0 - NES ROM build
# Assembles sprite0.s with ca65, links with ld65 using custom nes.cfg

# Paths (macOS Homebrew cc65)
CA65 = /opt/homebrew/bin/ca65
LD65 = /opt/homebrew/bin/ld65
MESEN = /Applications/Mesen.app/Contents/MacOS/Mesen

# Source files
ASM_SRC = sprite0.s
CFG_FILE = nes.cfg
ROM = sprite0.nes
OBJ = sprite0.o
DBG = sprite0.dbg

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
