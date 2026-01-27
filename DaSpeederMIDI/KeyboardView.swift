import SwiftUI
import Keyboard
import Tonic

struct KeyboardView: View {
    var onNoteOn: ((UInt8) -> Void)?

    var body: some View {
        Keyboard(layout: .piano(pitchRange: Pitch(48) ... Pitch(72)),
                 noteOn: { pitch, _ in onNoteOn?(UInt8(pitch.intValue)) },
                 noteOff: { _ in })
            .frame(height: 120)
    }
}
