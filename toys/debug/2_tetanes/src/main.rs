use std::fs;
use std::env;
use std::io::Cursor;
use tetanes_core::control_deck::ControlDeck;
use serde_json::json;

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: {} <rom-file>", args[0]);
        std::process::exit(1);
    }

    let rom_path = &args[1];

    // Load ROM
    let rom_data = fs::read(rom_path).expect("Failed to read ROM file");
    let mut rom_cursor = Cursor::new(rom_data);

    // Create control deck (NES emulator core)
    let mut deck = ControlDeck::new();

    // Load ROM into deck
    if let Err(e) = deck.load_rom("hello.nes", &mut rom_cursor) {
        eprintln!("Failed to load ROM: {:?}", e);
        std::process::exit(1);
    }

    // Run one frame
    let _ = deck.clock_frame();

    // Access Work RAM (0x0000-0x07FF mirrored to 0x1FFF)
    // Clone first 16 bytes to avoid borrow conflict
    let mem_sample: Vec<u8> = deck.wram().iter().take(16).copied().collect();
    let wram_size = deck.wram().len();

    // Try to save state to see format
    let state_path = "/tmp/tetanes_state.bin";
    if let Err(e) = deck.save_state(state_path) {
        eprintln!("Warning: Failed to save state: {:?}", e);
    }

    let state = json!({
        "wram_sample": mem_sample,
        "wram_size": wram_size,
        "state_saved": std::path::Path::new(state_path).exists()
    });

    println!("{}", serde_json::to_string_pretty(&state).unwrap());
}
