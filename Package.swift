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
      url: "https://github.com/yeo-messaging/YEOFR-SPM/releases/download/0.12.1/YEOFR.xcframework.zip",
      checksum: "ffeca35d4a3d6b3b7c6abd96816fd6244ae9c5de00274f2c332d011742b7dc90"
    )
  ]
)
