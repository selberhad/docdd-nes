#!/usr/bin/env node

const fs = require('fs');
const jsnes = require('jsnes');

// Parse command-line arguments
const args = process.argv.slice(2);
if (args.length < 1) {
  console.error('Usage: nes-headless.js <rom-file> [--frames=N] [--dump-range=START:END]');
  process.exit(1);
}

const romFile = args[0];
let framesToRun = 1;
let dumpRange = null;

// Parse options
for (let i = 1; i < args.length; i++) {
  const arg = args[i];
  if (arg.startsWith('--frames=')) {
    framesToRun = parseInt(arg.split('=')[1], 10);
  } else if (arg.startsWith('--dump-range=')) {
    const range = arg.split('=')[1].split(':');
    dumpRange = { start: parseInt(range[0], 16), end: parseInt(range[1], 16) };
  }
}

// Load ROM
let romData;
try {
  romData = fs.readFileSync(romFile, 'binary');
} catch (err) {
  console.error(`Error reading ROM: ${err.message}`);
  process.exit(1);
}

// Initialize emulator
const nes = new jsnes.NES({
  onFrame: function(frameBuffer) {
    // Discard frame buffer (headless - no display)
  },
  onAudioSample: function(left, right) {
    // Discard audio (headless - no sound)
  }
});

// Load ROM
try {
  nes.loadROM(romData);
} catch (err) {
  console.error(`Error loading ROM: ${err.message}`);
  process.exit(1);
}

// Run frames
for (let i = 0; i < framesToRun; i++) {
  nes.frame();
}

// Dump state as JSON
const state = {
  cpu: {
    pc: nes.cpu.REG_PC,
    a: nes.cpu.REG_ACC,
    x: nes.cpu.REG_X,
    y: nes.cpu.REG_Y,
    sp: nes.cpu.REG_SP,
    status: nes.cpu.REG_STATUS
  },
  ppu: {
    nmiOnVblank: nes.ppu.f_nmiOnVblank,
    spriteSize: nes.ppu.f_spriteSize,
    bgPatternTable: nes.ppu.f_bgPatternTable,
    spPatternTable: nes.ppu.f_spPatternTable,
    addrInc: nes.ppu.f_addrInc
  },
  memory: {}
};

// Dump memory range if specified
if (dumpRange) {
  const mem = [];
  for (let addr = dumpRange.start; addr <= dumpRange.end; addr++) {
    mem.push(nes.cpu.mem[addr]);
  }
  state.memory.range = {
    start: dumpRange.start,
    end: dumpRange.end,
    bytes: mem
  };
}

// Dump first 16 bytes of OAM (sprite memory)
state.oam = [];
for (let i = 0; i < 16; i++) {
  state.oam.push(nes.ppu.spriteMem[i]);
}

// Output JSON
console.log(JSON.stringify(state, null, 2));
