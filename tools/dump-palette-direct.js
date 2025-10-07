#!/usr/bin/env node
// Direct palette dump using jsnes - bypasses test harness for debugging

const {NES} = require('jsnes');
const fs = require('fs');

const romPath = process.argv[2];
const frames = parseInt(process.argv[3]) || 3;

if (!romPath) {
    console.error('Usage: dump-palette-direct.js <rom.nes> [frames]');
    process.exit(1);
}

const rom = fs.readFileSync(romPath);
const nes = new NES();

// Load ROM
nes.loadROM(String.fromCharCode.apply(null, rom));

// Run frames
for (let i = 0; i < frames; i++) {
    nes.frame();
}

console.log(`Palette RAM after ${frames} frames:`);
console.log('='.repeat(70));
console.log('\nBackdrop mirrors (hardware: all 8 should match):');

const backdropAddrs = [0x3F00, 0x3F04, 0x3F08, 0x3F0C, 0x3F10, 0x3F14, 0x3F18, 0x3F1C];
for (const addr of backdropAddrs) {
    const val = nes.ppu.vramMem[addr];
    console.log(`  $${addr.toString(16).toUpperCase().padStart(4, '0')}: 0x${val.toString(16).toUpperCase().padStart(2, '0')} (${val.toString().padStart(3, ' ')})`);
}

console.log('\nBG Palettes:');
for (let pal = 0; pal < 4; pal++) {
    const base = 0x3F00 + (pal * 4);
    process.stdout.write(`  Pal ${pal}: `);
    for (let col = 0; col < 4; col++) {
        const addr = base + col;
        const val = nes.ppu.vramMem[addr];
        process.stdout.write(`$3F${(addr - 0x3F00).toString(16).toUpperCase().padStart(2, '0')}=0x${val.toString(16).toUpperCase().padStart(2, '0')} `);
    }
    console.log();
}

console.log('\nSprite Palettes:');
for (let pal = 0; pal < 4; pal++) {
    const base = 0x3F10 + (pal * 4);
    process.stdout.write(`  Pal ${pal}: `);
    for (let col = 0; col < 4; col++) {
        const addr = base + col;
        const val = nes.ppu.vramMem[addr];
        process.stdout.write(`$3F${(addr - 0x3F00).toString(16).toUpperCase().padStart(2, '0')}=0x${val.toString(16).toUpperCase().padStart(2, '0')} `);
    }
    console.log();
}
