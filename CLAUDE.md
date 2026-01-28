# DaSpeederMIDI

macOS app: drag-drop audio files into two players, control playback speed via MIDI keyboard or on-screen piano.

## Build

Open `DaSpeederMIDI.xcodeproj` in Xcode, build and run. SPM dependencies resolve automatically.

## Dependencies (SPM)

- AudioKit 5.6.5+ — audio engine, MIDI, VariSpeed, NodeRecorder
- Keyboard 1.4.1+ — on-screen SwiftUI piano (brings in Tonic)
- Waveform — Metal-based waveform display

## Architecture

```
Player1 ↘
          Mixer → VariSpeed → engine.output
Player2 ↗           ↑
               NodeRecorder (tap for recording)
```

- `AudioEngine.swift` — AudioKit wrapper. Two players mixed together, shared speed control. Per-player: load, play/stop, volume, loop, reverse. Speed mapping: `pow(2, (note - 60) / 12)` (C4 = 1x). Speed ramping via Timer. Recording via `NodeRecorder` on variSpeed node.
- `DropView.swift` — NSView drag-drop target. Validates audio extensions (wav, aif, aiff, mp3, m4a, caf, flac).
- `KeyboardView.swift` — SwiftUI view wrapping AudioKit `Keyboard` (C2–C7, covers 0.25x–4x range).
- `ViewController.swift` — Two-player UI with per-player drop zones, waveforms, controls (play, loop, reverse, volume). Shared speed display, record, ramp controls. All UI in code via direct Auto Layout constraints (no NSStackView). Hosts keyboard and waveforms via `NSHostingView`.
- `AppDelegate.swift` — Minimal, default Xcode template.

## Conventions

- No storyboard UI besides window/menu structure
- All view layout in code (direct Auto Layout, no stack views)
- Callbacks via closures, not delegates
- Speed clamped to 0.25–4.0x
- Files loaded as buffered for seamless looping
- Recordings exported as 16-bit PCM WAV
