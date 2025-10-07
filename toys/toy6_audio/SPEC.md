# SPEC — Audio

<!-- Read docs/guides/SPEC_WRITING.md before writing this document -->

# Toy Model 6: APU Audio — Specification

Automated validation of NES APU audio generation through programmatic waveform analysis.

## Overview

**What it does:**
Validates that APU register writes produce detectable audio output by capturing emulator audio samples, analyzing them with FFT, and asserting on measurable properties (RMS amplitude, dominant frequency, silence detection). No manual listening required — full automation.

**Key principles:**
- **Programmatic validation only** — human ears not required for testing
- **Isolate APU basics** — pulse channel 1 register writes, silence detection, frequency measurement
- **Analysis pipeline** — jsnes → WAV → Python FFT → JSON metrics → Perl assertions
- **Falsifiable metrics** — RMS amplitude thresholds, frequency tolerance ranges

**Scope:**
Single complexity axis: APU pulse channel 1 tone generation. Does NOT test music engines, multiple channels, envelopes, or advanced effects.

**Integration context:**
- Input: NES ROM with APU register writes
- Output: Audio analysis JSON (RMS, frequency, playing/silence boolean)
- Extends: NES::Test DSL with audio assertions

## Data Model

### Audio Analysis JSON Output

Python analysis script produces JSON with measurable audio properties:

```json
{
  "rms": 0.042,
  "frequency": 439.8,
  "is_playing": true,
  "is_silence": false,
  "sample_rate": 48000,
  "duration_sec": 0.167
}
```

**Fields:**
- `rms` (float): Root mean square amplitude (0.0 = silence, 1.0 = maximum)
- `frequency` (float): Dominant frequency in Hz (from FFT peak)
- `is_playing` (bool): True if RMS > threshold (e.g., 0.01)
- `is_silence` (bool): True if RMS < threshold
- `sample_rate` (int): Audio sample rate from emulator
- `duration_sec` (float): Duration of analyzed audio segment

## Core Operations

### Operation 1: APU Initialization

**Purpose**: Silence all channels and disable hardware features before use.

**Registers:**
- `$4000-$4013`: Channel register initialization
- `$4015`: Enable channels (`$0F` = all on)
- `$4017`: Disable IRQ (`$40`)

**Behavior:**
Sets APU to known state. All channels silent until explicitly configured.

**Validation:**
Audio analysis shows silence (RMS < 0.01) after init.

### Operation 2: Pulse Channel 1 Tone Generation

**Purpose**: Generate audible tone at specified frequency.

**Registers:**
- `$4000`: Duty cycle and volume (`%DD11VVVV`)
- `$4002`: Period low byte
- `$4003`: Period high 3 bits

**Parameters:**
- Duty cycle: `00`=12.5%, `01`=25%, `10`=50%, `11`=75%
- Volume: `0000`=silence, `1111`=max
- Period: Calculated as `111860.8 / frequency - 1`

**Example (400 Hz square wave):**
```asm
lda #<279        ; Period = 111860.8 / 400 - 1 = 279
sta $4002
lda #>279
sta $4003
lda #%10111111   ; 50% duty, max volume
sta $4000
```

**Behavior:**
Produces continuous tone at target frequency until registers modified.

**Validation:**
- Audio analysis shows `is_playing = true`
- Measured frequency within ±5 Hz of target

### Operation 3: Silence

**Purpose**: Stop audio output.

**Method:**
Write volume=0 to `$4000` (lower 4 bits = `0000`).

**Example:**
```asm
lda #%10110000   ; 50% duty, volume=0
sta $4000
```

**Behavior:**
Audio output stops immediately.

**Validation:**
Audio analysis shows `is_silence = true` (RMS < 0.01).

## Test Scenarios

### Scenario 1: Simple — Single Tone

**Setup:**
Initialize APU, configure pulse channel 1 for 440 Hz (A note), run 10 frames.

**Expected:**
```perl
at_frame 10 => sub {
    assert_audio_playing();
    assert_frequency_near(440, 5);  # ±5 Hz tolerance
};
```

### Scenario 2: Complex — Frequency Change

**Setup:**
Play 400 Hz tone for 10 frames, change to 800 Hz, run 10 more frames.

**Expected:**
```perl
at_frame 10 => sub {
    assert_frequency_near(400, 5);
};
at_frame 20 => sub {
    assert_frequency_near(800, 5);
};
```

### Scenario 3: Error — Silence Detection

**Setup:**
Initialize APU, run 10 frames without enabling audio.

**Expected:**
```perl
at_frame 10 => sub {
    assert_silence();
};
```

### Scenario 4: Integration — Audio Start/Stop

**Setup:**
Start with silence, play tone at frame 5, stop at frame 15.

**Expected:**
```perl
at_frame 3 => sub {
    assert_silence();
};
at_frame 10 => sub {
    assert_audio_playing();
    assert_frequency_near(440, 5);
};
at_frame 20 => sub {
    assert_silence();
};
```

## Success Criteria

- [ ] APU initialization produces silence (RMS < 0.01)
- [ ] Writing pulse channel 1 registers produces detectable tone (RMS > 0.01)
- [ ] Measured frequency within ±5 Hz of calculated period
- [ ] Volume=0 produces silence (RMS < 0.01)
- [ ] Frequency changes reflected in analysis (400 Hz → 800 Hz detectable)
- [ ] Audio capture works headlessly (no manual listening)
- [ ] Python FFT analysis produces valid JSON metrics
- [ ] NES::Test audio assertions integrate cleanly with existing DSL
- [ ] All tests pass with `play-spec.pl` automation
- [ ] WAV files optionally saved for debugging/inspection
