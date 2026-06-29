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
  dependencies: [
    .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.0")
  ],
  targets: [
    .executableTarget(
      name: "Copybara",
      dependencies: [
        .product(name: "Sparkle", package: "Sparkle")
      ]
    )
  ]
)
