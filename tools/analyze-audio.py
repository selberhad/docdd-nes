#!/opt/homebrew/Caskroom/miniforge/base/bin/python3
"""
Analyze WAV file and output JSON metrics for automated audio testing.

Usage: analyze-audio.py <audio.wav>
Output: JSON with RMS, frequency, playing/silence detection
"""

import wave
import numpy as np
import json
import sys

def read_wav(path):
    """Read WAV file and return samples + sample rate."""
    with wave.open(path, 'rb') as wav:
        rate = wav.getframerate()
        n_channels = wav.getnchannels()
        frames = wav.readframes(wav.getnframes())

        # Parse as 16-bit PCM
        data = np.frombuffer(frames, dtype=np.int16)

        # Convert to mono if stereo
        if n_channels == 2:
            data = data.reshape(-1, 2).mean(axis=1)

        # Normalize to [-1.0, 1.0]
        samples = data.astype(float) / 32768.0

        return samples, rate

def analyze_audio(samples, rate):
    """Perform audio analysis: RMS, FFT frequency detection."""
    # RMS amplitude
    rms = float(np.sqrt(np.mean(samples ** 2)))

    # FFT for frequency analysis
    fft = np.fft.fft(samples)
    freqs = np.fft.fftfreq(len(samples), 1.0 / rate)
    magnitude = np.abs(fft[:len(fft)//2])

    # Find dominant frequency (ignore DC component at index 0)
    peak_idx = np.argmax(magnitude[1:]) + 1
    dominant_freq = float(abs(freqs[peak_idx]))

    # Detection thresholds
    silence_threshold = 0.01

    return {
        'rms': rms,
        'frequency': dominant_freq,
        'is_playing': rms > silence_threshold,
        'is_silence': rms < silence_threshold,
        'sample_rate': rate,
        'duration_sec': len(samples) / rate
    }

def main():
    if len(sys.argv) != 2:
        print("Usage: analyze-audio.py <audio.wav>", file=sys.stderr)
        sys.exit(1)

    wav_path = sys.argv[1]

    try:
        samples, rate = read_wav(wav_path)
        analysis = analyze_audio(samples, rate)
        print(json.dumps(analysis))
    except Exception as e:
        print(json.dumps({'error': str(e)}), file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
