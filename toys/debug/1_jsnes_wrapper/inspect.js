#!/usr/bin/env node

const fs = require('fs');
const jsnes = require('jsnes');

const romData = fs.readFileSync('../../toy0_toolchain/hello.nes', 'binary');

const nes = new jsnes.NES({
  onFrame: function() {},
  onAudioSample: function() {}
});

nes.loadROM(romData);
nes.frame();

// Inspect what's available
console.log("NES object keys:", Object.keys(nes));
console.log("CPU keys:", Object.keys(nes.cpu));
console.log("PPU keys:", Object.keys(nes.ppu));

console.log("\nCPU registers:");
console.log("  PC:", nes.cpu.REG_PC);
console.log("  A:", nes.cpu.REG_ACC);
console.log("  X:", nes.cpu.REG_X);
console.log("  Y:", nes.cpu.REG_Y);
console.log("  SP:", nes.cpu.REG_SP);

console.log("\nMemory at 0x0000:", nes.cpu.mem[0x0000]);
console.log("Memory at 0x2000:", nes.cpu.mem[0x2000]);
console.log("Memory at 0x0200:", nes.cpu.mem[0x0200]);
