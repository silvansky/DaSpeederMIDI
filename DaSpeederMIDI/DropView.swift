import Cocoa

class DropView: NSView {
    var onFileDropped: ((URL) -> Void)?
    private var isHighlighted = false

    private static let audioExtensions: Set<String> = ["wav", "aif", "aiff", "mp3", "m4a", "caf", "flac"]

    override init(frame: NSRect) {
        super.init(frame: frame)
        registerForDraggedTypes([.fileURL])
        wantsLayer = true
        layer?.cornerRadius = 12
        layer?.borderWidth = 2
        updateBorder()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateBorder() {
        layer?.borderColor = (isHighlighted ? NSColor.controlAccentColor : NSColor.separatorColor).cgColor
        layer?.backgroundColor = (isHighlighted ? NSColor.controlAccentColor.withAlphaComponent(0.1) : .clear).cgColor
    }

    private func isValidDrag(_ info: NSDraggingInfo) -> Bool {
        guard let urls = info.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] else { return false }
        return urls.contains { Self.audioExtensions.contains($0.pathExtension.lowercased()) }
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard isValidDrag(sender) else { return [] }
        isHighlighted = true
        updateBorder()
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        isHighlighted = false
        updateBorder()
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        isHighlighted = false
        updateBorder()
        guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
              let url = urls.first(where: { Self.audioExtensions.contains($0.pathExtension.lowercased()) })
        else { return false }
        onFileDropped?(url)
        return true
    }
}
