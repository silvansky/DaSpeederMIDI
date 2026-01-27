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
    private let volumeSlider = NSSlider(value: 1.0, minValue: 0, maxValue: 1, target: nil, action: nil)
    private let dropView = DropView()
    private var waveformHostingView: NSHostingView<AnyView>?
    private let rampCheckbox = NSButton(checkboxWithTitle: "Ramp", target: nil, action: nil)
    private let rampSlider = NSSlider(value: 0.3, minValue: 0.1, maxValue: 1.0, target: nil, action: nil)
    private let rampLabel = NSTextField(labelWithString: "0.3s")

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        updatePlayButton()

        do { try audioEngine.start() }
        catch { fileLabel.stringValue = "Audio engine error: \(error.localizedDescription)" }
    }

    private func setupUI() {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 12
        stack.alignment = .centerX
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)

        fileLabel.alignment = .center
        fileLabel.font = .systemFont(ofSize: 14, weight: .medium)

        speedLabel.alignment = .center
        speedLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)

        dropView.translatesAutoresizingMaskIntoConstraints = false

        rampLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        rampSlider.widthAnchor.constraint(greaterThanOrEqualToConstant: 80).isActive = true

        let controlsRow = NSStackView(views: [playButton, loopCheckbox, NSTextField(labelWithString: "Vol:"), volumeSlider, rampCheckbox, rampSlider, rampLabel])
        controlsRow.spacing = 12

        volumeSlider.widthAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true

        let keyboardView = KeyboardView(onNoteOn: { [weak self] note in
            self?.audioEngine.handleNote(note)
        })
        let hostingView = NSHostingView(rootView: keyboardView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        let waveformHost = NSHostingView(rootView: AnyView(EmptyView()))
        waveformHost.translatesAutoresizingMaskIntoConstraints = false
        waveformHost.isHidden = true
        self.waveformHostingView = waveformHost

        let dropContainer = NSView()
        dropContainer.translatesAutoresizingMaskIntoConstraints = false
        dropContainer.addSubview(dropView)
        dropContainer.addSubview(waveformHost)
        NSLayoutConstraint.activate([
            dropView.topAnchor.constraint(equalTo: dropContainer.topAnchor),
            dropView.bottomAnchor.constraint(equalTo: dropContainer.bottomAnchor),
            dropView.leadingAnchor.constraint(equalTo: dropContainer.leadingAnchor),
            dropView.trailingAnchor.constraint(equalTo: dropContainer.trailingAnchor),
            waveformHost.topAnchor.constraint(equalTo: dropContainer.topAnchor),
            waveformHost.bottomAnchor.constraint(equalTo: dropContainer.bottomAnchor),
            waveformHost.leadingAnchor.constraint(equalTo: dropContainer.leadingAnchor),
            waveformHost.trailingAnchor.constraint(equalTo: dropContainer.trailingAnchor),
        ])

        stack.addArrangedSubview(fileLabel)
        stack.addArrangedSubview(dropContainer)
        stack.addArrangedSubview(speedLabel)
        stack.addArrangedSubview(controlsRow)
        stack.addArrangedSubview(hostingView)

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dropContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            dropContainer.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -32),
            hostingView.heightAnchor.constraint(equalToConstant: 120),
            hostingView.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -32),
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
    }

    @objc private func toggleRamp() {
        audioEngine.rampEnabled = rampCheckbox.state == .on
    }

    @objc private func rampDurationChanged() {
        audioEngine.rampDuration = rampSlider.floatValue
        rampLabel.stringValue = String(format: "%.1fs", rampSlider.floatValue)
    }
}
