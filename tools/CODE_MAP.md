# tools/CODE_MAP.md

Utility scripts for scaffolding, testing, inspection, documentation, and setup.

## Scaffolding

### **new-toy.pl**
Scaffolds new toy directory structure. Creates SPEC.md, PLAN.md, README.md, LEARNINGS.md with templates. Usage: `new-toy.pl <name>`.

### **new-rom.pl**
Scaffolds ROM build infrastructure in existing directory. Generates Makefile, nes.cfg (NROM linker config), .s skeleton (standard init sequence), and play-spec.pl template. Usage: `new-rom.pl <rom_name> [dir]`.

## Testing & Inspection

### **inspect-rom.pl**
Decodes iNES ROM headers and displays metadata. Shows mapper, mirroring, PRG/CHR sizes, hardware vectors (NMI/RESET/IRQ), and first 64 bytes of code at reset vector. Validates file size against header. Usage: `inspect-rom.pl <file.nes>`.

## Documentation

### **fetch-wiki.sh**
Caches NESdev wiki pages to `.webcache/` for offline reference. Downloads HTML, converts to markdown. Usage: `fetch-wiki.sh <PageName>`.

### **add-attribution.pl**
Adds wiki attribution footer to learning documents. Appends NESdev wiki URL references for proper credit. Usage: `add-attribution.pl <learnings/file.md>`.

## Setup & Git

### **setup-brew-deps.sh**
Installs Homebrew toolchain dependencies. Checks for and installs cc65 (assembler/linker) and SDL2 (Mesen2 dependency). Verifies ARM64 compatibility.

### **git-bootstrap.sh**
Git repository initialization script. Sets up initial repository structure, creates first commit, configures remotes. Used during project setup.
