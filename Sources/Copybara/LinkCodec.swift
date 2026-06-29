import Foundation

enum LinkCodec {
  static func relativePath(for itemURL: URL, in rootURL: URL) -> String? {
    let root = rootURL.resolvingSymlinksInPath().standardizedFileURL
    let item = itemURL.resolvingSymlinksInPath().standardizedFileURL

    let rootPath = root.path
    let itemPath = item.path

    if itemPath == rootPath {
      return ""
    }

    let rootPrefix = rootPath.hasSuffix("/") ? rootPath : rootPath + "/"
    guard itemPath.hasPrefix(rootPrefix) else {
      return nil
    }

    return String(itemPath.dropFirst(rootPrefix.count))
  }

  static func makeLink(relativePath: String, scheme: String = Constants.urlScheme) -> String {
    let encodedPath =
      relativePath
      .split(separator: "/", omittingEmptySubsequences: false)
      .map { component in
        String(component).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
          ?? String(component)
      }
      .joined(separator: "/")

    return "\(scheme):///\(encodedPath)"
  }

  static func decodeRelativePath(from url: URL) -> String? {
    guard let scheme = url.scheme?.lowercased(),
      scheme == Constants.urlScheme || scheme == Constants.legacyURLScheme
    else {
      return nil
    }

    var rawRelativePath: String

    if let host = url.host(percentEncoded: false), !host.isEmpty, host != "open" {
      rawRelativePath = host + url.path(percentEncoded: false)
    } else {
      rawRelativePath = url.path(percentEncoded: false)
      if rawRelativePath.hasPrefix("/") {
        rawRelativePath.removeFirst()
      }
    }

    while rawRelativePath.hasPrefix("/") {
      rawRelativePath.removeFirst()
    }

    guard !rawRelativePath.contains("../"), rawRelativePath != ".." else {
      return nil
    }

    return rawRelativePath
  }

  static func containedURL(relativePath: String, rootURL: URL) -> URL? {
    let root = rootURL.resolvingSymlinksInPath().standardizedFileURL
    let destination =
      rootURL
      .appendingPathComponent(relativePath)
      .resolvingSymlinksInPath()
      .standardizedFileURL

    guard Self.relativePath(for: destination, in: root) != nil || destination.path == root.path
    else {
      return nil
    }

    return destination
  }
}
