import AppKit

final class DropTargetView: NSView {
  var onFileDrop: (([URL]) -> Void)?
  var onTextDrop: ((String) -> Void)?
  var onMenuRequested: (() -> Void)?

  private var isHighlighted = false {
    didSet { needsDisplay = true }
  }

  override init(frame frameRect: NSRect) {
    super.init(frame: frameRect)
    configure()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    configure()
  }

  override var acceptsFirstResponder: Bool {
    true
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    if isHighlighted {
      NSColor.selectedControlColor.withAlphaComponent(0.22).setFill()
      NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), xRadius: 4, yRadius: 4).fill()
    }
  }

  override func mouseDown(with event: NSEvent) {
    onMenuRequested?()
  }

  override func rightMouseDown(with event: NSEvent) {
    onMenuRequested?()
  }

  override func accessibilityPerformPress() -> Bool {
    onMenuRequested?()
    return true
  }

  override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    guard canRead(sender.draggingPasteboard) else {
      return []
    }
    isHighlighted = true
    return .copy
  }

  override func draggingExited(_ sender: NSDraggingInfo?) {
    isHighlighted = false
  }

  override func draggingEnded(_ sender: NSDraggingInfo) {
    isHighlighted = false
  }

  override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
    defer { isHighlighted = false }

    let pasteboard = sender.draggingPasteboard
    let fileURLs = PasteboardReader.fileURLs(from: pasteboard)
    if !fileURLs.isEmpty {
      onFileDrop?(fileURLs)
      return true
    }

    if let text = PasteboardReader.text(from: pasteboard) {
      onTextDrop?(text)
      return true
    }

    return false
  }

  private func canRead(_ pasteboard: NSPasteboard) -> Bool {
    !PasteboardReader.fileURLs(from: pasteboard).isEmpty
      || PasteboardReader.text(from: pasteboard) != nil
  }

  private func configure() {
    registerForDraggedTypes([.fileURL, .URL, .string])
    toolTip = Constants.appName
    setAccessibilityElement(true)
    setAccessibilityRole(.button)
    setAccessibilityLabel(Constants.appName)
    setAccessibilityHelp(
      "Opens the Copybara menu. Drop Dropbox files here to copy a local Copybara link.")
  }
}
