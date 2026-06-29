import Foundation

final class Preferences {
  private enum Key {
    static let dropboxRoot = "dropboxRoot"
    static let openEnclosingFolderOnly = "openEnclosingFolderOnly"
    static let showNotifications = "showNotifications"
    static let copiedURLScheme = "copiedURLScheme"
    static let history = "history"
  }

  private let defaults = UserDefaults.standard

  var dropboxRoot: URL? {
    get {
      guard let path = defaults.string(forKey: Key.dropboxRoot), !path.isEmpty else {
        return nil
      }
      return URL(fileURLWithPath: path)
    }
    set {
      defaults.set(newValue?.path, forKey: Key.dropboxRoot)
    }
  }

  var openEnclosingFolderOnly: Bool {
    get { defaults.bool(forKey: Key.openEnclosingFolderOnly) }
    set { defaults.set(newValue, forKey: Key.openEnclosingFolderOnly) }
  }

  var showNotifications: Bool {
    get { defaults.object(forKey: Key.showNotifications) as? Bool ?? true }
    set { defaults.set(newValue, forKey: Key.showNotifications) }
  }

  var copiedURLScheme: String {
    get {
      let scheme = defaults.string(forKey: Key.copiedURLScheme) ?? Constants.urlScheme
      guard Constants.supportedURLSchemes.contains(scheme) else {
        return Constants.urlScheme
      }
      return scheme
    }
    set {
      guard Constants.supportedURLSchemes.contains(newValue) else {
        return
      }
      defaults.set(newValue, forKey: Key.copiedURLScheme)
    }
  }

  var history: [String] {
    get { defaults.stringArray(forKey: Key.history) ?? [] }
    set { defaults.set(Array(newValue.prefix(Constants.maxHistoryItems)), forKey: Key.history) }
  }
}
