# DaSpeederMIDI

macOS app: drag-drop audio file, control playback speed via MIDI keyboard. On-screen SwiftUI keyboard included.

## Build

Open `DaSpeederMIDI.xcodeproj` in Xcode, build and run. SPM dependencies resolve automatically.

## Dependencies (SPM)

- AudioKit 5.6.5+ — audio engine, MIDI, VariSpeed
- Keyboard 1.4.1+ — on-screen SwiftUI piano (brings in Tonic)

## Architecture

```
AudioPlayer → VariSpeed → engine.output
```

- `AudioEngine.swift` — AudioKit wrapper. Loads files, plays/stops, sets speed. Receives hardware MIDI via `MIDIListener`. Speed mapping: `pow(2, (note - 60) / 12)` (C4 = 1x).
- `DropView.swift` — NSView drag-drop target. Validates audio extensions (wav, aif, aiff, mp3, m4a, caf, flac).
- `KeyboardView.swift` — SwiftUI view wrapping AudioKit `Keyboard` (C3–C5 piano layout).
- `ViewController.swift` — All UI in code via NSStackView + Auto Layout. Hosts keyboard via `NSHostingView`.
- `AppDelegate.swift` — Minimal, default Xcode template.

## Conventions

- No storyboard UI besides window/menu structure
- All view layout in code (Auto Layout)
- Callbacks via closures, not delegates
- Speed clamped to 0.25–4.0x
