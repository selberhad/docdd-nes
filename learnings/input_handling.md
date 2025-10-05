# Input Handling

**Source**: Priority 2 NESdev Wiki pages (Controller reading code, Input devices)

Practical patterns for reading controllers, handling input devices, and avoiding common pitfalls.

---

## Standard Controller Reading

### Controller Port Architecture

**Hardware**:
- **$4016** (read): Controller 1 + expansion port data (bits 0-4)
- **$4017** (read): Controller 2 + expansion port data (bits 0-4)
- **$4016** (write): Strobe signal to latch controller state

**Standard controller button order** (after strobe):
1. A
2. B
3. Select
4. Start
5. Up
6. Down
7. Left
8. Right

### Basic Controller Read Pattern

```asm
; Constants for button masks
BUTTON_A      = $80
BUTTON_B      = $40
BUTTON_SELECT = $20
BUTTON_START  = $10
BUTTON_UP     = $08
BUTTON_DOWN   = $04
BUTTON_LEFT   = $02
BUTTON_RIGHT  = $01

read_controller1:
  ; Strobe controller to latch current state
  lda #$01
  sta $4016      ; Start strobe
  lda #$00
  sta $4016      ; End strobe (controller latches state)

  ; Read 8 buttons (bit 0 of each read = button state)
  ldx #$08       ; 8 buttons to read
read_loop:
  lda $4016      ; Read button state
  lsr            ; Shift bit 0 into carry
  rol buttons1   ; Rotate carry into buttons1
  dex
  bne read_loop
  rts

; After calling read_controller1:
; buttons1 = %ABSS UDLR (1 = pressed, 0 = released)
```

**Benefit**: All 8 buttons compressed into 1 byte; easy to test with AND/BIT

### Reading Multiple Controllers

```asm
read_controllers:
  ; Strobe both controllers simultaneously
  lda #$01
  sta $4016
  lda #$00
  sta $4016

  ; Read controller 1
  ldx #$08
read_p1:
  lda $4016
  lsr
  rol buttons1
  dex
  bne read_p1

  ; Read controller 2
  ldx #$08
read_p2:
  lda $4017
  lsr
  rol buttons2
  dex
  bne read_p2

  rts
```

**CRITICAL**: Strobe once, then read both controllers; don't strobe between reads

---

## Input Debouncing and Edge Detection

### Button Press vs. Button Held

**Problem**: Reading controller every frame detects both "just pressed" and "held"

**Solution**: Track previous frame's state; compare to detect edges

```asm
read_controller_with_edges:
  ; Save previous state
  lda buttons1
  sta buttons1_prev

  ; Read current state
  jsr read_controller1

  ; Calculate "newly pressed" (was 0, now 1)
  lda buttons1
  eor #$FF         ; Invert current state
  and buttons1_prev ; AND with previous (filters out held buttons)
  eor #$FF
  and buttons1
  sta buttons1_new

  ; Calculate "newly released" (was 1, now 0)
  lda buttons1_prev
  eor #$FF
  and buttons1
  eor #$FF
  and buttons1_prev
  sta buttons1_released

  rts
```

**Usage**:
```asm
check_jump:
  lda buttons1_new
  and #BUTTON_A
  beq no_jump      ; A button NOT newly pressed
  ; Trigger jump (only once per press)
  jsr start_jump
no_jump:
```

### Simpler Edge Detection (One-Button Example)

```asm
; Detect A button press (not held)
check_a_button:
  lda buttons1
  and #BUTTON_A
  beq a_not_pressed

  ; A is pressed; check if it was pressed last frame
  lda buttons1_prev
  and #BUTTON_A
  bne a_not_pressed  ; Was pressed last frame; ignore (held)

  ; A newly pressed!
  jsr handle_a_press

a_not_pressed:
  rts
```

---

## Advanced Controller Techniques

### Rapid Fire Detection

**Problem**: Detect if player is tapping button rapidly (e.g., for rapid-fire weapon)

**Pattern**: Count frames since last button press

```asm
rapid_fire_check:
  lda buttons1_new
  and #BUTTON_B
  beq no_b_press

  ; B newly pressed; check time since last press
  lda b_press_timer
  cmp #6           ; Less than 6 frames since last press?
  bcs not_rapid
  ; Rapid fire detected!
  inc rapid_fire_count
not_rapid:
  lda #0
  sta b_press_timer
  rts

no_b_press:
  inc b_press_timer
  rts
```

### Simultaneous Button Detection (Cheat Codes)

**Pattern**: Check for specific button combinations

```asm
check_konami_code:
  ; Konami code: Up, Up, Down, Down, Left, Right, Left, Right, B, A
  lda buttons1_new
  and #BUTTON_UP
  beq not_code_start

  ; Up pressed; check if in sequence
  lda code_state
  cmp #0
  beq first_up
  cmp #1
  beq second_up
  ; ... (check full sequence) ...

first_up:
  inc code_state
  rts

; Reset code state if wrong button pressed
```

### Direction Priority (Opposite Directions)

**Problem**: Hardware allows Up+Down or Left+Right simultaneously (broken controller or emulator)

**Solution**: Prioritize one direction or cancel both

```asm
resolve_directions:
  lda buttons1
  and #BUTTON_UP
  beq check_down
  ; Up pressed; cancel Down
  lda buttons1
  and #$FF - BUTTON_DOWN
  sta buttons1

check_down:
  lda buttons1
  and #BUTTON_LEFT
  beq check_right
  ; Left pressed; cancel Right
  lda buttons1
  and #$FF - BUTTON_RIGHT
  sta buttons1

check_right:
  rts
```

---

## Input Devices (Beyond Standard Controller)

### Zapper (Light Gun)

**Hardware**:
- Connected to port 2 ($4017)
- Bit 4: Light sensor (1 = light detected, 0 = no light)
- Bit 3: Trigger (1 = not pressed, 0 = pressed)

**Reading pattern**:
```asm
read_zapper:
  lda $4017
  and #$18         ; Bits 3-4
  sta zapper_state

check_trigger:
  lda zapper_state
  and #$08
  bne trigger_released
  ; Trigger pressed
  jsr handle_zapper_shot
trigger_released:
```

**Light detection timing**:
1. Draw white target on screen
2. Wait for light sensor to detect (bit 4 = 1)
3. Calculate hit position based on scanline timing

### Arkanoid Controller (Paddle)

**Hardware**:
- Connects to port 2 ($4017)
- Returns 9-bit value (paddle position)
- Bits 3-4 contain serial data

**Reading pattern** (similar to controller, but 9 bits + button):
```asm
read_arkanoid:
  lda #$01
  sta $4016      ; Strobe

  lda #$00
  sta $4016

  ; Read 9 bits of position data
  ldx #$09
read_paddle_loop:
  lda $4017
  and #$08       ; Bit 3 = position data
  lsr
  lsr
  lsr
  rol paddle_position
  rol paddle_position+1
  dex
  bne read_paddle_loop

  ; Read button state (bit 4)
  lda $4017
  and #$10
  sta paddle_button
  rts
```

### Four Score (4-Player Adapter)

**Pattern**: Extends reads beyond 8 buttons; reads 24 bits per controller

```asm
read_four_score:
  ; Strobe all controllers
  lda #$01
  sta $4016
  lda #$00
  sta $4016

  ; Read 24 bits from $4016 (controllers 1 & 3)
  ; Read 24 bits from $4017 (controllers 2 & 4)
  ; Bits 0-7: Controller 1/2
  ; Bits 8-15: Controller 3/4
  ; Bits 16-23: Signature ($10 for Four Score detection)
```

**Signature detection**:
- Bit 16-23 = $10 → Four Score connected
- Bit 16-23 ≠ $10 → Standard controller or no device

---

## Controller Port Pin Usage (Platform Differences)

### NES Controller Ports

**Port 1 ($4016)**:
- D0: Serial data
- D3, D4: Additional inputs (used by some accessories)

**Port 2 ($4017)**:
- D0: Serial data
- D3, D4: Light gun / paddle data

### Famicom Controller Differences

**Built-in controllers**:
- Controller 1: Always connected, uses $4016 D0 and D2
- Controller 2: Built-in, uses $4017 D0; has microphone on $4016 D2

**Expansion port**:
- Full access to all data lines (D0-D4, $4016 and $4017)
- Used for keyboards, mahjong controllers, etc.

**CRITICAL**: Famicom controller 2 microphone appears on $4016 D2 (reads as 1 when audio detected)

---

## Common Pitfalls

### Pitfall 1: Reading Without Strobe

**Problem**: Forgetting to strobe before reading → stale data

```asm
; WRONG: No strobe
read_controller_wrong:
  lda $4016      ; Reads garbage or previous state
  rts

; CORRECT: Strobe first
read_controller_correct:
  lda #$01
  sta $4016
  lda #$00
  sta $4016
  lda $4016      ; Now reads valid data
  rts
```

### Pitfall 2: Strobe During Read

**Problem**: Strobing between button reads → corrupted data

```asm
; WRONG: Strobe inside loop
read_controller_wrong:
  ldx #$08
loop:
  lda #$01
  sta $4016      ; DON'T DO THIS!
  lda #$00
  sta $4016
  lda $4016
  lsr
  rol buttons1
  dex
  bne loop
```

### Pitfall 3: Ignoring Unused Bits

**Problem**: Relying on bits 1-7 of $4016/$4017 (only bit 0 is valid for standard controller)

```asm
; WRONG: Reading full byte
  lda $4016
  sta buttons1   ; Bits 1-7 are open bus / undefined

; CORRECT: Mask or shift bit 0
  lda $4016
  lsr            ; Shift bit 0 to carry
  rol buttons1   ; Rotate carry into result
```

### Pitfall 4: Not Handling Open Bus

**Problem**: On Famicom, unused data lines read as "open bus" (last value on bus)

**Solution**: Always mask expected bits; don't assume 0 for unused bits

---

## Input Timing and Cadence

### When to Read Controllers

**Option 1: During NMI**
```asm
nmi_handler:
  ; OAM DMA
  lda #$02
  sta $4014

  ; Read controllers
  jsr read_controllers

  ; Update game state based on input
  jsr update_player

  rti
```

**Benefit**: Consistent timing; input read every frame

**Option 2: In Main Loop**
```asm
main_loop:
  jsr wait_for_vblank
  jsr read_controllers
  jsr update_game_logic
  jmp main_loop
```

**Benefit**: Simpler code; no NMI overhead

### Input Lag Considerations

- **Read in NMI**: Input applied immediately to next frame update
- **Read in main loop**: 1 frame delay if read happens after game logic

**Best practice**: Read at START of frame (NMI) or immediately after vblank wait

---

## Key Takeaways

1. **Strobe once, read all buttons** - Don't strobe between reads; latches state atomically
2. **Only bit 0 is valid** - Mask or shift bit 0; ignore bits 1-7 (open bus)
3. **Track previous state for edges** - Detect "newly pressed" vs "held" for responsive controls
4. **Platform differences matter** - Famicom has built-in controllers + microphone on $4016 D2
5. **Accessories use extended protocols** - Light gun, paddle, Four Score need special read patterns

## Reference Files

---

## Attribution

This document synthesizes information from the following NESdev Wiki pages:

- [Controller_reading_code](https://www.nesdev.org/wiki/Controller_reading_code)
- [Input_devices](https://www.nesdev.org/wiki/Input_devices)

