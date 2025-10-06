#!/usr/bin/env node

/**
 * NES Test Harness - Persistent jsnes process for automated testing
 *
 * Protocol: JSON commands via stdin, responses via stdout
 *
 * Commands:
 *   {"cmd": "loadRom", "path": "rom.nes"}
 *   {"cmd": "frame", "count": 1}  // advance N frames
 *   {"cmd": "buttonDown", "controller": 1, "button": "A"}
 *   {"cmd": "buttonUp", "controller": 1, "button": "A"}
 *   {"cmd": "getState"}
 *   {"cmd": "reset"}
 *   {"cmd": "quit"}
 */

const jsnes = require('jsnes');
const fs = require('fs');
const readline = require('readline');

// Button name mapping
const BUTTONS = {
    'A': jsnes.Controller.BUTTON_A,
    'B': jsnes.Controller.BUTTON_B,
    'SELECT': jsnes.Controller.BUTTON_SELECT,
    'START': jsnes.Controller.BUTTON_START,
    'UP': jsnes.Controller.BUTTON_UP,
    'DOWN': jsnes.Controller.BUTTON_DOWN,
    'LEFT': jsnes.Controller.BUTTON_LEFT,
    'RIGHT': jsnes.Controller.BUTTON_RIGHT
};

let nes = null;
let frameCount = 0;

// Initialize NES with dummy callbacks
function initNES() {
    nes = new jsnes.NES({
        onFrame: () => {},  // No visual output needed
        onAudioSample: () => {}  // No audio needed
    });
    frameCount = 0;
}

// Command handlers
const commands = {
    loadRom: (args) => {
        const romPath = args.path;

        if (!fs.existsSync(romPath)) {
            return {status: 'error', message: `ROM not found: ${romPath}`};
        }

        const romData = fs.readFileSync(romPath, 'binary');

        initNES();
        nes.loadROM(romData);
        frameCount = 0;

        return {status: 'ok', message: `Loaded ${romPath}`};
    },

    frame: (args) => {
        if (!nes) {
            return {status: 'error', message: 'No ROM loaded'};
        }

        const count = args.count || 1;

        for (let i = 0; i < count; i++) {
            nes.frame();
            frameCount++;
        }

        return {status: 'ok', frame: frameCount};
    },

    buttonDown: (args) => {
        if (!nes) {
            return {status: 'error', message: 'No ROM loaded'};
        }

        const controller = args.controller || 1;
        const buttonName = args.button;

        if (!(buttonName in BUTTONS)) {
            return {status: 'error', message: `Unknown button: ${buttonName}`};
        }

        nes.buttonDown(controller, BUTTONS[buttonName]);

        return {status: 'ok'};
    },

    buttonUp: (args) => {
        if (!nes) {
            return {status: 'error', message: 'No ROM loaded'};
        }

        const controller = args.controller || 1;
        const buttonName = args.button;

        if (!(buttonName in BUTTONS)) {
            return {status: 'error', message: `Unknown button: ${buttonName}`};
        }

        nes.buttonUp(controller, BUTTONS[buttonName]);

        return {status: 'ok'};
    },

    getState: () => {
        if (!nes) {
            return {status: 'error', message: 'No ROM loaded'};
        }

        // Extract state from jsnes internals
        const state = {
            frame: frameCount,
            cpu: {
                pc: nes.cpu.REG_PC,
                a: nes.cpu.REG_ACC,
                x: nes.cpu.REG_X,
                y: nes.cpu.REG_Y,
                sp: nes.cpu.REG_SP,
                status: nes.cpu.REG_STATUS,
                // Memory snapshot (first 2KB - work RAM)
                mem: Array.from(nes.cpu.mem.slice(0, 0x0800))
            },
            ppu: {
                ctrl: nes.ppu.f_nmiOnVblank << 7 | nes.ppu.f_spriteSize << 5,
                mask: nes.ppu.f_bgVisibility | (nes.ppu.f_spVisibility << 1),
                status: nes.ppu.f_vBlank << 7,
                nmiOnVblank: nes.ppu.f_nmiOnVblank,
                spriteSize: nes.ppu.f_spriteSize,
                bgPatternTable: nes.ppu.f_bgPatternTable,
                spPatternTable: nes.ppu.f_spPatternTable
            },
            oam: Array.from(nes.ppu.spriteMem.slice(0, 256))
        };

        return {status: 'ok', data: state};
    },

    reset: () => {
        if (!nes) {
            return {status: 'error', message: 'No ROM loaded'};
        }

        nes.reset();
        frameCount = 0;

        return {status: 'ok'};
    },

    quit: () => {
        return {status: 'quit'};
    }
};

// Main command loop
const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
    terminal: false
});

rl.on('line', (line) => {
    let cmd;
    try {
        cmd = JSON.parse(line);
    } catch (e) {
        const error = {status: 'error', message: `Invalid JSON: ${e.message}`};
        console.log(JSON.stringify(error));
        return;
    }

    const handler = commands[cmd.cmd];
    if (!handler) {
        const error = {status: 'error', message: `Unknown command: ${cmd.cmd}`};
        console.log(JSON.stringify(error));
        return;
    }

    const result = handler(cmd.args || {});
    console.log(JSON.stringify(result));

    if (result.status === 'quit') {
        process.exit(0);
    }
});

// Signal ready
console.log(JSON.stringify({status: 'ready'}));
