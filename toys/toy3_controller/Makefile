# Makefile for toy3_controller - Controller read validation
# Assembles controller.s with ca65, links with ld65 using custom nes.cfg

# Paths (macOS Homebrew cc65)
# NOTE: Homebrew installs to /opt/homebrew on Apple Silicon
CA65 = /opt/homebrew/bin/ca65
LD65 = /opt/homebrew/bin/ld65
MESEN = /Applications/Mesen.app/Contents/MacOS/Mesen

# Source files
ASM_SRC = controller.s
CFG_FILE = nes.cfg
ROM = controller.nes
OBJ = controller.o
DBG = controller.dbg

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
