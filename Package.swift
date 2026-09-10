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
      url: "https://github.com/yeo-messaging/YEOFR-SPM/releases/download/0.9.1/YEOFR.xcframework.zip",
      checksum: "f046cdea1f76e1306a69494e33e2c416df5cb37a195151cdd8e55a6db7e01fc3"
    )
  ]
)
