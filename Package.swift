// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "Copybara",
  platforms: [
    .macOS(.v15)
  ],
  products: [
    .executable(name: "Copybara", targets: ["Copybara"])
  ],
  targets: [
    .executableTarget(
      name: "Copybara"
    )
  ]
)
