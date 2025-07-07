// swift-tools-version:6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "ActivityPub",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "ActivityPub",
      targets: ["ActivityPub"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/vapor/vapor.git", from: "4.106.1"),
    .package(url: "https://github.com/apple/swift-crypto.git", branch: "3.12.3"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "ActivityPub",
      dependencies: [
        .product(name: "Vapor", package: "vapor"),
        .product(name: "Crypto", package: "swift-crypto"),
        .product(name: "_CryptoExtras", package: "swift-crypto"),
      ]
    ),
    .testTarget(
      name: "ActivityPubTests",
      dependencies: ["ActivityPub"]
    ),
  ]
)
