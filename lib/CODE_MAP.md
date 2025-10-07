# lib/CODE_MAP.md

Testing infrastructure for NES development. Perl DSL for play-specs and JavaScript wrapper for headless emulation.

## Perl Modules (Test DSL)

### **NES/Test.pm**
Core testing DSL module. Provides play-spec primitives for NES ROM validation:
- `load_rom()`: Load ROM into emulator
- `at_frame()`: Execute assertions at specific frame
- `after_nmi()`: Execute assertions N NMIs after start
- `assert_ram()`, `assert_cpu_pc()`, `assert_sprite()`: State validation
- `assert_nmi_counter()`: Pattern-based counter validation

Manages persistent jsnes harness process via `nes-test-harness.js`. Communicates via JSON protocol.

### **NES/Test/Toy.pm**
Convenience module for toy test files. Auto-imports NES::Test, strict, warnings, Test::More. Auto-loads ROM from parent directory based on toy name. Reduces boilerplate in t/*.t files.

## JavaScript Wrapper

### **nes-test-harness.js**
Persistent jsnes emulator wrapper. Accepts JSON commands on stdin, returns JSON state on stdout:
- `load`: Load ROM from file path
- `run_frames`: Advance N frames
- `dump_state`: Return CPU/PPU/RAM/OAM state

Maintains emulator state across commands for efficient testing. Used by NES::Test.pm via IPC.

## Node.js Configuration

### **package.json**
npm package configuration. Declares jsnes dependency for headless NES emulation.

### **package-lock.json**
npm dependency lock file. Ensures reproducible jsnes version.

### **node_modules/**
npm dependencies (jsnes). Gitignored, installed via `npm install`.
