import AppKit

final class DropTargetView: NSView {
  var onFileDrop: (([URL]) -> Void)?
  var onTextDrop: ((String) -> Void)?
  var onPress: (() -> Void)?
  var onSecondaryPress: (() -> Void)?
  var preferredSize: NSSize? {
    didSet { invalidateIntrinsicContentSize() }
  }

  private var isHighlighted = false {
    didSet { needsDisplay = true }
  }
  private var showsCopyFeedback = false {
    didSet { needsDisplay = true }
  }
  private var feedbackTask: Task<Void, Never>?

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

  override var intrinsicContentSize: NSSize {
    preferredSize ?? super.intrinsicContentSize
  }

  override func hitTest(_ point: NSPoint) -> NSView? {
    super.hitTest(point) == nil ? nil : self
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    if isHighlighted || showsCopyFeedback {
      NSColor.selectedControlColor.withAlphaComponent(0.22).setFill()
      NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 2), xRadius: 4, yRadius: 4).fill()
    }
  }

  override func mouseDown(with event: NSEvent) {
    onPress?()
  }

  override func rightMouseDown(with event: NSEvent) {
    (onSecondaryPress ?? onPress)?()
  }

  override func accessibilityPerformPress() -> Bool {
    guard let onPress else {
      return false
    }
    onPress()
    return true
  }

  func flash() {
    feedbackTask?.cancel()
    showsCopyFeedback = true
    feedbackTask = Task { @MainActor [weak self] in
      do {
        try await Task.sleep(nanoseconds: 140_000_000)
      } catch {
        return
      }
      self?.showsCopyFeedback = false
    }
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
