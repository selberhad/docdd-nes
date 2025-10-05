# 6502 Math Routines

Practical math implementations for NES. Includes multiplication, division, and random number generation - all operations the 6502 lacks in hardware.

## Core Principle

The 6502 has **no hardware multiply or divide**. Every math operation beyond add/subtract must be implemented in software. Choose algorithms based on your constraints:
- **Constant operand**: Fastest (shift + add)
- **Variable operand, rare**: Use general routine
- **Variable operand, frequent**: Consider lookup tables (256 bytes)

---

## Multiplication

### Multiply by Power of 2 (Shifts)
**Always** use shifts for powers of 2.

```asm
; Multiply by 2^n = shift left n times
; Example: Multiply by 8 (2^3):
  lda value
  asl a
  asl a
  asl a
```

**Design tip**: Structure your code to use power-of-2 multipliers when possible (tile sizes, sprite dimensions, etc.)

**Signed numbers**: Save sign first, restore at end.

---

### Multiply by Small Constant (Shift + Add)
Decompose constant into binary (sum of powers of 2), shift and add.

**Algorithm**: Write constant in binary, shift for each bit position, add when bit is 1.

#### Example: Multiply by 13 (%1101 = 8 + 4 + 1)

```asm
; A = A * 13
; 13 = %1101 = 8 + 4 + 1
  lda Var      ; Start with 1x
  asl a        ; 2x
  adc Var      ; 3x (2x + 1x) [bit 0 of 13]
  asl a        ; 6x (skip bit 1, which is 0)
  asl a        ; 12x
  adc Var      ; 13x (12x + 1x) [bit 2 of 13]
               ; (bit 3 would add here but 8x was already included in shifts)
```

**Requirement**: Result must fit in 8 bits (ASL clears carry between ADCs)

---

### Multiply by Larger Constant (16-bit Result)

For results >255, track high byte with ROL.

#### Example: Multiply by 81 (%1010001 = 64 + 16 + 1)

```asm
; 16-bit result in A (low) and Y (high)
  lda #$00
  sta ResH        ; Init high byte
  lda Var         ; Start with 1x
  asl a
  rol ResH
  adc Var         ; bit 0: add 1x
  asl a
  rol ResH        ; bit 1: 0 (skip)
  asl a
  rol ResH        ; bit 2: 0 (skip)
  asl a
  rol ResH        ; bit 3: 0 (skip)
  asl a
  rol ResH
  adc Var         ; bit 4: add 1x (16x + 1x = 17x)
  asl a
  rol ResH        ; bit 5: 0 (skip)
  asl a
  rol ResH
  adc Var         ; bit 6: add 1x (final 64x + 16x + 1x = 81x)
  ldy ResH
```

**Pattern**:
1. ASL for each bit position
2. ADC Var when bit is 1
3. ROL ResH after each ASL to track overflow

---

### General 8x8 Multiply (Variable × Variable)

For unpredictable operands, use this standard routine.

```asm
; Multiply A × Y, result in A (low) and X (high)
; Destroys A, X, Y
; ~200 cycles worst case

multiply:
  sta factor1
  sty factor2
  lda #0
  ldx #8          ; 8 bits
  lsr factor1     ; Shift multiplier right

mul_loop:
  bcc skip_add
  clc
  adc factor2     ; Add multiplicand if bit was 1
skip_add:
  ror a           ; Shift result right (high bit)
  ror factor1     ; Shift partial product right (becomes low byte)
  dex
  bne mul_loop

  tax             ; X = high byte
  lda factor1     ; A = low byte
  rts

.zeropage
factor1: .res 1
factor2: .res 1
```

**Cycles**: ~200 worst case
**Use when**: Both operands unknown at compile time

---

### Fast Signed Multiply (8x8 -> 16-bit)

For signed multiplication, use this optimized routine.

```asm
; Multiply signed A × signed X, result in (A=low, X=high)
; ~140-150 cycles
; Source: NESdev wiki Fast_signed_multiply.html

; (See full implementation in .webcache/Fast_signed_multiply.html)
; Key insight: Handles sign extension efficiently
```

**Use for**: Physics calculations (velocity × time), damage calculations

---

### Multiply by Variable (Many Times)

If multiplying by the same variable repeatedly in an algorithm, **generate specialized code at runtime**.

```asm
; Pseudocode:
; 1. Analyze bits of variable
; 2. Generate sequence of ASL/ADC in RAM
; 3. Execute RAM code
; 4. Much faster than general multiply routine for repeated ops
```

**Use case**: Scaling entire sprite set, bulk coordinate transforms
**Trade-off**: Complex, requires RAM execution

---

## Division

### Divide by Power of 2 (Shifts)

```asm
; Unsigned divide by 2^n = shift right n times
; Example: Divide by 8:
  lda value
  lsr a
  lsr a
  lsr a
```

**Signed division** by 2: Use arithmetic shift right (preserve sign):

```asm
  cmp #$80        ; Set carry = sign bit
  ror a           ; Shift right, keep sign
```

---

### Divide by 3 (Optimized)

Division by 3 is common enough (e.g., averaging 3 samples) to warrant a specialized routine.

```asm
; Divide 8-bit unsigned A by 3, result in A
; ~40-50 cycles
; Source: Divide_by_3.html

; (See full implementation in .webcache/Divide_by_3.html)
; Uses multiply-by-inverse technique
```

**Faster than general division** for this specific case.

---

### Divide by Constant (Multiply by Inverse)

For constant divisors, use "multiply by inverse" technique.

**Concept**: Division by N ≈ Multiplication by (256/N), then shift right 8.

```asm
; Example: Divide by 5
; Inverse: 256/5 = 51.2 ≈ 51 ($33)
  lda value
  ; Multiply by 51 (using shift+add)
  ; (Implementation details depend on constant)
  ; Then shift result right 8 bits
```

**Source**: `Division_by_a_constant_integer.html`
**Trade-off**: Approximate result (rounding error)
**Use for**: Non-critical divisions where speed matters

---

### General 8-bit Divide (A ÷ X)

```asm
; Divide unsigned A ÷ X
; Result: A = quotient, Y = remainder
; Destroys: A, X, Y
; ~200-250 cycles

divide:
  sta dividend
  stx divisor
  lda #0          ; Clear remainder
  ldx #8          ; 8 bits

div_loop:
  asl dividend    ; Shift dividend left
  rol a           ; Shift bit into remainder
  cmp divisor
  bcc skip_sub
  sbc divisor     ; Subtract divisor (carry already set from CMP)
  sec
skip_sub:
  rol dividend    ; Shift result bit into dividend (quotient)
  dex
  bne div_loop

  lda dividend    ; A = quotient
  tay             ; Y = remainder (in A from above)
  rts

.zeropage
dividend: .res 1
divisor:  .res 1
```

**Source**: `8-bit_Divide.html`

---

## BCD (Binary-Coded Decimal)

The NES 2A03 has a **non-functional decimal mode**. To do BCD math, use software routines.

### 16-bit BCD Addition/Subtraction

```asm
; Add two 16-bit BCD numbers
; Inputs: (num1_hi, num1_lo), (num2_hi, num2_lo)
; Output: (result_hi, result_lo)
; ~60-80 cycles

; (See full implementation in .webcache/16-bit_BCD.html)
```

**Use for**: Score display, currency, anything shown in decimal

---

### Base 100 (Alternative to BCD)

Instead of BCD (0-99 per byte, 4 bits wasted), use **base 100** (0-99 stored as binary).

```asm
; Each byte stores 0-99 as binary value
; Example: 9999 = [99][99] in two bytes
; Addition: Add bytes, adjust if >99

; Advantages:
; - No BCD adjust needed
; - Simpler compare
; - Easier to work with

; Disadvantages:
; - Convert to BCD for display
```

**Source**: `Base_100.html`
**Trade-off**: Extra conversion to display, but simpler math

---

## Random Number Generation

### LFSR (Linear Feedback Shift Register)

The **standard** PRNG for 6502 systems. Uses only shifts and XOR.

#### 16-bit Galois LFSR (Polynomial $0039)

```asm
; Returns random 8-bit number in A (0-255)
; Clobbers Y
; Requires 2-byte zero-page "seed" (initialize to non-zero)
; Period: 65535 (repeats after 65535 calls)
; Average: 137 cycles

.zeropage
seed: .res 2      ; Initialize to any value except 0

.code
prng:
  ldy #8          ; Generate 8 bits
  lda seed+0
loop:
  asl             ; Shift register left
  rol seed+1
  bcc no_xor
  eor #$39        ; XOR feedback when bit shifts out
no_xor:
  dey
  bne loop
  sta seed+0
  cmp #0          ; Set flags
  rts
```

**Cycles**: 133-141 (average 137)
**Size**: 19 bytes

---

#### Overlapped 16-bit LFSR (Faster)

```asm
; Same result, but computes 8 iterations at once
; 69 cycles, 35 bytes

prng:
  lda seed+1
  tay                      ; Store copy
  lsr
  lsr
  lsr
  sta seed+1
  lsr
  eor seed+1
  lsr
  eor seed+1
  eor seed+0               ; Combine with low byte
  sta seed+1
  tya                      ; Original high byte
  sta seed+0
  asl
  eor seed+0
  asl
  eor seed+0
  asl
  asl
  asl
  eor seed+0
  sta seed+0
  rts
```

**Cycles**: 69
**Size**: 35 bytes
**Trade-off**: 2x faster, but 16 bytes larger

---

### Seeding the RNG

**Problem**: Always starting with same seed = same sequence every time.

**Solutions**:
1. **Player input timing**: Count frames until player presses start
   ```asm
   ; In main loop before game starts:
   init_seed:
     inc seed+0
     bne check_input
     inc seed+1
   check_input:
     lda joy1
     and #BUTTON_START
     beq init_seed    ; Loop until START pressed
   ```

2. **Frame counter**: Use a running frame counter at random event
   ```asm
   ; When random event occurs (enemy spawns, etc.):
     lda frame_count_lo
     sta seed+0
     lda frame_count_hi
     sta seed+1
   ```

3. **Mix multiple sources**: XOR several unpredictable values
   ```asm
     lda frame_count
     eor controller_state
     eor ppu_scroll_x
     sta seed+0
   ```

---

### When to Use Wider LFSRs

- **16-bit**: Good for most games (65K sequence length)
- **24-bit**: When generating large batches of random numbers
- **32-bit**: Extremely long sequences, high-quality randomness

**Source**: `Random_number_generator/Linear_feedback_shift_register_(advanced)`

---

## Lookup Tables vs Computation

| Operation | Computation | Lookup Table (256 bytes) |
|-----------|-------------|--------------------------|
| Multiply by constant | ~10-30 cycles | ~5 cycles |
| Divide by small constant | ~40-200 cycles | ~5 cycles |
| Sine/Cosine (8-bit) | N/A (too slow) | ~5 cycles |
| Square root | ~100+ cycles | ~5 cycles |

**Rule of Thumb**:
- **ROM plentiful**: Use tables for speed
- **ROM scarce**: Compute on demand
- **Mixed**: Hybrid (compute + small cache table)

---

## Special Considerations

### Overflow Detection

```asm
; Check if 8-bit multiply will overflow:
  lda factor1
  cmp #$80
  bcs might_overflow
  ; Safe if both factors < 128

might_overflow:
  ; Check more carefully or use 16-bit result
```

---

### Signed vs Unsigned

**Unsigned** math is simpler (what we've shown).
**Signed** math requires:
1. Check signs of inputs
2. Convert to absolute value
3. Perform unsigned operation
4. Fix result sign

**Tip**: Design systems to use unsigned when possible (positions, sizes, indices).

---

## Common Use Cases

| Use Case | Recommended Technique |
|----------|----------------------|
| Multiply by 8, 16, 32 | Shift (ASL) |
| Multiply by 3, 5, 7 | Shift + add (constant) |
| Multiply unknown values | General 8x8 routine |
| Divide by 2, 4, 8 | Shift (LSR) |
| Divide by 3 | Special routine |
| Divide by other constant | Multiply by inverse |
| Random enemy spawn | 16-bit LFSR |
| Random loot table | 16-bit LFSR |
| Procedural terrain | 24/32-bit LFSR |
| Score display | BCD or base 100 |

---

## Performance Summary

| Operation | Cycles (approx) | Notes |
|-----------|-----------------|-------|
| Multiply by constant | 10-30 | Depends on constant bits |
| 8x8 multiply | ~200 | General routine |
| Fast signed multiply | ~140-150 | Optimized |
| Divide by constant | 40-200 | Via multiply-inverse |
| 8-bit divide | ~200-250 | General routine |
| 16-bit LFSR | ~137 | Standard version |
| 16-bit LFSR (fast) | 69 | Overlapped version |
| BCD addition (16-bit) | ~60-80 | Software BCD |

---

## References

- Source: NESdev Wiki
  - `Multiplication_by_a_constant_integer.html`
  - `Fast_signed_multiply.html`
  - `8-bit_Multiply.html`
  - `8-bit_Divide.html`
  - `Division_by_a_constant_integer.html`
  - `Divide_by_3.html`
  - `16-bit_BCD.html`
  - `Base_100.html`
  - `Random_number_generator.html`

---

## Attribution

This document synthesizes information from the following NESdev Wiki pages:

- [Fast_signed_multiply](https://www.nesdev.org/wiki/Fast_signed_multiply)
- [Divide_by_3](https://www.nesdev.org/wiki/Divide_by_3)
- [16-bit_BCD](https://www.nesdev.org/wiki/16-bit_BCD)

