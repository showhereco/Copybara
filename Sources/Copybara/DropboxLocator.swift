import Foundation

enum DropboxLocator {
  static func discoverDropboxRoot() -> URL? {
    let infoURL = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent(".dropbox/info.json")

    guard let data = try? Data(contentsOf: infoURL),
      let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      return nil
    }

    for account in ["business", "personal"] {
      if let data = object[account] as? [String: Any],
        let path = data["root_path"] as? String
      {
        return URL(fileURLWithPath: path)
      }
    }

    return nil
  }
}
