import AudioKit
import AVFoundation

class AudioEngine {
    private let engine = AudioKit.AudioEngine()
    private let players = [AudioPlayer(), AudioPlayer()]
    private let mixer: Mixer
    private let variSpeed: VariSpeed
    private let midi = MIDI()

    var onSpeedChange: ((Float, UInt8) -> Void)?
    var onPlaybackEnd: ((Int) -> Void)?

    private(set) var currentNote: UInt8 = 60
    private(set) var currentSpeed: Float = 1.0

    var rampEnabled = false
    var rampDuration: Float = 0.3
    private var rampTimer: Timer?
    private var rampStart: Float = 1.0
    private var rampTarget: Float = 1.0
    private var rampStartTime: CFAbsoluteTime = 0

    private var recorder: NodeRecorder?
    var isRecording: Bool { recorder?.isRecording ?? false }

    init() {
        mixer = Mixer(players)
        variSpeed = VariSpeed(mixer)
        engine.output = variSpeed
        midi.addListener(MIDIHandler(engine: self))
    }

    func start() throws {
        try engine.start()
        midi.openInput()
    }

    func stop() {
        engine.stop()
        midi.closeAllInputs()
    }

    func loadFile(url: URL, player: Int) throws {
        guard (0...1).contains(player) else { return }
        try players[player].load(url: url, buffered: true)
        players[player].completionHandler = { [weak self] in
            DispatchQueue.main.async { self?.onPlaybackEnd?(player) }
        }
    }

    func play(player: Int) {
        guard (0...1).contains(player), hasFile(player: player) else { return }
        players[player].play()
    }

    func stopPlayback(player: Int) {
        guard (0...1).contains(player) else { return }
        players[player].stop()
    }

    func setVolume(_ volume: Float, player: Int) {
        guard (0...1).contains(player) else { return }
        players[player].volume = AUValue(volume)
    }

    func setLooping(_ looping: Bool, player: Int) {
        guard (0...1).contains(player) else { return }
        players[player].isLooping = looping
    }

    func setReversed(_ reversed: Bool, player: Int) {
        guard (0...1).contains(player) else { return }
        players[player].isReversed = reversed
    }

    func hasFile(player: Int) -> Bool {
        guard (0...1).contains(player) else { return false }
        return players[player].file != nil
    }

    func isPlaying(player: Int) -> Bool {
        guard (0...1).contains(player) else { return false }
        return players[player].isPlaying
    }

    func setSpeed(_ speed: Float) {
        currentSpeed = speed.clamped(to: 0.25...4.0)
        variSpeed.rate = AUValue(currentSpeed)
    }

    func handleNote(_ note: UInt8) {
        currentNote = note
        let speed = pow(2.0, Float(Int(note) - 60) / 12.0)
        if rampEnabled {
            rampTo(speed)
        } else {
            setSpeed(speed)
        }
        onSpeedChange?(speed.clamped(to: 0.25...4.0), note)
    }

    private func rampTo(_ target: Float) {
        rampTimer?.invalidate()
        rampStart = currentSpeed
        rampTarget = target.clamped(to: 0.25...4.0)
        rampStartTime = CFAbsoluteTimeGetCurrent()
        let interval: TimeInterval = 1.0 / 60.0
        rampTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            let elapsed = Float(CFAbsoluteTimeGetCurrent() - self.rampStartTime)
            let t = min(elapsed / self.rampDuration, 1.0)
            let speed = self.rampStart + (self.rampTarget - self.rampStart) * t
            self.setSpeed(speed)
            self.onSpeedChange?(self.currentSpeed, self.currentNote)
            if t >= 1.0 { timer.invalidate(); self.rampTimer = nil }
        }
    }

    func startRecording() throws {
        recorder = try NodeRecorder(node: variSpeed, shouldCleanupRecordings: false)
        try recorder?.record()
    }

    func stopRecording() -> AVAudioFile? {
        recorder?.stop()
        let file = recorder?.audioFile
        recorder = nil
        return file
    }
}

private extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

private class MIDIHandler: MIDIListener {
    weak var engine: AudioEngine?

    init(engine: AudioEngine) {
        self.engine = engine
    }

    func receivedMIDINoteOn(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {
        guard velocity > 0 else { return }
        DispatchQueue.main.async { self.engine?.handleNote(noteNumber) }
    }

    func receivedMIDINoteOff(noteNumber: MIDINoteNumber, velocity: MIDIVelocity, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDIController(_ controller: MIDIByte, value: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDIAftertouch(noteNumber: MIDINoteNumber, pressure: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDIAftertouch(_ pressure: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDIPitchWheel(_ pitchWheelValue: MIDIWord, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDIProgramChange(_ program: MIDIByte, channel: MIDIChannel, portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDISystemCommand(_ data: [MIDIByte], portID: MIDIUniqueID?, timeStamp: MIDITimeStamp?) {}
    func receivedMIDISetupChange() {}
    func receivedMIDIPropertyChange(propertyChangeInfo: MIDIObjectPropertyChangeNotification) {}
    func receivedMIDINotification(notification: MIDINotification) {}
}
