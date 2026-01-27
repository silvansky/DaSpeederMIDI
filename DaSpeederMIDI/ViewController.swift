import Cocoa
import SwiftUI
import Waveform
import AVFoundation

class ViewController: NSViewController {
    private let audioEngine = AudioEngine()
    private let fileLabel = NSTextField(labelWithString: "Drop audio file here")
    private let speedLabel = NSTextField(labelWithString: "Speed: 1.00x (C4)")
    private let playButton = NSButton(title: "Play", target: nil, action: nil)
    private let loopCheckbox = NSButton(checkboxWithTitle: "Loop", target: nil, action: nil)
    private let volumeSlider = NSSlider(value: 1.0, minValue: 0, maxValue: 4, target: nil, action: nil)
    private let dropView = DropView()
    private var waveformHostingView: NSHostingView<AnyView>?
    private let volumeLabel = NSTextField(labelWithString: "1.00")
    private let rampCheckbox = NSButton(checkboxWithTitle: "Ramp", target: nil, action: nil)
    private let rampSlider = NSSlider(value: 0.3, minValue: 0.1, maxValue: 1.0, target: nil, action: nil)
    private let rampLabel = NSTextField(labelWithString: "0.3s")
    private let volLabel = NSTextField(labelWithString: "Vol:")

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        updatePlayButton()

        do { try audioEngine.start() }
        catch { fileLabel.stringValue = "Audio engine error: \(error.localizedDescription)" }
    }

    private func setupUI() {
        let pad: CGFloat = 16
        let spacing: CGFloat = 8

        fileLabel.alignment = .center
        fileLabel.font = .systemFont(ofSize: 14, weight: .medium)
        fileLabel.translatesAutoresizingMaskIntoConstraints = false

        speedLabel.alignment = .center
        speedLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        speedLabel.translatesAutoresizingMaskIntoConstraints = false

        dropView.translatesAutoresizingMaskIntoConstraints = false

        let waveformHost = NSHostingView(rootView: AnyView(EmptyView()))
        waveformHost.translatesAutoresizingMaskIntoConstraints = false
        waveformHost.isHidden = true
        self.waveformHostingView = waveformHost

        let dropContainer = NSView()
        dropContainer.translatesAutoresizingMaskIntoConstraints = false
        dropContainer.wantsLayer = true
        dropContainer.layer?.masksToBounds = true
        dropContainer.addSubview(dropView)
        dropContainer.addSubview(waveformHost)

        // Controls row
        let controls = [playButton, loopCheckbox, volLabel, volumeSlider, volumeLabel, rampCheckbox, rampSlider, rampLabel] as [NSView]
        let controlsRow = NSView()
        controlsRow.translatesAutoresizingMaskIntoConstraints = false
        volumeLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        rampLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        for c in controls {
            c.translatesAutoresizingMaskIntoConstraints = false
            controlsRow.addSubview(c)
            c.centerYAnchor.constraint(equalTo: controlsRow.centerYAnchor).isActive = true
        }

        // Keyboard
        let keyboardView = KeyboardView(onNoteOn: { [weak self] note in
            self?.audioEngine.handleNote(note)
        })
        let keyboardHost = NSHostingView(rootView: keyboardView)
        keyboardHost.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(fileLabel)
        view.addSubview(dropContainer)
        view.addSubview(speedLabel)
        view.addSubview(controlsRow)
        view.addSubview(keyboardHost)

        NSLayoutConstraint.activate([
            // File label
            fileLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: pad),
            fileLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            fileLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),

            // Drop container — takes all available space
            dropContainer.topAnchor.constraint(equalTo: fileLabel.bottomAnchor, constant: spacing),
            dropContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            dropContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            dropContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),

            // Drop view & waveform fill container
            dropView.topAnchor.constraint(equalTo: dropContainer.topAnchor),
            dropView.bottomAnchor.constraint(equalTo: dropContainer.bottomAnchor),
            dropView.leadingAnchor.constraint(equalTo: dropContainer.leadingAnchor),
            dropView.trailingAnchor.constraint(equalTo: dropContainer.trailingAnchor),
            waveformHost.topAnchor.constraint(equalTo: dropContainer.topAnchor),
            waveformHost.bottomAnchor.constraint(equalTo: dropContainer.bottomAnchor),
            waveformHost.leadingAnchor.constraint(equalTo: dropContainer.leadingAnchor),
            waveformHost.trailingAnchor.constraint(equalTo: dropContainer.trailingAnchor),

            // Speed label
            speedLabel.topAnchor.constraint(equalTo: dropContainer.bottomAnchor, constant: spacing),
            speedLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            speedLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),

            // Controls row
            controlsRow.topAnchor.constraint(equalTo: speedLabel.bottomAnchor, constant: spacing),
            controlsRow.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: pad),
            controlsRow.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -pad),
            controlsRow.heightAnchor.constraint(equalToConstant: 24),

            // Controls horizontal layout
            playButton.leadingAnchor.constraint(equalTo: controlsRow.leadingAnchor),
            loopCheckbox.leadingAnchor.constraint(equalTo: playButton.trailingAnchor, constant: 8),
            volLabel.leadingAnchor.constraint(equalTo: loopCheckbox.trailingAnchor, constant: 12),
            volumeSlider.leadingAnchor.constraint(equalTo: volLabel.trailingAnchor, constant: 4),
            volumeSlider.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            volumeLabel.leadingAnchor.constraint(equalTo: volumeSlider.trailingAnchor, constant: 4),
            rampCheckbox.leadingAnchor.constraint(equalTo: volumeLabel.trailingAnchor, constant: 12),
            rampSlider.leadingAnchor.constraint(equalTo: rampCheckbox.trailingAnchor, constant: 4),
            rampSlider.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            rampLabel.leadingAnchor.constraint(equalTo: rampSlider.trailingAnchor, constant: 4),
            rampLabel.trailingAnchor.constraint(lessThanOrEqualTo: controlsRow.trailingAnchor),

            // Keyboard — fixed height at bottom
            keyboardHost.topAnchor.constraint(equalTo: controlsRow.bottomAnchor, constant: spacing),
            keyboardHost.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardHost.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardHost.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            keyboardHost.heightAnchor.constraint(equalToConstant: 120),
        ])
    }

    private func setupBindings() {
        dropView.onFileDropped = { [weak self] url in
            self?.loadFile(url)
        }

        audioEngine.onSpeedChange = { [weak self] speed, note in
            self?.updateSpeedLabel(speed: speed, note: note)
        }

        audioEngine.onPlaybackEnd = { [weak self] in
            self?.updatePlayButton()
        }

        playButton.target = self
        playButton.action = #selector(togglePlay)

        loopCheckbox.target = self
        loopCheckbox.action = #selector(toggleLoop)
        loopCheckbox.state = .on
        audioEngine.isLooping = true

        volumeSlider.target = self
        volumeSlider.action = #selector(volumeChanged)

        rampCheckbox.target = self
        rampCheckbox.action = #selector(toggleRamp)

        rampSlider.target = self
        rampSlider.action = #selector(rampDurationChanged)
    }

    private func loadFile(_ url: URL) {
        do {
            try audioEngine.loadFile(url: url)
            fileLabel.stringValue = url.lastPathComponent
            showWaveform(url: url)
            updatePlayButton()
            audioEngine.play()
            updatePlayButton()
        } catch {
            fileLabel.stringValue = "Error: \(error.localizedDescription)"
        }
    }

    private func showWaveform(url: URL) {
        guard let file = try? AVAudioFile(forReading: url),
              let channelData = file.floatChannelData(),
              let samples = channelData.first else { return }
        let buffer = SampleBuffer(samples: samples)
        let waveform = Waveform(samples: buffer)
            .foregroundColor(.accentColor)
        waveformHostingView?.rootView = AnyView(waveform)
        waveformHostingView?.isHidden = false
    }

    private func updateSpeedLabel(speed: Float, note: UInt8) {
        let noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let name = noteNames[Int(note) % 12]
        let octave = Int(note) / 12 - 1
        speedLabel.stringValue = String(format: "Speed: %.2fx (%@%d)", speed, name, octave)
    }

    private func updatePlayButton() {
        playButton.isEnabled = audioEngine.hasFile
        playButton.title = audioEngine.isPlaying ? "Stop" : "Play"
    }

    @objc private func togglePlay() {
        if audioEngine.isPlaying {
            audioEngine.stopPlayback()
        } else {
            audioEngine.play()
        }
        updatePlayButton()
    }

    @objc private func toggleLoop() {
        audioEngine.isLooping = loopCheckbox.state == .on
    }

    @objc private func volumeChanged() {
        audioEngine.volume = volumeSlider.floatValue
        volumeLabel.stringValue = String(format: "%.2f", volumeSlider.floatValue)
    }

    @objc private func toggleRamp() {
        audioEngine.rampEnabled = rampCheckbox.state == .on
    }

    @objc private func rampDurationChanged() {
        audioEngine.rampDuration = rampSlider.floatValue
        rampLabel.stringValue = String(format: "%.1fs", rampSlider.floatValue)
    }
}
