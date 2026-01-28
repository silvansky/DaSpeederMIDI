import Cocoa
import SwiftUI
import Waveform
import AVFoundation

class ViewController: NSViewController {
    private let audioEngine = AudioEngine()

    private let fileLabel1 = NSTextField(labelWithString: "Player 1 — Drop audio file")
    private let fileLabel2 = NSTextField(labelWithString: "Player 2 — Drop audio file")
    private let speedLabel = NSTextField(labelWithString: "Speed: 1.00x (C4)")

    private let dropView1 = DropView()
    private let dropView2 = DropView()
    private var waveformHost1: NSHostingView<AnyView>?
    private var waveformHost2: NSHostingView<AnyView>?

    private let playButton1 = NSButton(title: "Play", target: nil, action: nil)
    private let playButton2 = NSButton(title: "Play", target: nil, action: nil)
    private let loopCheckbox1 = NSButton(checkboxWithTitle: "Loop", target: nil, action: nil)
    private let loopCheckbox2 = NSButton(checkboxWithTitle: "Loop", target: nil, action: nil)
    private let reverseCheckbox1 = NSButton(checkboxWithTitle: "Rev", target: nil, action: nil)
    private let reverseCheckbox2 = NSButton(checkboxWithTitle: "Rev", target: nil, action: nil)
    private let volumeSlider1 = NSSlider(value: 1.0, minValue: 0, maxValue: 2, target: nil, action: nil)
    private let volumeSlider2 = NSSlider(value: 1.0, minValue: 0, maxValue: 2, target: nil, action: nil)
    private let volumeLabel1 = NSTextField(labelWithString: "1.00")
    private let volumeLabel2 = NSTextField(labelWithString: "1.00")

    private let spinner1 = NSProgressIndicator()
    private let spinner2 = NSProgressIndicator()

    private let recordButton = NSButton(title: "Record", target: nil, action: nil)
    private let rampCheckbox = NSButton(checkboxWithTitle: "Ramp", target: nil, action: nil)
    private let rampSlider = NSSlider(value: 0.3, minValue: 0.1, maxValue: 1.0, target: nil, action: nil)
    private let rampLabel = NSTextField(labelWithString: "0.3s")

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        updatePlayButtons()

        do { try audioEngine.start() }
        catch { fileLabel1.stringValue = "Audio engine error: \(error.localizedDescription)" }
    }

    private func setupUI() {
        let pad: CGFloat = 16
        let spacing: CGFloat = 8

        for label in [fileLabel1, fileLabel2] {
            label.alignment = .center
            label.font = .systemFont(ofSize: 14, weight: .medium)
            label.translatesAutoresizingMaskIntoConstraints = false
        }

        speedLabel.alignment = .center
        speedLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        speedLabel.translatesAutoresizingMaskIntoConstraints = false

        dropView1.translatesAutoresizingMaskIntoConstraints = false
        dropView2.translatesAutoresizingMaskIntoConstraints = false

        let wh1 = NSHostingView(rootView: AnyView(EmptyView()))
        wh1.translatesAutoresizingMaskIntoConstraints = false
        wh1.isHidden = true
        waveformHost1 = wh1

        let wh2 = NSHostingView(rootView: AnyView(EmptyView()))
        wh2.translatesAutoresizingMaskIntoConstraints = false
        wh2.isHidden = true
        waveformHost2 = wh2

        let dropContainer1 = makeDropContainer(dropView: dropView1, waveformHost: wh1, spinner: spinner1)
        let dropContainer2 = makeDropContainer(dropView: dropView2, waveformHost: wh2, spinner: spinner2)

        let controlsRow1 = makeControlsRow(playButton: playButton1, loopCheckbox: loopCheckbox1, reverseCheckbox: reverseCheckbox1, volumeSlider: volumeSlider1, volumeLabel: volumeLabel1)
        let controlsRow2 = makeControlsRow(playButton: playButton2, loopCheckbox: loopCheckbox2, reverseCheckbox: reverseCheckbox2, volumeSlider: volumeSlider2, volumeLabel: volumeLabel2)

        let sharedControlsRow = NSView()
        sharedControlsRow.translatesAutoresizingMaskIntoConstraints = false
        let sharedControls = [recordButton, rampCheckbox, rampSlider, rampLabel] as [NSView]
        rampLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        for c in sharedControls {
            c.translatesAutoresizingMaskIntoConstraints = false
            sharedControlsRow.addSubview(c)
            c.centerYAnchor.constraint(equalTo: sharedControlsRow.centerYAnchor).isActive = true
        }

        let keyboardView = KeyboardView(onNoteOn: { [weak self] note in
            self?.audioEngine.handleNote(note)
        })
        let keyboardHost = NSHostingView(rootView: keyboardView)
        keyboardHost.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(fileLabel1)
        view.addSubview(dropContainer1)
        view.addSubview(controlsRow1)
        view.addSubview(fileLabel2)
        view.addSubview(dropContainer2)
        view.addSubview(controlsRow2)
        view.addSubview(speedLabel)
        view.addSubview(sharedControlsRow)
        view.addSubview(keyboardHost)

        NSLayoutConstraint.activate([
            // Player 1
            fileLabel1.topAnchor.constraint(equalTo: view.topAnchor, constant: pad),
            fileLabel1.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            fileLabel1.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),

            dropContainer1.topAnchor.constraint(equalTo: fileLabel1.bottomAnchor, constant: spacing),
            dropContainer1.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            dropContainer1.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            dropContainer1.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),

            controlsRow1.topAnchor.constraint(equalTo: dropContainer1.bottomAnchor, constant: spacing),
            controlsRow1.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            controlsRow1.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            controlsRow1.heightAnchor.constraint(equalToConstant: 24),

            // Player 2
            fileLabel2.topAnchor.constraint(equalTo: controlsRow1.bottomAnchor, constant: pad),
            fileLabel2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            fileLabel2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),

            dropContainer2.topAnchor.constraint(equalTo: fileLabel2.bottomAnchor, constant: spacing),
            dropContainer2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            dropContainer2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            dropContainer2.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),
            dropContainer2.heightAnchor.constraint(equalTo: dropContainer1.heightAnchor),

            controlsRow2.topAnchor.constraint(equalTo: dropContainer2.bottomAnchor, constant: spacing),
            controlsRow2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            controlsRow2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            controlsRow2.heightAnchor.constraint(equalToConstant: 24),

            // Speed label
            speedLabel.topAnchor.constraint(equalTo: controlsRow2.bottomAnchor, constant: pad),
            speedLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            speedLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),

            // Shared controls
            sharedControlsRow.topAnchor.constraint(equalTo: speedLabel.bottomAnchor, constant: spacing),
            sharedControlsRow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            sharedControlsRow.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            sharedControlsRow.heightAnchor.constraint(equalToConstant: 24),

            recordButton.leadingAnchor.constraint(equalTo: sharedControlsRow.leadingAnchor),
            rampCheckbox.leadingAnchor.constraint(equalTo: recordButton.trailingAnchor, constant: 12),
            rampSlider.leadingAnchor.constraint(equalTo: rampCheckbox.trailingAnchor, constant: 4),
            rampSlider.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            rampLabel.leadingAnchor.constraint(equalTo: rampSlider.trailingAnchor, constant: 4),
            rampLabel.trailingAnchor.constraint(lessThanOrEqualTo: sharedControlsRow.trailingAnchor),

            // Keyboard
            keyboardHost.topAnchor.constraint(equalTo: sharedControlsRow.bottomAnchor, constant: spacing),
            keyboardHost.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardHost.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardHost.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            keyboardHost.heightAnchor.constraint(equalToConstant: 120),
        ])
    }

    private func makeDropContainer(dropView: DropView, waveformHost: NSHostingView<AnyView>, spinner: NSProgressIndicator) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.wantsLayer = true
        container.layer?.masksToBounds = true
        container.addSubview(dropView)
        container.addSubview(waveformHost)

        spinner.style = .spinning
        spinner.isIndeterminate = true
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.isHidden = true
        container.addSubview(spinner)

        NSLayoutConstraint.activate([
            dropView.topAnchor.constraint(equalTo: container.topAnchor),
            dropView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            dropView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            dropView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            waveformHost.topAnchor.constraint(equalTo: container.topAnchor),
            waveformHost.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            waveformHost.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            waveformHost.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            spinner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        return container
    }

    private func makeControlsRow(playButton: NSButton, loopCheckbox: NSButton, reverseCheckbox: NSButton, volumeSlider: NSSlider, volumeLabel: NSTextField) -> NSView {
        let row = NSView()
        row.translatesAutoresizingMaskIntoConstraints = false
        let volLabel = NSTextField(labelWithString: "Vol:")
        volumeLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)

        let controls = [playButton, loopCheckbox, reverseCheckbox, volLabel, volumeSlider, volumeLabel] as [NSView]
        for c in controls {
            c.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(c)
            c.centerYAnchor.constraint(equalTo: row.centerYAnchor).isActive = true
        }

        NSLayoutConstraint.activate([
            playButton.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            loopCheckbox.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 8),
            reverseCheckbox.leadingAnchor.constraint(equalTo: loopCheckbox.trailingAnchor, constant: 8),
            volLabel.leadingAnchor.constraint(equalTo: reverseCheckbox.trailingAnchor, constant: 12),
            volumeSlider.leadingAnchor.constraint(equalTo: volLabel.trailingAnchor, constant: 4),
            volumeSlider.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            volumeLabel.leadingAnchor.constraint(equalTo: volumeSlider.trailingAnchor, constant: 4),
            volumeLabel.trailingAnchor.constraint(lessThanOrEqualTo: row.trailingAnchor),
        ])
        return row
    }

    private func setupBindings() {
        dropView1.onFileDropped = { [weak self] url in self?.loadFile(url, player: 0) }
        dropView2.onFileDropped = { [weak self] url in self?.loadFile(url, player: 1) }

        audioEngine.onSpeedChange = { [weak self] speed, note in
            self?.updateSpeedLabel(speed: speed, note: note)
        }

        audioEngine.onPlaybackEnd = { [weak self] player in
            self?.updatePlayButtons()
        }

        playButton1.target = self
        playButton1.action = #selector(togglePlay1)
        playButton2.target = self
        playButton2.action = #selector(togglePlay2)

        loopCheckbox1.target = self
        loopCheckbox1.action = #selector(toggleLoop1)
        loopCheckbox1.state = .on
        audioEngine.setLooping(true, player: 0)

        loopCheckbox2.target = self
        loopCheckbox2.action = #selector(toggleLoop2)
        loopCheckbox2.state = .on
        audioEngine.setLooping(true, player: 1)

        reverseCheckbox1.target = self
        reverseCheckbox1.action = #selector(toggleReverse1)
        reverseCheckbox2.target = self
        reverseCheckbox2.action = #selector(toggleReverse2)

        volumeSlider1.target = self
        volumeSlider1.action = #selector(volumeChanged1)
        volumeSlider2.target = self
        volumeSlider2.action = #selector(volumeChanged2)

        rampCheckbox.target = self
        rampCheckbox.action = #selector(toggleRamp)

        rampSlider.target = self
        rampSlider.action = #selector(rampDurationChanged)

        recordButton.target = self
        recordButton.action = #selector(toggleRecord)
    }

    private func loadFile(_ url: URL, player: Int) {
        let label = player == 0 ? fileLabel1 : fileLabel2
        let spinner = player == 0 ? spinner1 : spinner2
        let waveformHost = player == 0 ? waveformHost1 : waveformHost2

        label.stringValue = "Player \(player + 1) — Loading…"
        spinner.isHidden = false
        spinner.startAnimation(nil)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            do {
                try self.audioEngine.loadFile(url: url, player: player)
                let samples = Self.readSamples(url: url)
                DispatchQueue.main.async {
                    spinner.stopAnimation(nil)
                    spinner.isHidden = true
                    label.stringValue = "Player \(player + 1) — \(url.lastPathComponent)"
                    if let samples {
                        self.showWaveform(samples: samples, url: url, host: waveformHost)
                    }
                    self.updatePlayButtons()
                    self.audioEngine.play(player: player)
                    self.updatePlayButtons()
                }
            } catch {
                DispatchQueue.main.async {
                    spinner.stopAnimation(nil)
                    spinner.isHidden = true
                    label.stringValue = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

    private static func readSamples(url: URL) -> [Float]? {
        guard let file = try? AVAudioFile(forReading: url),
              let channelData = file.floatChannelData(),
              let samples = channelData.first else { return nil }
        return samples
    }

    private func showWaveform(samples: [Float], url: URL, host: NSHostingView<AnyView>?) {
        let buffer = SampleBuffer(samples: samples)
        let waveform = Waveform(samples: buffer)
            .foregroundColor(.accentColor)
            .id(url)
        host?.rootView = AnyView(waveform)
        host?.isHidden = false
    }

    private func updateSpeedLabel(speed: Float, note: UInt8) {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let name = noteNames[Int(note) % 12]
        let octave = Int(note) / 12 - 1
        speedLabel.stringValue = String(format: "Speed: %.2fx (%@%d)", speed, name, octave)
    }

    private func updatePlayButtons() {
        playButton1.isEnabled = audioEngine.hasFile(player: 0)
        playButton1.title = audioEngine.isPlaying(player: 0) ? "Stop" : "Play"
        playButton2.isEnabled = audioEngine.hasFile(player: 1)
        playButton2.title = audioEngine.isPlaying(player: 1) ? "Stop" : "Play"
    }

    @objc private func togglePlay1() { togglePlay(player: 0) }
    @objc private func togglePlay2() { togglePlay(player: 1) }

    private func togglePlay(player: Int) {
        if audioEngine.isPlaying(player: player) {
            audioEngine.stopPlayback(player: player)
        } else {
            audioEngine.play(player: player)
        }
        updatePlayButtons()
    }

    @objc private func toggleLoop1() { audioEngine.setLooping(loopCheckbox1.state == .on, player: 0) }
    @objc private func toggleLoop2() { audioEngine.setLooping(loopCheckbox2.state == .on, player: 1) }

    @objc private func toggleReverse1() { audioEngine.setReversed(reverseCheckbox1.state == .on, player: 0) }
    @objc private func toggleReverse2() { audioEngine.setReversed(reverseCheckbox2.state == .on, player: 1) }

    @objc private func volumeChanged1() {
        audioEngine.setVolume(volumeSlider1.floatValue, player: 0)
        volumeLabel1.stringValue = String(format: "%.2f", volumeSlider1.floatValue)
    }

    @objc private func volumeChanged2() {
        audioEngine.setVolume(volumeSlider2.floatValue, player: 1)
        volumeLabel2.stringValue = String(format: "%.2f", volumeSlider2.floatValue)
    }

    @objc private func toggleRamp() {
        audioEngine.rampEnabled = rampCheckbox.state == .on
    }

    @objc private func rampDurationChanged() {
        audioEngine.rampDuration = rampSlider.floatValue
        rampLabel.stringValue = String(format: "%.1fs", rampSlider.floatValue)
    }

    @objc private func toggleRecord() {
        if audioEngine.isRecording {
            guard let file = audioEngine.stopRecording() else {
                recordButton.title = "Record"
                return
            }
            recordButton.title = "Record"
            presentSaveDialog(for: file)
        } else {
            do {
                try audioEngine.startRecording()
                recordButton.title = "Stop Rec"
            } catch {
                fileLabel1.stringValue = "Record error: \(error.localizedDescription)"
            }
        }
    }

    private func presentSaveDialog(for file: AVAudioFile) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let defaultName = "DaSpeeder_recording_\(formatter.string(from: Date())).wav"

        let panel = NSSavePanel()
        panel.nameFieldStringValue = defaultName
        panel.allowedContentTypes = [.wav]
        panel.beginSheetModal(for: view.window!) { response in
            guard response == .OK, let url = panel.url else { return }
            self.exportToWAV(source: file, destination: url)
        }
    }

    private func exportToWAV(source: AVAudioFile, destination: URL) {
        do {
            let format = source.processingFormat
            let wavSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: format.sampleRate,
                AVNumberOfChannelsKey: format.channelCount,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsNonInterleaved: false,
            ]
            let outputFile = try AVAudioFile(forWriting: destination, settings: wavSettings)
            let buffer = AVAudioPCMBuffer(pcmFormat: source.processingFormat, frameCapacity: AVAudioFrameCount(source.length))!
            try source.read(into: buffer)
            try outputFile.write(from: buffer)
        } catch {
            DispatchQueue.main.async {
                self.fileLabel1.stringValue = "Export error: \(error.localizedDescription)"
            }
        }
    }
}
