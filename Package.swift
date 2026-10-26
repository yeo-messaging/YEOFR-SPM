// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "YEOFR",
  platforms: [.iOS(.v17), .macOS("26.0")],
  products: [
    .library(name: "YEOFR", targets: ["YEOFR"])
  ],
  targets: [
    .binaryTarget(
      name: "YEOFR",
      url: "https://github.com/yeo-messaging/YEOFR-SPM/releases/download/0.11.2/YEOFR.xcframework.zip",
      checksum: "89cd972d3722c165bca789df9604aecbc471e420c6611ff359e2e68b8a2ffb6b"
    )
  ]
)
