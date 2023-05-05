// swift-tools-version: 5.8

import PackageDescription

let package = Package(
  name: "ProbabilityTheoryTask",
  platforms: [
    .macOS(.v13),
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-argument-parser",
      from: "1.2.0"),
    .package(
      url: "https://github.com/tplaymeow/swift-text-table",
      branch: "main"),
  ],
  targets: [
    .executableTarget(
      name: "ProbabilityTheoryTask",
      dependencies: [
        .product(
          name: "ArgumentParser",
          package: "swift-argument-parser"),
        .product(
          name: "TextTable",
          package: "swift-text-table"),
      ],
      path: "Sources"),
  ]
)
