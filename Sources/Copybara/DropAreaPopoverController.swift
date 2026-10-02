import AppKit

@MainActor
final class DropAreaPopoverController: NSObject, NSPopoverDelegate {
  var onFileDrop: (([URL]) -> Void)?
  var onTextDrop: ((String) -> Void)?
  var onSettingsRequested: ((NSView) -> Void)?

  private let popover = NSPopover()
  private let content = DropAreaPopoverContentView(
    frame: NSRect(x: 0, y: 0, width: 320, height: 180)
  )

  var isShown: Bool {
    popover.isShown
  }

  func close() {
    popover.close()
  }

  override init() {
    super.init()

    configureContent()

    let contentController = NSViewController()
    contentController.view = content
    contentController.preferredContentSize = content.frame.size

    popover.contentViewController = contentController
    popover.contentSize = content.frame.size
    popover.animates = true
    popover.behavior = .applicationDefined
    popover.delegate = self
  }

  func show(relativeTo anchor: NSView) {
    guard anchor.window != nil else {
      return
    }

    if popover.isShown {
      popover.close()
      return
    }

    popover.show(relativeTo: anchor.bounds, of: anchor, preferredEdge: .minY)
  }

  func popoverDidShow(_ notification: Notification) {
    content.window?.makeFirstResponder(content)
  }

  func popoverShouldDetach(_ popover: NSPopover) -> Bool {
    false
  }

  private func configureContent() {
    content.material = .popover
    content.blendingMode = .withinWindow
    content.state = .active
    content.onClose = { [weak self] in
      self?.popover.close()
    }

    let icon = NSImageView()
    icon.image = NSImage(
      systemSymbolName: "link",
      accessibilityDescription: nil
    )?.withSymbolConfiguration(.init(pointSize: 32, weight: .bold))
    icon.contentTintColor = .controlAccentColor
    icon.imageScaling = .scaleProportionallyDown
    icon.setAccessibilityElement(false)
    icon.translatesAutoresizingMaskIntoConstraints = false

    let title = NSTextField(labelWithString: "Drop a Dropbox file or folder")
    title.font = .systemFont(ofSize: 14, weight: .medium)
    title.alignment = .center

    let subtitle = NSTextField(labelWithString: "Dropbox web links also work")
    subtitle.font = .systemFont(ofSize: 12)
    subtitle.textColor = .secondaryLabelColor
    subtitle.alignment = .center

    let instructions = NSStackView(views: [icon, title, subtitle])
    instructions.orientation = .vertical
    instructions.alignment = .centerX
    instructions.spacing = 12
    instructions.translatesAutoresizingMaskIntoConstraints = false
    content.addSubview(instructions)

    NSLayoutConstraint.activate([
      icon.widthAnchor.constraint(equalToConstant: 36),
      icon.heightAnchor.constraint(equalToConstant: 36),
      instructions.centerXAnchor.constraint(equalTo: content.centerXAnchor),
      instructions.centerYAnchor.constraint(equalTo: content.centerYAnchor),
      instructions.leadingAnchor.constraint(greaterThanOrEqualTo: content.leadingAnchor, constant: 20),
      instructions.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -20)
    ])

    let dropTarget = DropTargetView(frame: content.bounds)
    dropTarget.autoresizingMask = [.width, .height]
    dropTarget.setAccessibilityLabel("Copybara Drop Area")
    dropTarget.setAccessibilityHelp(
      "Drop a Dropbox file, folder, or web link here to copy or open a Copybara link"
    )
    dropTarget.onFileDrop = { [weak self] urls in
      guard let self else {
        return
      }
      onFileDrop?(urls)
      popover.close()
    }
    dropTarget.onTextDrop = { [weak self] text in
      guard let self else {
        return
      }
      onTextDrop?(text)
      popover.close()
    }
    content.addSubview(dropTarget)

    let closeButton = NSButton(title: "", target: self, action: #selector(closeDropArea(_:)))
    closeButton.image = NSImage(
      systemSymbolName: "xmark",
      accessibilityDescription: "Close Drop Area"
    )?.withSymbolConfiguration(.init(pointSize: 10, weight: .semibold))
    closeButton.imagePosition = .imageOnly
    closeButton.isBordered = false
    closeButton.imageScaling = .scaleProportionallyDown
    closeButton.toolTip = "Close Drop Area"
    closeButton.setAccessibilityLabel("Close Drop Area")
    closeButton.translatesAutoresizingMaskIntoConstraints = false
    content.addSubview(closeButton)

    NSLayoutConstraint.activate([
      closeButton.topAnchor.constraint(equalTo: content.topAnchor, constant: 10),
      closeButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -10),
      closeButton.widthAnchor.constraint(equalToConstant: 20),
      closeButton.heightAnchor.constraint(equalToConstant: 20)
    ])

    let settingsButton = NSButton(title: "", target: self, action: #selector(showSettings(_:)))
    settingsButton.image = NSImage(
      systemSymbolName: "gearshape",
      accessibilityDescription: "Settings and Recent Links"
    )?.withSymbolConfiguration(.init(pointSize: 13, weight: .regular))
    settingsButton.imagePosition = .imageOnly
    settingsButton.isBordered = false
    settingsButton.imageScaling = .scaleProportionallyDown
    settingsButton.toolTip = "Settings and Recent Links"
    settingsButton.setAccessibilityLabel("Settings and Recent Links")
    settingsButton.translatesAutoresizingMaskIntoConstraints = false
    content.addSubview(settingsButton)

    NSLayoutConstraint.activate([
      settingsButton.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -10),
      settingsButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -10),
      settingsButton.widthAnchor.constraint(equalToConstant: 24),
      settingsButton.heightAnchor.constraint(equalToConstant: 24)
    ])
  }

  @objc private func closeDropArea(_ sender: NSButton) {
    popover.close()
  }

  @objc private func showSettings(_ sender: NSButton) {
    onSettingsRequested?(sender)
  }
}

@MainActor
private final class DropAreaPopoverContentView: NSVisualEffectView {
  var onClose: (() -> Void)?

  override var acceptsFirstResponder: Bool {
    true
  }

  override func cancelOperation(_ sender: Any?) {
    onClose?()
  }

  override func keyDown(with event: NSEvent) {
    if event.keyCode == 53 {
      onClose?()
    } else {
      super.keyDown(with: event)
    }
  }
}
