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

_(To be filled after implementation)_

## Patterns for Production

_(To be filled after implementation)_
