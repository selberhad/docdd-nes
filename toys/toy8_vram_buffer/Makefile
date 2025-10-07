# Makefile for buffer - NES ROM build
# Assembles buffer.s with ca65, links with ld65 using custom nes.cfg

# Paths (macOS Homebrew cc65)
CA65 = /opt/homebrew/bin/ca65
LD65 = /opt/homebrew/bin/ld65
MESEN = /Applications/Mesen.app/Contents/MacOS/Mesen

# Source files
ASM_SRC = buffer.s
CFG_FILE = nes.cfg
ROM = buffer.nes
OBJ = buffer.o
DBG = buffer.dbg

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
