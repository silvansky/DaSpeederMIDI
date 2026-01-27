import Cocoa
import SwiftUI

class ViewController: NSViewController {
    private let audioEngine = AudioEngine()
    private let fileLabel = NSTextField(labelWithString: "Drop audio file here")
    private let speedLabel = NSTextField(labelWithString: "Speed: 1.00x (C4)")
    private let playButton = NSButton(title: "Play", target: nil, action: nil)
    private let loopCheckbox = NSButton(checkboxWithTitle: "Loop", target: nil, action: nil)
    private let volumeSlider = NSSlider(value: 1.0, minValue: 0, maxValue: 1, target: nil, action: nil)
    private let dropView = DropView()

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

        let controlsRow = NSStackView(views: [playButton, loopCheckbox, NSTextField(labelWithString: "Vol:"), volumeSlider])
        controlsRow.spacing = 12

        volumeSlider.widthAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true

        let keyboardView = KeyboardView(onNoteOn: { [weak self] note in
            self?.audioEngine.handleNote(note)
        })
        let hostingView = NSHostingView(rootView: keyboardView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(fileLabel)
        stack.addArrangedSubview(dropView)
        stack.addArrangedSubview(speedLabel)
        stack.addArrangedSubview(controlsRow)
        stack.addArrangedSubview(hostingView)

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dropView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120),
            dropView.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -32),
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
    }

    private func loadFile(_ url: URL) {
        do {
            try audioEngine.loadFile(url: url)
            fileLabel.stringValue = url.lastPathComponent
            updatePlayButton()
            audioEngine.play()
            updatePlayButton()
        } catch {
            fileLabel.stringValue = "Error: \(error.localizedDescription)"
        }
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
}
