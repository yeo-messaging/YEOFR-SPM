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
      url: "https://github.com/yeo-messaging/YEOFR-SPM/releases/download/0.7.4/YEOFR.xcframework.zip",
      checksum: "fdfba23a164e82ac4f563fdb7d8c4970960944cee06ea280d89ed6dacf4412c1"
    )
  ]
)
