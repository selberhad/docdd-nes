# LEARNINGS — Audio

<!-- Read docs/guides/LEARNINGS_WRITING.md before writing this document -->

## Learning Goals

**Goal**: Automated audio validation WITHOUT manual listening - fully programmatic assertions for APU behavior.

**Vision**: LLM can validate NES audio behavior autonomously using programmatic analysis, not human ears.

### Questions to Answer

**Q1: Can we capture audio from jsnes headlessly?**
- Does jsnes expose audio samples in our test harness?
- What format? (Float32Array? Int16Array? Sample rate?)
- Can we buffer samples and export to WAV from Node.js?

**Q2: What Python libraries work for audio analysis?**
- numpy alone sufficient for basic FFT analysis?
- Need scipy/librosa for more advanced analysis?
- What metrics are extractable: RMS amplitude, dominant frequency, waveform shape?

**Q3: Can we validate APU register behavior programmatically?**
- Writing to $4000-$4003 (pulse channel 1) → detectable tone in output?
- Period registers → measurable frequency in Hz?
- Silence (volume=0) → detectable RMS threshold in output?
- Frequency changes → FFT shows expected frequency shift?

**Q4: What assertions are feasible for automated testing?**
- `assert_audio_playing()` - RMS amplitude > threshold
- `assert_silence()` - RMS amplitude near zero
- `assert_frequency_near(hz, tolerance)` - FFT peak detection
- `assert_pulse_wave(channel)` - Waveform shape analysis (stretch goal)

**Q5: What are Phase 1 (jsnes) limitations for audio?**
- What can't we validate without real hardware/better emulator?
- What requires human listening validation?
- What differences between jsnes and cycle-accurate emulators?

### Decisions to Make

**D1: Audio capture format**
- WAV file format (portable, inspectable, standard)
- Sample rate: 44100 Hz (standard) or jsnes native rate?
- Bit depth: 16-bit PCM (sufficient for analysis)

**D2: Python analysis architecture**
- Standalone script: `tools/analyze-audio.py`
- Input: WAV file path
- Output: JSON with metrics (RMS, frequency, playing/silence boolean)
- Keep it simple: numpy for FFT, standard library for WAV parsing

**D3: NES::Test DSL integration**
- Add audio capture command to nes-test-harness.js
- Add audio analysis invocation to lib/NES/Test.pm
- New assertion functions: `assert_audio_playing`, `assert_silence`, `assert_frequency_near`
- Cache WAV files for debugging? (save to /tmp/ for inspection)

**D4: Test ROM scope**
- Start simple: Single pulse wave tone (400 Hz or 440 Hz A note)
- Test silence detection (no audio output)
- Test frequency change (pitch shift)
- Defer: Music engines (FamiTone2, etc.) to future toy

## Findings

### ✅ Audio Capture Pipeline (Q1 - ANSWERED)

**jsnes audio API works perfectly:**
- `onAudioSample(left, right)` callback receives float samples normalized to [-1.0, 1.0]
- Sample rate: 48000 Hz (jsnes default)
- Called once per audio sample during frame execution
- Buffer accumulation works: ~8000 samples per 10 frames

**WAV encoding successful:**
- Node.js Buffer API handles WAV format (44-byte header + PCM data)
- 16-bit mono PCM sufficient for analysis
- Base64 transport works (no file I/O needed in harness)
- Typical payload: ~16KB WAV for 10 frames

**Decision validated:** D1 - 48kHz, 16-bit PCM mono, WAV format

### ✅ Python FFT Analysis (Q2 - ANSWERED)

**numpy alone is sufficient:**
- No scipy/librosa needed for basic frequency detection
- `numpy.fft.fft()` + `numpy.fft.fftfreq()` work perfectly
- `numpy.sqrt(numpy.mean(samples**2))` for RMS amplitude

**Metrics extracted successfully:**
- RMS amplitude: Distinguishes silence (0.0000) from tone (0.0606)
- Dominant frequency: FFT peak detection within ±1 Hz accuracy (measured 799.2 Hz for 800 Hz tone)
- Boolean flags: `is_playing`, `is_silence` (threshold 0.01 works)

**Decision validated:** D2 - Python + numpy, JSON output, no additional dependencies

### ✅ APU Register Validation (Q3 - PARTIALLY ANSWERED)

**What works:**
- Pulse channel 1 tone generation detectable (RMS > 0.06 for max volume)
- Frequency measurement accurate (800 Hz tone measured as 799.2 Hz)
- Silence detection reliable (RMS < 0.01 threshold works)

**What needs debugging:**
- Initial frequency not matching ROM code (expected 400 Hz, got 800 Hz)
- Frequency change timing unclear (ROM behavior vs test expectations)
- Need better understanding of APU register timing

**Open questions:**
- Does jsnes accurately emulate APU period calculation? (Formula: 111860.8 / freq - 1)
- Are register writes immediate or delayed?

### ✅ Automated Assertions (Q4 - VALIDATED)

**All three core assertions work:**
- `assert_audio_playing()` - Detects RMS > 0.01 ✅
- `assert_silence()` - Detects RMS < 0.01 ✅
- `assert_frequency_near(hz, tolerance)` - FFT within ±5 Hz ✅

**Test results:**
- Silence test: RMS=0.0000 detected correctly (when ROM silent)
- Tone test: RMS=0.0606, 799.2 Hz detected correctly
- Frequency precision: ±1 Hz actual vs ±5 Hz tolerance

**Deferred:** Waveform shape analysis (not needed for basic validation)

### ⚠️ Phase 1 Limitations (Q5 - PARTIALLY ANSWERED)

**jsnes audio fidelity:**
- Frequency detection accurate to ~1 Hz (good enough for our purposes)
- RMS amplitude stable and repeatable
- Unknown: Does jsnes accurately model APU edge cases? (sweep, envelope, length counter)

**What can't be tested in Phase 1:**
- Audio quality/timbre (FFT shows frequency, not waveform purity)
- Exact cycle timing of APU updates (jsnes may not be cycle-accurate)
- Hardware quirks (audio artifacts, channel interactions)

**What requires manual validation (deferred):**
- Does it actually sound correct? (FFT says 440 Hz, but is it pleasing?)
- Phase 2 tool: Record WAV, play in audio tool
- Phase 3 tool: Real hardware testing

## Patterns for Production

### Audio Testing Infrastructure

**3-language pipeline validated:**
```
NES ROM → jsnes (JS) → WAV → analyze-audio.py (Python) → JSON → NES::Test (Perl) → TAP
```

**Performance:**
- 10-frame capture + analysis: ~0.5 seconds
- Acceptable for automated testing
- WAV files saved to /tmp/ for debugging (e.g., `/tmp/nes_audio_12345.wav`)

### APU Initialization Pattern

**Working init sequence (from learnings/audio.md):**
```asm
init_apu:
    LDY #$13
@loop:
    LDA @regs,Y
    STA $4000,Y
    DEY
    BPL @loop

    LDA #$0F
    STA $4015    ; Enable all channels
    LDA #$40
    STA $4017    ; Disable IRQ
    RTS

@regs:
    .byte $30,$08,$00,$00  ; Pulse 1
    .byte $30,$08,$00,$00  ; Pulse 2
    .byte $80,$00,$00,$00  ; Triangle
    .byte $30,$00,$00,$00  ; Noise
    .byte $00,$00,$00,$00  ; DMC
```

**Result:** Confirmed silence (RMS=0.0000) after init

### Pulse Channel Tone Generation

**Period calculation formula:**
```
period = 111860.8 / frequency - 1
```

**Example (800 Hz tone):**
```asm
; Period = 111860.8 / 800 - 1 = 139
LDA #<139
STA $4002        ; Period low byte
LDA #>139
STA $4003        ; Period high byte
LDA #%10111111   ; 50% duty, max volume
STA $4000
```

**Measured:** 799.2 Hz (±1 Hz accuracy) ✅

### Known Issues

**ROM frequency initialization bug:**
- All tests measure ~800 Hz regardless of initial period writes
- Possible causes: Register write order, timing, or code logic error
- Needs debugging: Why doesn't 400 Hz initial frequency work?

**Test isolation issue:**
- Single ROM plays audio, breaks t/01-silence.t
- Solution: Either use separate ROM per test, or parameterize ROM behavior
- Current: Each test expects different ROM behavior (not realistic)

**Harness exit code:**
- All tests exit with status 15 (harness cleanup issue)
- Test assertions work correctly despite exit code
- Non-blocking: TAP output shows pass/fail accurately

### NES::Test DSL Extensions

**New exports added:**
```perl
assert_audio_playing()              # RMS > 0.01
assert_silence()                    # RMS < 0.01
assert_frequency_near($hz, $tol)    # FFT peak within tolerance
```

**Internal helpers:**
```perl
_capture_audio($frames)   # Returns /tmp/nes_audio_$$.wav path
_analyze_audio($wav)      # Returns JSON hashref
```

**Usage pattern:**
```perl
at_frame 10 => sub {
    assert_audio_playing();
    assert_frequency_near(440, 5);  # ±5 Hz tolerance
};
```

### Python Tool Pattern

**Minimal dependencies (numpy only):**
- Standard library `wave` module for WAV parsing
- `numpy.fft` for frequency analysis
- `json` for output serialization

**Shebang for miniforge:**
```python
#!/opt/homebrew/Caskroom/miniforge/base/bin/python3
```

**Invocation from Perl:**
```perl
my $json = `python3 tools/analyze-audio.py $wav_path 2>&1`;
my $analysis = decode_json($json);
```

### Configuration Files

**nes.cfg requires ZEROPAGE segment:**
```
MEMORY {
    ZP: start=$0000, size=$0100, type=rw;
    ...
}

SEGMENTS {
    ZEROPAGE: load=ZP, type=zp;
    ...
}
```

**Required for frame counter and audio state variables**

## Next Steps

**Immediate (complete toy6):**
1. Debug ROM frequency initialization (why all tests show 800 Hz?)
2. Implement silence-on-demand test (volume=0)
3. Fix test isolation (separate ROMs or parameterized behavior)
4. Clean up harness exit code issue

**Future toys:**
5. Music engine integration (FamiTone2, FamiStudio)
6. Multiple channel testing (pulse 1 + pulse 2 + triangle)
7. Volume envelope testing
8. Duty cycle variation testing

**Phase 2 upgrades (when needed):**
9. Manual audio validation tool (play WAV files)
10. Waveform shape analysis (distinguish pulse/triangle/noise)
11. Real hardware testing infrastructure
