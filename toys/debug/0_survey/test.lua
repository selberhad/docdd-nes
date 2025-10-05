-- Simple test: Read memory and print to stdout
-- Run with: fceux --loadlua test.lua ../toy0_toolchain/hello.nes

print("Lua script started")

-- Run 1 frame
emu.frameadvance()

-- Read PPU CTRL register (should be 0x80 after init)
local ppu_ctrl = memory.readbyte(0x2000)
print(string.format("PPU_CTRL: 0x%02X", ppu_ctrl))

-- Get CPU cycle count
local cycles = debugger.getcyclescount()
print(string.format("Cycles: %d", cycles))

-- Get frame count
local frames = emu.framecount()
print(string.format("Frames: %d", frames))

-- Exit
os.exit(0)
