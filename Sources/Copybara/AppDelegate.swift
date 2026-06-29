import AppKit
import ServiceManagement
import UniformTypeIdentifiers

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
  private let preferences = Preferences()
  private var statusItem: NSStatusItem?

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.accessory)
    Notifier.shared.prepare()

    if preferences.dropboxRoot == nil {
      preferences.dropboxRoot = DropboxLocator.discoverDropboxRoot()
    }

    NSApp.servicesProvider = self
    NSUpdateDynamicServices()

    configureStatusItem()
  }

  func application(_ application: NSApplication, open urls: [URL]) {
    urls.forEach(openCopybaraURL)
  }

  private func configureStatusItem() {
    let item = NSStatusBar.system.statusItem(withLength: 28)
    guard let button = item.button else {
      return
    }

    let icon = NSImage(
      systemSymbolName: "link",
      accessibilityDescription: Constants.appName
    )?.withSymbolConfiguration(.init(pointSize: 14, weight: .regular))
    icon?.isTemplate = true

    button.image = icon
    button.imagePosition = .imageOnly
    button.imageScaling = .scaleProportionallyDown
    button.toolTip = Constants.appName
    button.setAccessibilityElement(false)

    let dropTargetView = DropTargetView(frame: button.bounds)
    dropTargetView.autoresizingMask = [.width, .height]

    dropTargetView.onFileDrop = { [weak self] urls in
      guard let fileURL = urls.first else {
        return
      }
      _ = self?.copyLink(forFileURL: fileURL)
    }
    dropTargetView.onTextDrop = { [weak self] text in
      self?.handleDroppedText(text)
    }
    dropTargetView.onMenuRequested = { [weak self] in
      self?.showMenu()
    }

    button.addSubview(dropTargetView)
    statusItem = item
  }

  private func showMenu() {
    let menu = buildMenu()
    menu.delegate = self

    guard let statusItem, let button = statusItem.button else {
      return
    }

    statusItem.menu = menu
    button.performClick(nil)
  }

  func menuDidClose(_ menu: NSMenu) {
    if statusItem?.menu === menu {
      statusItem?.menu = nil
    }
  }

  private func buildMenu() -> NSMenu {
    let menu = NSMenu()

    let rootTitle = preferences.dropboxRoot?.path ?? "Not set"
    let rootItem = menuItem("Dropbox: \(rootTitle)", icon: "folder")
    rootItem.isEnabled = false
    menu.addItem(rootItem)

    menu.addItem(
      menuItem(
        "Change Dropbox Folder...",
        action: #selector(changeDropboxFolder),
        icon: "folder.badge.gearshape"))

    menu.addItem(.separator())

    let schemeItem = menuItem("Copied URL scheme", icon: "link")
    let schemeMenu = NSMenu()
    for scheme in Constants.supportedURLSchemes {
      let item = menuItem(
        copiedURLSchemeTitle(for: scheme),
        action: #selector(selectCopiedURLScheme(_:)),
        icon: "link"
      )
      item.target = self
      item.representedObject = scheme
      item.state = preferences.copiedURLScheme == scheme ? .on : .off
      schemeMenu.addItem(item)
    }
    schemeItem.submenu = schemeMenu
    menu.addItem(schemeItem)

    let openEnclosingItem = menuItem(
      "Open enclosing folder only",
      action: #selector(toggleOpenEnclosingOnly(_:)),
      icon: "folder"
    )
    openEnclosingItem.state = preferences.openEnclosingFolderOnly ? .on : .off
    menu.addItem(openEnclosingItem)

    let notificationsItem = menuItem(
      "Show notifications",
      action: #selector(toggleNotifications(_:)),
      icon: "bell"
    )
    notificationsItem.state = preferences.showNotifications ? .on : .off
    menu.addItem(notificationsItem)

    let launchItem = menuItem(
      launchAtLoginTitle,
      action: #selector(toggleLaunchAtLogin(_:)),
      icon: "power"
    )
    launchItem.state = launchAtLoginEnabled ? .on : .off
    launchItem.isEnabled = launchAtLoginMenuEnabled
    menu.addItem(launchItem)

    let history = preferences.history
    if !history.isEmpty {
      menu.addItem(.separator())

      for link in history {
        let item = menuItem(
          "Copy \(URL(string: link)?.lastPathComponent.removingPercentEncoding ?? link)",
          action: #selector(copyHistoryItem(_:)),
          image: historyIcon(for: link)
        )
        item.representedObject = link
        menu.addItem(item)
      }
    }

    menu.addItem(.separator())
    menu.addItem(menuItem("Quit", action: #selector(quit), icon: "xmark", keyEquivalent: "q"))

    for item in menu.items where item.action != nil {
      item.target = self
    }

    return menu
  }

  private func menuItem(
    _ title: String,
    action: Selector? = nil,
    icon: String? = nil,
    image: NSImage? = nil,
    keyEquivalent: String = ""
  ) -> NSMenuItem {
    let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
    item.image = image ?? icon.flatMap(menuIcon)
    return item
  }

  private func menuIcon(_ systemSymbolName: String) -> NSImage? {
    guard
      let image = NSImage(
        systemSymbolName: systemSymbolName,
        accessibilityDescription: nil
      )?.withSymbolConfiguration(.init(pointSize: 13, weight: .regular))
    else {
      return nil
    }

    image.isTemplate = true
    return image
  }

  private func historyIcon(for link: String) -> NSImage? {
    guard let url = URL(string: link),
      let relativePath = LinkCodec.decodeRelativePath(from: url)
    else {
      return menuIcon("doc")
    }

    if let root = preferences.dropboxRoot,
      let itemURL = LinkCodec.containedURL(relativePath: relativePath, rootURL: root),
      FileManager.default.fileExists(atPath: itemURL.path)
    {
      return sizedMenuIcon(NSWorkspace.shared.icon(forFile: itemURL.path))
    }

    let pathExtension = (relativePath as NSString).pathExtension
    if !pathExtension.isEmpty, let type = UTType(filenameExtension: pathExtension) {
      return sizedMenuIcon(NSWorkspace.shared.icon(for: type))
    }

    return menuIcon("doc")
  }

  private func sizedMenuIcon(_ image: NSImage) -> NSImage {
    image.size = NSSize(width: 16, height: 16)
    return image
  }

  private func handleDroppedText(_ text: String) {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

    if let url = URL(string: trimmed), isDropboxWebURL(url) {
      locateDropboxShare(url)
      return
    }

    if let url = URL(string: trimmed), isWebURL(url) {
      NSWorkspace.shared.open(url)
    }
  }

  private func locateDropboxShare(_ url: URL) {
    guard let root = configuredDropboxRoot() else {
      notifyMissingDropboxRoot()
      return
    }

    let filename = url.lastPathComponent.removingPercentEncoding ?? url.lastPathComponent
    guard !filename.isEmpty else {
      notify(title: "File not found", body: "The Dropbox URL does not contain a file name.")
      return
    }

    Task.detached(priority: .userInitiated) {
      let matches = SpotlightFinder.findFiles(named: filename, under: root)
      await MainActor.run {
        guard let first = matches.first else {
          self.notify(title: "File not found", body: "No local Dropbox item matched \(filename).")
          return
        }

        self.openOrReveal(first)

        if matches.count > 1 {
          self.notify(
            title: "Multiple copies found", body: "Opened the first local match for \(filename).")
        }
      }
    }
  }

  private func openCopybaraURL(_ url: URL) {
    guard let root = configuredDropboxRoot() else {
      notifyMissingDropboxRoot()
      return
    }

    guard let relativePath = LinkCodec.decodeRelativePath(from: url),
      let destination = LinkCodec.containedURL(relativePath: relativePath, rootURL: root)
    else {
      notify(title: "Invalid Copybara link", body: url.absoluteString)
      return
    }

    openOrReveal(destination)
  }

  private func openOrReveal(_ url: URL) {
    if preferences.openEnclosingFolderOnly {
      NSWorkspace.shared.activateFileViewerSelecting([url])
    } else {
      NSWorkspace.shared.open(url)
    }
  }

  private func configuredDropboxRoot() -> URL? {
    if let root = preferences.dropboxRoot {
      return root
    }

    let discovered = DropboxLocator.discoverDropboxRoot()
    preferences.dropboxRoot = discovered
    return discovered
  }

  private func notifyMissingDropboxRoot() {
    notify(
      title: "Dropbox folder not set", body: "Choose your Dropbox folder from the Copybara menu.")
  }

  private func notify(title: String, body: String) {
    Notifier.shared.show(title: title, body: body, enabled: preferences.showNotifications)
  }

  @discardableResult
  private func copyLink(forFileURL fileURL: URL) -> Bool {
    guard let root = configuredDropboxRoot() else {
      notifyMissingDropboxRoot()
      return false
    }

    guard let relativePath = LinkCodec.relativePath(for: fileURL, in: root) else {
      notify(title: "Copybara failed", body: "The selected item is not inside your Dropbox folder.")
      return false
    }

    let link = LinkCodec.makeLink(
      relativePath: relativePath,
      scheme: preferences.copiedURLScheme
    )
    if copyLinkToClipboard(link) {
      addToHistory(link)
      return true
    }

    return false
  }

  @discardableResult
  private func copyLinkToClipboard(_ link: String) -> Bool {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    guard pasteboard.setString(link, forType: .string) else {
      flashStatusButton()
      notify(title: "Copy failed", body: "The link could not be written to the clipboard.")
      return false
    }

    flashStatusButton()
    notify(title: "Link copied", body: link)
    return true
  }

  private func flashStatusButton() {
    guard let button = statusItem?.button else {
      return
    }

    button.highlight(true)
    Task { @MainActor [weak self] in
      try? await Task.sleep(nanoseconds: 140_000_000)
      self?.statusItem?.button?.highlight(false)
    }
  }

  private func addToHistory(_ link: String) {
    var history = preferences.history.filter { $0 != link }
    history.insert(link, at: 0)
    preferences.history = history
  }

  private var launchAtLoginEnabled: Bool {
    SMAppService.mainApp.status == .enabled
  }

  private var launchAtLoginMenuEnabled: Bool {
    switch SMAppService.mainApp.status {
    case .enabled, .notRegistered:
      return true
    case .requiresApproval, .notFound:
      return false
    @unknown default:
      return false
    }
  }

  private var launchAtLoginTitle: String {
    switch SMAppService.mainApp.status {
    case .enabled, .notRegistered:
      return "Launch at login"
    case .requiresApproval:
      return "Launch at login requires approval"
    case .notFound:
      return "Launch at login unavailable"
    @unknown default:
      return "Launch at login unavailable"
    }
  }

  private func isWebURL(_ url: URL) -> Bool {
    guard let scheme = url.scheme?.lowercased() else {
      return false
    }

    return scheme == "http" || scheme == "https"
  }

  private func isDropboxWebURL(_ url: URL) -> Bool {
    guard isWebURL(url),
      let host = url.host(percentEncoded: false)?.lowercased()
    else {
      return false
    }

    return host == "dropbox.com" || host.hasSuffix(".dropbox.com")
  }

  private func copiedURLSchemeTitle(for scheme: String) -> String {
    switch scheme {
    case Constants.urlScheme:
      return "Copybara (copybara:)"
    case Constants.legacyURLScheme:
      return "Dropifier legacy (dropifier:)"
    default:
      return "\(scheme):"
    }
  }

  @objc private func changeDropboxFolder() {
    NSApp.activate(ignoringOtherApps: true)

    let panel = NSOpenPanel()
    panel.title = "Choose Dropbox Folder"
    panel.prompt = "Choose"
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.allowsMultipleSelection = false

    if panel.runModal() == .OK, let url = panel.url {
      preferences.dropboxRoot = url
    }
  }

  @objc private func toggleOpenEnclosingOnly(_ item: NSMenuItem) {
    preferences.openEnclosingFolderOnly.toggle()
    item.state = preferences.openEnclosingFolderOnly ? .on : .off
  }

  @objc private func toggleNotifications(_ item: NSMenuItem) {
    preferences.showNotifications.toggle()
    item.state = preferences.showNotifications ? .on : .off
  }

  @objc private func selectCopiedURLScheme(_ item: NSMenuItem) {
    guard let scheme = item.representedObject as? String else {
      return
    }
    preferences.copiedURLScheme = scheme
  }

  @objc private func toggleLaunchAtLogin(_ item: NSMenuItem) {
    let shouldEnable = SMAppService.mainApp.status != .enabled

    do {
      if shouldEnable {
        try SMAppService.mainApp.register()
      } else {
        try SMAppService.mainApp.unregister()
      }
      item.state = launchAtLoginEnabled ? .on : .off
      item.title = launchAtLoginTitle
      item.isEnabled = launchAtLoginMenuEnabled
    } catch {
      notify(title: "Launch at login failed", body: error.localizedDescription)
    }
  }

  @objc(copyLinkWithCopybara:userData:error:)
  private func copyLinkWithCopybara(
    _ pasteboard: NSPasteboard,
    userData: String?,
    error: AutoreleasingUnsafeMutablePointer<NSString?>
  ) {
    guard let fileURL = PasteboardReader.fileURLs(from: pasteboard).first else {
      error.pointee = "No Finder item was provided to Copybara."
      return
    }

    if !copyLink(forFileURL: fileURL) {
      error.pointee = "Copybara could not copy a link for the selected item."
    }
  }

  @objc private func copyHistoryItem(_ item: NSMenuItem) {
    guard let link = item.representedObject as? String else {
      return
    }

    if copyLinkToClipboard(link) {
      addToHistory(link)
    }
  }

  @objc private func quit() {
    NSApp.terminate(nil)
  }
}
