// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "YEOFR",
  platforms: [.iOS(.v17)],
  products: [
    .library(name: "YEOFR", targets: ["YEOFR"])
  ],
  targets: [
    .binaryTarget(
      name: "YEOFR",
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.4.14/YEOFR.xcframework.zip",
      checksum: "7064d9d82d23308118b74eacfe191085ba9d9b5824955e558813596aac76708a"
    )
  ]
)
