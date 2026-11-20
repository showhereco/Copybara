import AppKit

enum PasteboardReader {
  private static let filenamesType = NSPasteboard.PasteboardType("NSFilenamesPboardType")
  static let dropTypes: [NSPasteboard.PasteboardType] = [.fileURL, filenamesType, .URL, .string]

  static func fileURLs(from pasteboard: NSPasteboard) -> [URL] {
    let options: [NSPasteboard.ReadingOptionKey: Any] = [
      .urlReadingFileURLsOnly: true
    ]

    let urls = (pasteboard.readObjects(forClasses: [NSURL.self], options: options) ?? [])
      .compactMap { object -> URL? in
        if let url = object as? URL {
          return url
        }
        return (object as? NSURL) as URL?
      }

    if !urls.isEmpty {
      return urls
    }

    let filenames = pasteboard.propertyList(forType: filenamesType) as? [String]
    return filenames?.map { URL(fileURLWithPath: $0) } ?? []
  }

  static func text(from pasteboard: NSPasteboard) -> String? {
    [.string, .URL]
      .compactMap { pasteboard.string(forType: $0) }
      .first { !$0.isEmpty }
  }
}
