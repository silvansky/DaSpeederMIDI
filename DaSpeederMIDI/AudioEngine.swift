import AudioKit
import AVFoundation

class AudioEngine {
    private let engine = AudioKit.AudioEngine()
    private let player = AudioPlayer()
    private let variSpeed: VariSpeed
    private let midi = MIDI()

    var onSpeedChange: ((Float, UInt8) -> Void)?
    var onPlaybackEnd: (() -> Void)?

    var isLooping: Bool {
        get { player.isLooping }
        set { player.isLooping = newValue }
    }

    var volume: Float {
        get { Float(player.volume) }
        set { player.volume = AUValue(newValue) }
    }

    var isPlaying: Bool { player.isPlaying }
    private(set) var currentNote: UInt8 = 60
    private(set) var currentSpeed: Float = 1.0
    private var fileLoaded = false

    var rampEnabled = false
    var rampDuration: Float = 0.3
    private var rampTimer: Timer?
    private var rampStart: Float = 1.0
    private var rampTarget: Float = 1.0
    private var rampStartTime: CFAbsoluteTime = 0

    init() {
        variSpeed = VariSpeed(player)
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

    func loadFile(url: URL) throws {
        try player.load(url: url, buffered: true)
        fileLoaded = true
        player.completionHandler = { [weak self] in
            DispatchQueue.main.async { self?.onPlaybackEnd?() }
        }
    }

    func play() {
        guard fileLoaded else { return }
        player.play()
    }

    func stopPlayback() {
        player.stop()
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

    var hasFile: Bool { fileLoaded }
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
