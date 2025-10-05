# 6502 Optimization Techniques

Advanced optimization patterns for 6502 assembly on NES. Focus on cycle/byte trade-offs and practical techniques beyond basics.

## Core Principles

**Optimization Types:**
- **Speed**: Fewer cycles (critical for NMI, vblank code)
- **Size**: Fewer bytes (when ROM space limited)
- **Constant-time**: Same cycles regardless of input (for consistent frame timing)

**When to Optimize:**
- NMI handlers (only ~2273 cycles available)
- Tight loops running per-frame
- Code called frequently (sprite updates, physics)
- When profiling shows bottlenecks

**When NOT to Optimize:**
- Init code (runs once)
- Infrequent events (menu navigation)
- Before measuring (premature optimization)

---

## Speed + Size Wins (Use These First)

### Tail Call Optimization
Replace `JSR` + `RTS` with `JMP` when subroutine ends by calling another.

```asm
; Before (7 bytes, 18 cycles):
MySubroutine:
  lda Foo
  sta Bar
  jsr SomeRandomRoutine
  rts

; After (6 bytes, 9 cycles saved):
MySubroutine:
  lda Foo
  sta Bar
  jmp SomeRandomRoutine
```

**Savings**: 1 byte, 9 cycles

---

### Split Pointer Tables (Hi/Lo Separate)
Avoid ASL to double index - saves cycles and bytes for pointer lookups.

```asm
; Before (8 bytes, 14 cycles):
  lda FooBar
  asl A              ; Double for word table
  tax
  lda PointerTable,X
  sta Temp
  lda PointerTable+1,X
  sta Temp+1

PointerTable:
  .word Pointer1, Pointer2, ...

; After (6 bytes, 10 cycles):
  ldx FooBar
  lda PointerTableL,X
  sta Temp
  lda PointerTableH,X
  sta Temp+1

PointerTableL:
  .byte <Pointer1, <Pointer2, ...
PointerTableH:
  .byte >Pointer1, >Pointer2, ...
```

**Savings**: 2 bytes, 4 cycles
**Trade-off**: Tables take more ROM (split), less human-friendly
**Use when**: Frequent table lookups (jump tables, level data)

---

### RTS Trick (Jump Table via Stack)
Use RTS for jump tables - saves RAM, is reentrant, no temp variable needed.

```asm
; Before (indirect JMP, needs Temp in RAM):
  ldx JumpEntry
  lda PointerTableH,X
  sta Temp+1
  lda PointerTableL,X
  sta Temp
  jmp (Temp)              ; 5 cycles if Temp in ZP

; After (RTS trick, no RAM needed):
  ldx JumpEntry
  lda PointerTableH,X
  pha
  lda PointerTableL,X
  pha
  rts                     ; 6 cycles total

PointerTable:
  .word action0-1, action1-1, action2-1  ; NOTE: Addresses must be -1
```

**Savings**: 4 bytes if Temp not in ZP, frees 2 bytes RAM, reentrant
**Cost**: 1 cycle slower than ZP indirect JMP
**Gotcha**: Table entries must be target address MINUS 1 (RTS adds 1)

**Combine with tail call** for 1 more byte + 9 cycles:
```asm
; Run SomeOtherFunction, then jump to table entry, then return to caller
  ldx JumpEntry
  lda PointerTableH,X
  pha
  lda PointerTableL,X
  pha
  jmp SomeOtherFunction   ; Will RTS to table entry, which RTSs to original caller
```

---

### Inline Single-Use Subroutines
If a subroutine is called only ONCE, inline it (avoid JSR/RTS overhead).

**Savings**: 4 bytes, 12 cycles
**Trade-off**: Harder to maintain, can't call from multiple places
**Use macro** if you need the code structure without the call overhead.

---

### Test Upper 2 Bits with BIT
Avoid ASL when checking bits 7 and 6 (N and V flags).

```asm
; Before (3 bytes, 4 cycles):
  lda FooBar
  asl A         ; C = b7, N = b6

; After (3 bytes, 4 cycles, preserves A):
  bit FooBar    ; N = b7, V = b6, A unchanged
```

**Use case**: Polling $2002 for sprite-0 hit (bit 6) or vblank (bit 7)

---

### Avoid CLC/SEC When Carry is Known
If you know carry state from prior operation, skip CLC/SEC.

```asm
; Example: Code only reached via BCS (carry is SET)
some_label:
  adc #(value-1)   ; Carry already set, so this adds 'value'

; Example: Code only reached when carry is CLEAR
other_label:
  sbc #(value-1)   ; Carry clear, so subtract 'value'
  ; OR
  adc #<-value     ; Equivalent
```

**Savings**: 2 cycles, 1 byte per avoided CLC/SEC

---

### Test Bits in Decreasing Order
Check higher bits first to avoid redundant CMP instructions.

```asm
; Test bits 7, 6, 5 (5 bytes total):
  lda foobar
  bmi bit7_set
  cmp #$40       ; We know bit 7 is clear, so only need to check #$40
  bcs bit6_set
  cmp #$20
  bcs bit5_set

; OR if A can be destroyed (4 bytes):
  lda foobar
  bmi bit7_set
  asl
  bmi bit6_set
  asl
  bmi bit5_set
```

**Savings**: 1 byte per comparison (vs testing each bit independently)

---

### Test Bits in Increasing Order
Shift right and check carry for low bits.

```asm
  lda foobar
  lsr
  bcs bit0_set
  lsr
  bcs bit1_set
  lsr
  bcs bit2_set
```

**Note**: Destroys A

---

### Test Bits Without Destroying A
Use BIT instruction on an opcode that has the bits you need.

```asm
; Before (8 bytes, 8 cycles):
  lda foobar
  and #$30
  beq bits_clear
  lda foobar      ; Reload A because AND destroyed it
  ...
bits_clear:
  lda foobar
  ...

; After (5 bytes, 6 cycles):
  lda foobar
  bit _bmi_instruction  ; BMI opcode = $30
  beq bits_clear
  ...
bits_clear:
  ...

_bmi_instruction:       ; Somewhere in your code
  bmi somewhere
```

**Savings**: 3 bytes, 2 cycles

---

### Test Equality Preserving Carry
Use EOR instead of CMP to test equality without affecting carry.

```asm
; Before (9 bytes, 14 cycles):
  php
  cmp myVal
  beq equal
  plp
  ...
equal:
  plp
  ...

; After (destroys A, 2 bytes, 5 cycles):
  eor myVal
  beq equal
  ...

; After (preserves A, 4 bytes, 11 cycles):
  eor myVal
  beq equal
  eor myVal    ; Restore A (not equal case)
  ...
equal:
  eor myVal    ; Restore A (equal case)
  ...
```

**Savings**: 7 cycles + 3 bytes (A destroyed), or 3 cycles - 1 byte (A preserved)

---

### Test All Specified Bits Set (Preserving Carry)
Combine EOR + AND to test if multiple bits are set.

```asm
; Before (test bits 7,6,1,0 all set):
  php
  and #%11000011
  cmp #%11000011
  beq all_set
  plp
  ...

; After:
  eor #$ff
  and #%11000011
  beq all_set
  ...
```

**Savings**: 3 bytes, 7 cycles

---

### Use Opposite Rotate vs Many Shifts
4 ROLs faster than 5 LSRs when extracting high bits.

```asm
; Extract top 3 bits to low positions:
; Before (10 bytes, 10 cycles):
  lda value
  lsr
  lsr
  lsr
  lsr
  lsr
  and #$07

; After (8 bytes, 8 cycles, high bits NOT cleared):
  lda value
  rol
  rol
  rol
  rol
  ; Only care about bits 0-2 now (bits 3-7 are garbage)
```

**Use case**: When you only need certain bits and don't care about others

---

### Avoid CMP in Loops
Choose loop direction and end value to use implicit flags from INC/DEC.

```asm
; Increasing X to 255:
loop:
  ...
  inx
  bne loop       ; No CMP needed

; Decreasing X to 1:
loop:
  ...
  dex
  bne loop       ; No CMP needed

; Decreasing X to 0 (starting from 0-128):
loop:
  ...
  dex
  bpl loop       ; BPL works because 0 is positive, $FF is negative
```

**For arrays**: Offset array base address to make final index = 0 or 255:
```asm
; Copy indexes 10-13 from my_array to $2007
  ldx #252             ; 256 - 4 bytes
loop:
  lda my_array-242,x   ; 242 = 252 - 10 (first index)
  sta $2007
  inx
  bne loop
```

**Savings**: 2 bytes, 2 cycles per loop iteration

---

### Avoid CMP for Specific Constants
Use INC/DEC to test for -1, 0, 1, 2 without CMP.

```asm
; Test for $FF (-1):
  ldx Val
  inx
  beq Equals

; Test for 1:
  ldx Val
  dex
  beq Equals

; Test for 2 (range check <2):
  lda Val
  lsr a
  beq LessThan
  bne GreaterEqualTo
```

**Savings**: 1 byte, clobbers register

---

## Speed Optimizations (Trade Size for Cycles)

### Identity Table (Trade 256 Bytes ROM for Cycles)
Use 256-byte lookup table instead of temp variables.

```asm
; Before (5 bytes, 7 cycles):
  ldx Foo
  lda Bar
  stx Temp
  clc
  adc Temp

; After (4 bytes, 5 cycles, costs 256 bytes ROM):
  ldx Foo
  lda Bar
  clc
  adc Identity,X

Identity:
  .byte $00, $01, $02, ..., $FE, $FF  ; 256 bytes
```

**Savings**: 2 cycles, 1 byte
**Cost**: 256 bytes ROM
**Use when**: ROM plentiful, speed critical (NMI handlers)

---

### Lookup Table to Shift Left 4
Replace 4 ASLs with table lookup (if high nibble clear).

```asm
; Before (8 bytes, 8 cycles):
  lda rownum
  asl A
  asl A
  asl A
  asl A

; After (4 bytes, 4 cycles, costs 16 bytes ROM):
  ldx rownum
  lda times_sixteen,x

times_sixteen:
  .byte $00, $10, $20, $30, $40, $50, $60, $70
  .byte $80, $90, $A0, $B0, $C0, $D0, $E0, $F0
```

**Savings**: 4 cycles, 4 bytes code
**Cost**: 16 bytes ROM
**Gotcha**: Clobbers X

---

## Size Optimizations (Trade Cycles for Bytes)

### Use Stack Instead of Temp Variable
Save 2 bytes by using PHA/PLA instead of STA/LDA.

```asm
; Before (7 bytes):
  lda Foo
  sta Temp
  lda Bar
  ...
  lda Temp

; After (5 bytes, 4 cycles slower):
  lda Foo
  pha
  lda Bar
  ...
  pla
```

**Savings**: 2 bytes
**Cost**: 4 cycles slower
**Use when**: Not in tight loop, RAM scarce

---

### Use Relative Branch Instead of JMP
If flag state is known and target is close (<128 bytes).

```asm
; Before:
  lda #1
  jmp target      ; 3 bytes

; After:
  lda #1
  bne target      ; 2 bytes (Z always clear after LDA #1)
  ; OR
  bpl target      ; N always clear after LDA #1
```

**Savings**: 1 byte

---

### BIT Trick (Multiple Entry Points)
Use BIT absolute ($2C) to skip over LDA instructions, creating multiple entry points.

```asm
; Before (must load A before each JSR):
  lda #5
  jsr sub
  lda #7
  jsr sub
  lda #11
  jsr sub

; After (entry points skip to appropriate LDA):
  jsr sub_5
  jsr sub_7
  jsr sub_11

sub_5:
  lda #5
  .byte $2C      ; BIT absolute opcode
sub_7:
  lda #7         ; Becomes operand of BIT if sub_5 called
  .byte $2C
sub_11:
  lda #11        ; Becomes operand of BIT if sub_5 or sub_7 called
sub:
  sta $2007
  sta $2007
  rts
```

**Savings**: Code size reduced if sub_X called multiple times
**Used in**: Super Mario Bros.

---

## Table Scanning Optimizations

### Scan Small Tables (<256 bytes) Backwards
DEY sets zero flag implicitly - no CMP needed.

```asm
; Forward (slower):
  lda #0
  ldy #0
loop:
  sta table,y
  iny
  cpy #size
  bne loop

; Backward (faster):
  lda #0
  ldy #size
loop:
  dey
  sta table,y   ; DEY before STA! (or final Y=0 won't execute)
  bne loop
```

**Savings**: 2 bytes, 2 cycles per iteration

### Scan Small Tables (<128 bytes) with BPL
If table <=128 bytes, use BPL instead of BNE.

```asm
  lda #0
  ldy #size-1    ; size MUST be <=128
loop:
  clc
  adc table,y
  dey
  bpl loop       ; Executes when Y >= 0, including Y=0
```

**Gotcha**: DEY after operation (operation may affect flags)

---

### Scan Tables Forward Efficiently
Use offset addressing to avoid CPY.

```asm
; Scan 3-byte table forward without CMP:
  ldy #$FD
loop:
  cmp table - $FD,y   ; table base - $FD, so $FD+table = table[0]
  beq found
  iny
  bne loop            ; Loop ends when Y wraps to 0

; General pattern for forward scan:
  ldy #$100-size
loop:
  cmp table - ($100-size),y
  beq found
  iny
  bne loop
```

**Savings**: Avoid CMP, costs potential page crossing
**Use for**: Sizes <= 128 bytes

---

### Scan Large Tables (>256 bytes)
Use negated size trick to avoid 16-bit comparisons.

```asm
; Clear $103 bytes efficiently:
  lda #<(begin - <-count)
  sta addr
  lda #>(begin - <-count)
  sta addr+1

  lda #0
  ldx #>-count      ; High byte of -count
  ldy #<-count      ; Low byte of -count

loop:
  sta (addr),y
  iny
  bne loop
  inc addr+1
  inx
  bne loop
```

**Pattern**: Load X/Y with -count, adjust addr by low byte of -count
**Result**: No 16-bit CMP needed in loop

---

## Synthetic Instructions (Simulate Missing Opcodes)

### Negate A
```asm
; A = -A (carry known clear):
  eor #$FF
  adc #1

; A = -A (carry known set):
  eor #$FF
  sec
  adc #0
```

**Cycles**: 6

---

### Reverse Subtract (A = Value - A)
```asm
  eor #$FF
  sec
  adc Value

; Special case (A = 255 - A):
  eor #$FF
```

---

### Sign-Extend 8-bit to 16-bit
Calculate high byte of sign-extended value.

```asm
; Branching version (varies):
  ora #$7F
  bmi neg
  lda #0
neg:

; Constant-time version (7 bytes, 8 cycles, destroys carry):
  asl a           ; C = bit 7
  lda #$00
  adc #$FF        ; A = $00 if C=1, $FF if C=0
  eor #$FF        ; Invert
```

---

### Arithmetic Shift Right (Preserve Sign)
```asm
; For A:
  cmp #$80
  ror a

; For memory:
  lda Value
  asl a           ; Move sign to carry
  ror Value
```

---

### 8-bit Rotate (Not 9-bit like ROL/ROR)
```asm
; Rotate left:
  cmp #$80        ; Set carry to bit 7
  rol a

; Rotate left (alternate):
  asl a
  adc #0

; Rotate right (save/restore A):
  pha
  lsr a
  pla
  ror a

; Rotate right (branch version):
  lsr a
  bcc skip
  adc #$80-1      ; Carry is set
skip:
```

---

### Nybble Swap ($1F -> $F1)
```asm
; 8 bytes, 12 cycles:
  asl a
  adc #$80
  rol a
  asl a
  adc #$80
  rol a
```

---

### 16-bit Increment/Decrement
```asm
; INC16 (faster, only adjusts high if low wraps):
  inc Word
  bne noinc
  inc Word+1
noinc:

; DEC16 (check before decrement):
  lda Word
  bne nodec
  dec Word+1
nodec:
  dec Word
```

**Use in loops**: INC16 conveniently sets Z flag when entire word is zero.

---

### Toggle Carry Flag
```asm
  rol a
  eor #$01
  ror a
```

**Destroys**: N, Z flags
**Preserves**: A

---

### Count Bits Set in A
```asm
; Loop until zero (faster):
  ldx #$ff
incr:
  inx
loop:
  asl
  bcs incr
  bne loop
  txa          ; X = count
```

---

## Unofficial Opcodes (Use with Caution)

**WARNING**: Not portable to 65C02, HuC6280, 65C816. Some emulators don't implement them. Use only in NES-specific code.

### Combined Operations (AND + Operation)

#### ALR #i ($4B) - AND #i then LSR A
```asm
; 2 cycles, equivalent to:
  and #i
  lsr a
```

**Gotcha**: Unreliable on UM6561AF-2 famiclone chip

---

#### ANC #i ($0B, $2B) - AND #i, Copy N to C
```asm
; 2 cycles, sets C = bit 7 of result
  and #i
  ; C = N
```

**Use for**: Sign extension (ANC #$FF), clear A+C (ANC #$00)

---

#### AXS #i ($CB) - (A AND X) - #i -> X
```asm
; 2 cycles, iterate through structures:
  txa
  axs #$FC   ; Step to next OAM entry (4 bytes each)
```

**Saves**: 1 byte, 4 cycles vs 4x INX

---

#### LAX - LDA + TAX Combined
```asm
; Addressing modes: (d,X), d, a, (d),Y, d,Y, a,Y
  lax value  ; Equivalent to: lda value : tax
```

**Saves**: 1 byte, 2 cycles
**Note**: No immediate mode (#i) due to 6502 bug

---

#### SAX - Store (A AND X)
```asm
; Addressing modes: (d,X), d, a, d,Y
  sax value  ; Store (A AND X) to memory
```

**No flags affected**

---

### RMW + Operation Combos (DCP, ISC, RLA, RRA, SLO, SRE)

#### DCP - DEC then CMP
```asm
; All RMW addressing modes
  dcp value  ; Equivalent to: dec value : cmp value
```

**Use for**: Multi-byte decrement underflow check (LDA #$FF : DCP)

---

#### ISC - INC then SBC
```asm
  isc value  ; Equivalent to: inc value : sbc value
```

---

#### RLA - ROL then AND
```asm
  rla value  ; Equivalent to: rol value : and value
```

**Use for**: Efficient rotate + load (LDA #$FF : RLA value)

---

#### RRA - ROR then ADC
```asm
  rra value  ; Equivalent to: ror value : adc value
```

**Computes**: A + value/2 (9-bit value, rounded up)

---

#### SLO - ASL then ORA
```asm
  slo value  ; Equivalent to: asl value : ora value
```

**Use for**: Efficient shift + load (LDA #0 : SLO value)

---

#### SRE - LSR then EOR
```asm
  sre value  ; Equivalent to: lsr value : eor value
```

**Use for**: Efficient shift + load (LDA #0 : SRE value)

---

### NOPs (Waste Cycles / Watermarking)

```asm
; 1-byte NOPs (2 cycles): $1A, $3A, $5A, $7A, $DA, $EA, $FA

; 2-byte NOPs (2 cycles): $80, $82, $89, $C2, $E2
; Portable NOP: $89 (BIT #i on 65C02/HuC6280/65C816)

; 3-byte NOPs (4 cycles): $0C (absolute)
; 4-cycle NOPs (d,X): $14, $34, $54, $74, $D4, $F4
; 4-5 cycle NOPs (a,X): $1C, $3C, $5C, $7C, $DC, $FC
```

**Use for**: Cycle-exact delays, watermarking ROM, padding, debugger breakpoints

---

## When to Use What

| Scenario | Technique |
|----------|-----------|
| Jump table (common) | RTS trick |
| Tight loop | Scan backwards, avoid CMP |
| NMI handler | Identity table, split tables, tail calls |
| Pointer lookups | Split hi/lo tables |
| Test bits without clobbering A | BIT trick |
| Preserve carry while testing | EOR instead of CMP |
| ROM limited | Use stack, relative branches, BIT trick |
| Speed critical | Identity tables, lookup tables |
| Large table scan | Negated size trick |
| Structure iteration | AXS unofficial opcode |

---

## Cycle Budgets (Rules of Thumb)

- **Vblank**: ~2273 cycles total
- **Sprite DMA**: 513-514 cycles (done first in vblank)
- **Remaining vblank**: ~1760 cycles for PPU updates
- **Frame**: 29780 cycles total (NTSC)

**Implication**: Every cycle saved in NMI = more time for PPU writes.

---

## References

- Related: `RTS_Trick.html`, `Jump_Table.html`, `Scanning_Tables.html`, `Synthetic_Instructions.html`
- Related: `Programming_with_unofficial_opcodes.html`

---

## Attribution

This document synthesizes information from the following NESdev Wiki pages:

- [6502_assembly_optimisations](https://www.nesdev.org/wiki/6502_assembly_optimisations)

