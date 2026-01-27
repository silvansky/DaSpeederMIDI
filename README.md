# Da Speeder MIDI

A macOS app that lets you control audio playback speed using a MIDI keyboard. Drop an audio file, press keys to change speed — middle C plays at normal speed, each semitone shifts by a factor of 2^(1/12).

## Features

- **Drag & drop** audio files (WAV, AIFF, MP3, M4A, CAF, FLAC)
- **MIDI speed control** — hardware MIDI keyboard or on-screen piano (C2–C7)
- **Speed range** — 0.25x to 4.0x (C4 = 1.0x, octave up = 2x, octave down = 0.5x)
- **Speed ramping** — smooth transition between speeds with configurable duration (0.1–1.0s)
- **Waveform display** — visualize the loaded audio file
- **Volume control** — 0 to 4x gain
- **Loop mode** — seamless buffered looping
- **Recording** — capture speed-modified output and export as WAV

## Requirements

- macOS 15.7+
- Xcode 16+

## Building

1. Open `DaSpeederMIDI.xcodeproj` in Xcode
2. Build and run (⌘R)

SPM dependencies (AudioKit, Keyboard, Waveform) resolve automatically on first build.

## Usage

1. Launch the app
2. Drop an audio file onto the waveform area — playback starts automatically
3. Play notes on a connected MIDI keyboard or the on-screen piano to change speed
4. Use controls to toggle looping, adjust volume, enable speed ramping
5. Press Record to capture output, then save as WAV when done

## Speed Mapping

| Note | Speed |
|------|-------|
| C2   | 0.25x |
| C3   | 0.5x  |
| C4   | 1.0x  |
| C5   | 2.0x  |
| C6   | 4.0x  |

Intermediate semitones follow `2^((note - 60) / 12)`.

## License

All rights reserved.
