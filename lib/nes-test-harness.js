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
 *   {"cmd": "setVerbosity", "level": 0}  // 0=off, 1=info, 2=debug
 *
 * Environment:
 *   DEBUG=1  - Enable debug logging (same as verbosity level 2)
 */

const jsnes = require('jsnes');
const fs = require('fs');
const readline = require('readline');

// Verbosity control
let verbosity = process.env.DEBUG ? 2 : 0;

function debug(msg) {
    if (verbosity >= 2) {
        console.error(`[DEBUG] ${msg}`);
    }
}

function info(msg) {
    if (verbosity >= 1) {
        console.error(`[INFO] ${msg}`);
    }
}

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
let audioBuffer = [];
let captureAudio = false;

// Initialize NES with dummy callbacks
function initNES() {
    nes = new jsnes.NES({
        onFrame: () => {},  // No visual output needed
        onAudioSample: (left, right) => {
            if (captureAudio) {
                // Store mono (average L/R channels)
                audioBuffer.push((left + right) / 2.0);
            }
        }
    });
    frameCount = 0;
    audioBuffer = [];
    captureAudio = false;
}

// WAV file encoder - converts float audio samples to WAV format
function encodeWAV(samples, sampleRate) {
    const numChannels = 1; // Mono
    const bitsPerSample = 16;
    const bytesPerSample = bitsPerSample / 8;
    const blockAlign = numChannels * bytesPerSample;
    const byteRate = sampleRate * blockAlign;
    const dataSize = samples.length * bytesPerSample;
    const buffer = Buffer.alloc(44 + dataSize);

    // RIFF chunk descriptor
    buffer.write('RIFF', 0);
    buffer.writeUInt32LE(36 + dataSize, 4);
    buffer.write('WAVE', 8);

    // fmt sub-chunk
    buffer.write('fmt ', 12);
    buffer.writeUInt32LE(16, 16);           // Subchunk1Size (16 for PCM)
    buffer.writeUInt16LE(1, 20);            // AudioFormat (1 = PCM)
    buffer.writeUInt16LE(numChannels, 22);
    buffer.writeUInt32LE(sampleRate, 24);
    buffer.writeUInt32LE(byteRate, 28);
    buffer.writeUInt16LE(blockAlign, 32);
    buffer.writeUInt16LE(bitsPerSample, 34);

    // data sub-chunk
    buffer.write('data', 36);
    buffer.writeUInt32LE(dataSize, 40);

    // Convert float samples [-1.0, 1.0] to 16-bit PCM
    let offset = 44;
    for (let i = 0; i < samples.length; i++) {
        const sample = Math.max(-1, Math.min(1, samples[i])); // Clamp
        const pcm = Math.round(sample * 32767);
        buffer.writeInt16LE(pcm, offset);
        offset += 2;
    }

    return buffer;
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

        const buttonIndex = BUTTONS[buttonName];

        debug(`buttonDown: controller=${controller}, button=${buttonName} (index=${buttonIndex})`);
        debug(`  state before: [${nes.controllers[controller].state.map(v => v.toString(16)).join(',')}]`);

        nes.buttonDown(controller, buttonIndex);

        debug(`  state after:  [${nes.controllers[controller].state.map(v => v.toString(16)).join(',')}]`);

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

        const buttonIndex = BUTTONS[buttonName];

        debug(`buttonUp: controller=${controller}, button=${buttonName} (index=${buttonIndex})`);
        debug(`  state before: [${nes.controllers[controller].state.map(v => v.toString(16)).join(',')}]`);

        nes.buttonUp(controller, buttonIndex);

        debug(`  state after:  [${nes.controllers[controller].state.map(v => v.toString(16)).join(',')}]`);

        return {status: 'ok'};
    },

    getState: () => {
        if (!nes) {
            return {status: 'error', message: 'No ROM loaded'};
        }

        // Extract state from jsnes internals
        debug(`getState: frame=${frameCount}, ctrl1=[${nes.controllers[1].state.map(v => v.toString(16)).join(',')}]`);

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
            oam: Array.from(nes.ppu.spriteMem.slice(0, 256)),
            controllers: {
                1: Array.from(nes.controllers[1].state),
                2: Array.from(nes.controllers[2].state)
            }
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

    captureAudio: (args) => {
        if (!nes) {
            return {status: 'error', message: 'No ROM loaded'};
        }

        const frames = args.frames || 10;
        const sampleRate = 48000; // jsnes default

        // Clear buffer and enable capture
        audioBuffer = [];
        captureAudio = true;

        debug(`captureAudio: capturing ${frames} frames`);

        // Run frames while capturing audio
        for (let i = 0; i < frames; i++) {
            nes.frame();
            frameCount++;
        }

        // Disable capture
        captureAudio = false;

        debug(`captureAudio: captured ${audioBuffer.length} samples`);

        // Encode to WAV
        const wavBuffer = encodeWAV(audioBuffer, sampleRate);
        const base64 = wavBuffer.toString('base64');

        return {
            status: 'ok',
            frame: frameCount,
            samples: audioBuffer.length,
            wav: base64
        };
    },

    setVerbosity: (args) => {
        const level = args.level || 0;
        verbosity = level;
        info(`Verbosity set to ${level}`);
        return {status: 'ok', verbosity: verbosity};
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
