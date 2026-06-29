import Foundation

enum SpotlightFinder {
  static func findFiles(named filename: String, under root: URL) -> [URL] {
    let process = Process()
    let pipe = Pipe()

    process.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
    process.arguments = [
      "-onlyin", root.path, "kMDItemFSName ==[cd] \(quotedQueryValue(filename))",
    ]
    process.standardOutput = pipe
    process.standardError = Pipe()

    do {
      try process.run()
      process.waitUntilExit()
    } catch {
      return []
    }

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let output = String(data: data, encoding: .utf8) else {
      return []
    }

    return
      output
      .split(separator: "\n")
      .map { URL(fileURLWithPath: String($0)) }
      .filter { $0.lastPathComponent == filename }
  }

  private static func quotedQueryValue(_ value: String) -> String {
    let escaped =
      value
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")

    return "\"\(escaped)\""
  }
}
