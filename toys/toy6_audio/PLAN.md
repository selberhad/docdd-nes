# PLAN — Audio

<!-- Read docs/guides/PLAN_WRITING.md before writing this document -->

# Toy Model 6: APU Audio — Implementation Plan

**Goal**: Build automated audio validation pipeline (jsnes → WAV → Python FFT → JSON → Perl assertions) and validate APU pulse channel 1 tone generation.

**Scope**: Single complexity axis — APU register writes produce measurable audio. Infrastructure-heavy (3 steps for pipeline, 2 steps for ROM/tests).

**Priorities**:
1. **Audio capture** (critical path blocker)
2. **Python analysis** (enables assertions)
3. **DSL integration** (NES::Test extensions)
4. **ROM validation** (TDD against real APU)

**Methodology**: TDD where possible. Infrastructure steps (1-3) are spikes with manual validation. ROM/test steps (4-5) follow strict Red → Green → Commit.

---

## Step 1: Audio Capture Infrastructure

### Goal
Modify `lib/nes-test-harness.js` to buffer audio samples during emulation and export to WAV file.

### Step 1.a: Investigate Audio Buffering

**Spike tasks:**
- Modify `initNES()` to attach real `onAudioSample` callback
- Buffer samples in array: `audioBuffer = []`
- Store as Float32Array or convert to Int16 for WAV compatibility
- Estimate buffer size: 48000 Hz × 0.167 sec = ~8000 samples per 10 frames

**Key decisions:**
- Mono vs stereo: Store both channels or mix to mono?
- Buffer management: Clear on ROM load, accumulate during frames

### Step 1.b: Implement WAV Export

**Tasks:**
1. Add command: `{"cmd": "captureAudio", "frames": 10}`
2. Run emulation for N frames while buffering audio
3. Convert buffer to WAV format (WAV header + PCM data)
4. Return base64-encoded WAV or write to temp file
5. Add command: `{"cmd": "getAudio"}` → returns WAV data

**Code pattern (illustrative):**
```javascript
commands.captureAudio = (args) => {
    const frames = args.frames || 10;
    audioBuffer = [];
    for (let i = 0; i < frames; i++) {
        nes.frame();
    }
    const wavData = encodeWAV(audioBuffer, 48000, 1); // mono
    return {status: 'ok', wav: wavData.toString('base64')};
};
```

### Step 1.c: Manual Validation

**Test:**
- Run test harness with simple ROM
- Capture audio for 10 frames
- Write WAV to `/tmp/test.wav`
- Inspect with `hexdump` or audio tool
- Verify: 48kHz sample rate, valid PCM data

### Success Criteria

- [ ] `onAudioSample` callback receives float samples during emulation
- [ ] Audio buffer accumulates samples correctly
- [ ] WAV encoding produces valid file (header + PCM data)
- [ ] `captureAudio` command returns base64 WAV data
- [ ] Manual inspection confirms valid audio file

---

## Step 2: Python Audio Analysis Tool

### Goal
Create `tools/analyze-audio.py` to perform FFT analysis on WAV files and output JSON metrics.

### Step 2.a: WAV Parsing

**Tasks:**
1. Read WAV file with standard library (`wave` module)
2. Extract PCM samples as numpy array
3. Convert to mono if stereo (average channels)
4. Normalize to float range [-1.0, 1.0]

**Code pattern:**
```python
#!/usr/bin/env python3
import wave
import numpy as np
import json
import sys

def read_wav(path):
    with wave.open(path, 'rb') as wav:
        rate = wav.getframerate()
        frames = wav.readframes(wav.getnframes())
        data = np.frombuffer(frames, dtype=np.int16)
        # Normalize to [-1.0, 1.0]
        return data.astype(float) / 32768.0, rate
```

### Step 2.b: FFT Analysis

**Tasks:**
1. Compute RMS amplitude: `sqrt(mean(samples^2))`
2. Perform FFT: `numpy.fft.fft(samples)`
3. Find dominant frequency: Peak magnitude in FFT
4. Apply thresholds: `is_playing = RMS > 0.01`, `is_silence = RMS < 0.01`

**Code pattern:**
```python
def analyze_audio(samples, rate):
    rms = np.sqrt(np.mean(samples ** 2))

    # FFT for frequency analysis
    fft = np.fft.fft(samples)
    freqs = np.fft.fftfreq(len(samples), 1/rate)
    magnitude = np.abs(fft[:len(fft)//2])

    # Find dominant frequency (ignore DC component)
    peak_idx = np.argmax(magnitude[1:]) + 1
    dominant_freq = abs(freqs[peak_idx])

    return {
        'rms': float(rms),
        'frequency': float(dominant_freq),
        'is_playing': rms > 0.01,
        'is_silence': rms < 0.01,
        'sample_rate': rate,
        'duration_sec': len(samples) / rate
    }
```

### Step 2.c: CLI Interface

**Tasks:**
1. Accept WAV file path as argument
2. Output JSON to stdout
3. Handle errors gracefully (invalid file, etc.)

**Usage:**
```bash
tools/analyze-audio.py /tmp/audio.wav
# Output: {"rms": 0.042, "frequency": 439.8, ...}
```

### Step 2.d: Manual Validation

**Test:**
- Generate known tone (400 Hz sine wave) with Python or audio tool
- Run analysis script
- Verify: RMS > 0, frequency ≈ 400 Hz

### Success Criteria

- [ ] Script reads WAV files correctly
- [ ] RMS calculation produces reasonable values (0.0-1.0)
- [ ] FFT identifies dominant frequency within ±5 Hz
- [ ] JSON output matches spec format
- [ ] Known tone (400 Hz) correctly identified

---

## Step 3: NES::Test DSL Integration

### Goal
Extend `lib/NES/Test.pm` with audio assertions that invoke capture + analysis pipeline.

### Step 3.a: Audio Capture Method

**Tasks:**
1. Add `capture_audio($frames)` method to NES::Test
2. Send `captureAudio` command to harness
3. Receive base64 WAV data
4. Decode and write to temp file
5. Return temp file path

**Code pattern:**
```perl
sub capture_audio {
    my ($self, $frames) = @_;
    $frames //= 10;

    my $cmd = {cmd => 'captureAudio', frames => $frames};
    my $result = $self->send_command($cmd);

    # Decode base64 WAV and write to temp file
    my $wav_data = decode_base64($result->{wav});
    my $temp_path = "/tmp/nes_audio_$$.wav";
    write_file($temp_path, {binmode => ':raw'}, $wav_data);

    return $temp_path;
}
```

### Step 3.b: Audio Analysis Method

**Tasks:**
1. Add `analyze_audio($wav_path)` method
2. Invoke `tools/analyze-audio.py`
3. Parse JSON output
4. Return hashref with metrics

**Code pattern:**
```perl
sub analyze_audio {
    my ($self, $wav_path) = @_;

    my $json = `python3 tools/analyze-audio.py $wav_path`;
    return decode_json($json);
}
```

### Step 3.c: Assertion Methods

**Tasks:**
1. `assert_audio_playing()` - RMS > threshold
2. `assert_silence()` - RMS < threshold
3. `assert_frequency_near($hz, $tolerance)` - FFT peak within range

**Code pattern:**
```perl
sub assert_audio_playing {
    my ($self) = @_;
    my $wav = $self->capture_audio(10);
    my $analysis = $self->analyze_audio($wav);

    ok($analysis->{is_playing}, "Audio is playing (RMS=$analysis->{rms})");
}

sub assert_frequency_near {
    my ($self, $target_hz, $tolerance) = @_;
    $tolerance //= 5;

    my $wav = $self->capture_audio(10);
    my $analysis = $self->analyze_audio($wav);

    my $diff = abs($analysis->{frequency} - $target_hz);
    ok($diff <= $tolerance,
       "Frequency $analysis->{frequency} Hz within ${tolerance}Hz of ${target_hz}Hz");
}
```

### Success Criteria

- [ ] `capture_audio()` returns valid WAV file path
- [ ] `analyze_audio()` parses JSON correctly
- [ ] `assert_audio_playing()` detects non-silence
- [ ] `assert_silence()` detects silence
- [ ] `assert_frequency_near()` validates tone frequency

---

## Step 4: ROM Scaffolding

### Goal
Create buildable test ROM with APU initialization routine (no audio yet).

### Step 4.a: Scaffold ROM Build

**Tasks:**
1. Run: `../../tools/new-rom.pl audio`
2. Verify Makefile, nes.cfg, audio.s created
3. Build: `make` → `audio.nes`
4. Inspect: `../../tools/inspect-rom.pl audio.nes`

### Step 4.b: APU Initialization

**Add to ROM:**
- APU init routine (based on `learnings/audio.md`)
- Silence all channels
- Enable channels in $4015
- Disable IRQ in $4017

**Code pattern:**
```asm
init_apu:
    ; Initialize $4000-$4013
    ldy #$13
@loop:
    lda @regs,y
    sta $4000,y
    dey
    bpl @loop

    lda #$0f
    sta $4015    ; Enable all channels
    lda #$40
    sta $4017    ; Disable IRQ
    rts

@regs:
    .byte $30,$08,$00,$00  ; Pulse 1
    .byte $30,$08,$00,$00  ; Pulse 2
    .byte $80,$00,$00,$00  ; Triangle
    .byte $30,$00,$00,$00  ; Noise
    .byte $00,$00,$00,$00  ; DMC
```

### Success Criteria

- [ ] ROM builds without errors
- [ ] ROM boots in emulator (test harness)
- [ ] APU initialization runs (no crashes)

---

## Step 5: TDD Implementation

### Goal
Write tests FIRST, then implement ROM code to make tests pass.

### Step 5.a: Test — Silence After Init

**Test file:** `t/01-silence.t`

**Test strategy:**
- Load ROM, run 10 frames
- Assert silence (no audio output)

**Code pattern:**
```perl
use Test::More tests => 1;
use NES::Test;

my $t = NES::Test->new(rom => 'audio.nes');

$t->at_frame(10 => sub {
    $t->assert_silence();
});

$t->run();
```

**Expected:** Red (fails if APU makes noise)

### Step 5.b: Implement — Ensure Silence

**ROM changes:**
- Call `init_apu` in reset handler
- Do NOT write to pulse channel registers
- Infinite loop after init

**Expected:** Green (test passes)

**Commit:** `test(toy6): add silence after init test`
**Commit:** `feat(toy6): implement APU initialization`

### Step 5.c: Test — 440 Hz Tone

**Test file:** `t/02-tone-440hz.t`

**Test strategy:**
- Load ROM, run 10 frames
- Assert audio playing
- Assert frequency ≈ 440 Hz (A note)

**Code pattern:**
```perl
$t->at_frame(10 => sub {
    $t->assert_audio_playing();
    $t->assert_frequency_near(440, 5);
});
```

**Expected:** Red (no tone yet)

### Step 5.d: Implement — 440 Hz Tone

**ROM changes:**
- Calculate period: `111860.8 / 440 - 1 ≈ 253`
- Write period to $4002/$4003
- Write duty + volume to $4000

**Code pattern:**
```asm
    ; 440 Hz tone (A note)
    lda #<253
    sta $4002
    lda #>253
    sta $4003
    lda #%10111111  ; 50% duty, max volume
    sta $4000
```

**Expected:** Green (test passes)

**Commit:** `test(toy6): add 440Hz tone test`
**Commit:** `feat(toy6): implement 440Hz pulse tone`

### Step 5.e: Test — Frequency Change

**Test file:** `t/03-frequency-change.t`

**Test strategy:**
- Start with 400 Hz
- After frame 10, change to 800 Hz
- Assert both frequencies detected

**Code pattern:**
```perl
$t->at_frame(10 => sub {
    $t->assert_frequency_near(400, 5);
});

$t->at_frame(20 => sub {
    $t->assert_frequency_near(800, 5);
});
```

**Expected:** Red (ROM plays single frequency)

### Step 5.f: Implement — Frequency Change

**ROM changes:**
- Track frame counter in RAM
- At frame 10: recalculate period for 800 Hz
- Write new period to registers

**Expected:** Green (test passes)

**Commit:** `test(toy6): add frequency change test`
**Commit:** `feat(toy6): implement frequency change at frame 10`

### Step 5.g: Test — Silence on Demand

**Test file:** `t/04-silence-on-demand.t`

**Test strategy:**
- Play tone for 10 frames
- Silence at frame 10
- Assert silence at frame 15

**Expected:** Red (tone continues playing)

### Step 5.h: Implement — Silence on Demand

**ROM changes:**
- At frame 10: write volume=0 to $4000

**Code pattern:**
```asm
    lda #%10110000  ; 50% duty, volume=0
    sta $4000
```

**Expected:** Green (test passes)

**Commit:** `test(toy6): add silence-on-demand test`
**Commit:** `feat(toy6): implement volume=0 silence`

### Success Criteria

- [ ] All tests written before implementation (Red phase)
- [ ] All tests pass after implementation (Green phase)
- [ ] Commits follow conventional format with step numbers
- [ ] Each test file validates single behavior
- [ ] ROM code demonstrates APU register control

---

## Risks

**R1: jsnes audio fidelity**
- jsnes may not accurately emulate APU
- Mitigation: Validate with known test ROMs if available, document limitations

**R2: FFT accuracy at low sample counts**
- 10 frames = ~8000 samples at 48kHz
- May have frequency resolution issues
- Mitigation: Test with longer capture (20-30 frames) if needed

**R3: Infrastructure complexity**
- 3-language pipeline (JavaScript, Python, Perl)
- Mitigation: Manual validation at each step before integration

**R4: Noise/silence threshold tuning**
- RMS threshold of 0.01 may be too sensitive/insensitive
- Mitigation: Test with actual ROMs, adjust threshold empirically

---

## Dependencies

**External:**
- numpy (Python) - already installed
- jsnes (Node.js) - already integrated

**Internal:**
- lib/nes-test-harness.js (modify)
- lib/NES/Test.pm (extend)
- tools/new-rom.pl (use for scaffolding)

---

## Time Estimate

- Step 1: Audio capture — 45 min
- Step 2: Python analysis — 30 min
- Step 3: DSL integration — 30 min
- Step 4: ROM scaffolding — 15 min
- Step 5: TDD implementation — 60 min

**Total: ~3 hours**

---

## Notes

- **Save WAV files to /tmp/ for debugging** (inspectable with audio tools)
- **Document jsnes limitations in LEARNINGS.md** (Phase 1 validation only)
- **Defer music engines to future toys** (FamiTone2, etc.)
- **Keep Python script simple** (numpy only, no scipy unless needed)
