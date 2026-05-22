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
      url: "https://github.com/YEOMessaging/YEOFR-SPM/releases/download/0.6.1/YEOFR.xcframework.zip",
      checksum: "adb926a918b622660e53795bdcd0c0360d4fd408359b82f8e44e3a71f7b99b54"
    )
  ]
)
